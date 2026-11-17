// Acesso ao banco. O RLS garante que cada laboratório só vê e altera os próprios dados;
// laboratorio_id é preenchido automaticamente pelo banco (default meu_laboratorio_id()).
import { supabase } from './supabase.js';

function erroAmigavel(erro, mensagensUnicas = {}) {
  if (!erro) return null;
  switch (erro.code) {
    case '23505': {
      const chave = Object.keys(mensagensUnicas).find((k) => erro.message?.includes(k));
      return new Error(chave ? mensagensUnicas[chave] : 'Já existe um registro com esses dados.');
    }
    case '42501':
      return new Error('Você não tem permissão para fazer esta alteração.');
    case '23503':
      return new Error('Este registro está em uso e não pode ser alterado desta forma.');
    case '23514':
      return new Error('Algum valor informado é inválido.');
    default:
      console.error(erro);
      return new Error('Não foi possível salvar. Tente novamente.');
  }
}

// ---------------- Serviços ----------------

export async function listarServicos() {
  const { data, error } = await supabase
    .from('servicos')
    .select('id, nome, categoria, descricao, preco_padrao, prazo_padrao_dias, ativo')
    .order('nome');
  if (error) throw erroAmigavel(error);
  return data;
}

export async function salvarServico(dados, id = null) {
  const consulta = id
    ? supabase.from('servicos').update(dados).eq('id', id)
    : supabase.from('servicos').insert(dados);
  const { error } = await consulta;
  if (error) throw erroAmigavel(error, { servicos_laboratorio_id_nome_key: 'Já existe um serviço com esse nome.' });
}

// ---------------- Dentistas ----------------

export async function listarDentistas() {
  const { data, error } = await supabase
    .from('dentistas')
    .select('id, nome, cro, clinica, telefone, email, endereco, observacoes, ativo')
    .order('nome');
  if (error) throw erroAmigavel(error);
  return data;
}

export async function salvarDentista(dados, id = null) {
  const consulta = id
    ? supabase.from('dentistas').update(dados).eq('id', id)
    : supabase.from('dentistas').insert(dados);
  const { error } = await consulta;
  if (error) throw erroAmigavel(error);
}

// ---------------- Equipe ----------------

export async function listarUsuarios() {
  const { data, error } = await supabase.from('usuarios').select('id, nome, papel, ativo').eq('ativo', true).order('nome');
  if (error) throw erroAmigavel(error);
  return data;
}

// ---------------- Ordens de serviço ----------------

const CAMPOS_OS = `id, numero, dentista_id, tecnico_responsavel_id, paciente, cor, observacoes, status,
  data_entrada, prazo_entrega, data_entrega, desconto, valor_total,
  dentista:dentistas(nome, clinica),
  tecnico:usuarios(nome),
  itens:itens_ordem_servico(id, servico_id, dentes, quantidade, valor_unitario, valor_total, servico:servicos(nome))`;

export async function listarOrdens() {
  const { data, error } = await supabase
    .from('ordens_servico')
    .select(CAMPOS_OS)
    .order('numero', { ascending: false })
    .limit(500);
  if (error) throw erroAmigavel(error);
  return data;
}

export async function obterOrdem(id) {
  const { data, error } = await supabase.from('ordens_servico').select(CAMPOS_OS).eq('id', id).single();
  if (error) throw erroAmigavel(error);
  return data;
}

/**
 * Cria ou edita a OS e substitui os itens.
 * itens: [{ servico_id, dentes, quantidade, valor_unitario? }] — sem valor_unitario o banco usa a tabela de preços.
 */
export async function salvarOrdem(dados, itens, id = null) {
  if (!itens.length) throw new Error('Adicione pelo menos um serviço na ordem.');

  let ordemId = id;
  if (id) {
    const { error } = await supabase.from('ordens_servico').update(dados).eq('id', id);
    if (error) throw erroAmigavel(error);
    const { error: erroItens } = await supabase.from('itens_ordem_servico').delete().eq('ordem_servico_id', id);
    if (erroItens) throw erroAmigavel(erroItens);
  } else {
    const { data, error } = await supabase.from('ordens_servico').insert(dados).select('id').single();
    if (error) throw erroAmigavel(error);
    ordemId = data.id;
  }

  const linhas = itens.map((item) => {
    const linha = {
      ordem_servico_id: ordemId,
      servico_id: item.servico_id,
      dentes: item.dentes || null,
      quantidade: item.quantidade,
    };
    if (item.valor_unitario != null) linha.valor_unitario = item.valor_unitario;
    return linha;
  });
  const { error: erroInsert } = await supabase.from('itens_ordem_servico').insert(linhas);
  if (erroInsert) throw erroAmigavel(erroInsert);
  return ordemId;
}

export async function alterarStatusOrdem(id, status) {
  const { error } = await supabase.from('ordens_servico').update({ status }).eq('id', id);
  if (error) throw erroAmigavel(error);
}

export async function listarHistorico(ordemId) {
  const { data, error } = await supabase
    .from('historico_etapas')
    .select('status_anterior, status_novo, criado_em, usuario:usuarios(nome)')
    .eq('ordem_servico_id', ordemId)
    .order('criado_em', { ascending: false });
  if (error) throw erroAmigavel(error);
  return data;
}

// ---------------- Tabela de preços por dentista ----------------

/** Retorna Map servico_id -> preço especial do dentista. */
export async function listarPrecosDentista(dentistaId) {
  const { data, error } = await supabase
    .from('precos_dentista')
    .select('servico_id, preco')
    .eq('dentista_id', dentistaId);
  if (error) throw erroAmigavel(error);
  return new Map(data.map((p) => [p.servico_id, Number(p.preco)]));
}

/**
 * precos: Map servico_id -> número (preço especial) ou null (usar preço padrão).
 * Grava os preços informados e remove os que voltaram para o padrão.
 */
export async function salvarPrecosDentista(dentistaId, precos) {
  const gravar = [];
  const remover = [];
  for (const [servicoId, preco] of precos) {
    if (preco === null) remover.push(servicoId);
    else gravar.push({ dentista_id: dentistaId, servico_id: servicoId, preco });
  }

  if (gravar.length) {
    const { error } = await supabase.from('precos_dentista').upsert(gravar, { onConflict: 'dentista_id,servico_id' });
    if (error) throw erroAmigavel(error);
  }
  if (remover.length) {
    const { error } = await supabase
      .from('precos_dentista')
      .delete()
      .eq('dentista_id', dentistaId)
      .in('servico_id', remover);
    if (error) throw erroAmigavel(error);
  }
}

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
    .select('id, nome, descricao, preco_padrao, prazo_padrao_dias, ativo')
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

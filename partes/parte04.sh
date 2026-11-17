mkdir -p "js"
cat > "js/dados.js" <<'FIM_ARQUIVO_PW'
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
FIM_ARQUIVO_PW
mkdir -p "js"
cat > "js/formatos.js" <<'FIM_ARQUIVO_PW'
// Formatação e conversão de valores para exibição.

const moeda = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

/** 1234.5 -> "R$ 1.234,50" */
export function formatarMoeda(valor) {
  return valor === null || valor === undefined || valor === '' ? '' : moeda.format(Number(valor));
}

/** "1.234,50" | "1234,5" | "1234.50" -> 1234.5  (vazio -> null) */
export function lerMoeda(texto) {
  const limpo = String(texto ?? '').replace(/[R$\s]/g, '').trim();
  if (!limpo) return null;
  // Com vírgula: padrão brasileiro (ponto = milhar). Sem vírgula: aceita ponto como decimal.
  const normalizado = limpo.includes(',') ? limpo.replace(/\./g, '').replace(',', '.') : limpo;
  const numero = Number(normalizado);
  return Number.isFinite(numero) ? Math.round(numero * 100) / 100 : NaN;
}

/** 1234.5 -> "1234,50" (para preencher campos de edição) */
export function moedaParaCampo(valor) {
  return valor === null || valor === undefined ? '' : Number(valor).toFixed(2).replace('.', ',');
}

/** Só dígitos -> (11) 98765-4321 / (11) 3456-7890 */
export function formatarTelefone(texto) {
  const d = String(texto ?? '').replace(/\D/g, '').slice(0, 11);
  if (d.length <= 2) return d;
  if (d.length <= 6) return `(${d.slice(0, 2)}) ${d.slice(2)}`;
  if (d.length <= 10) return `(${d.slice(0, 2)}) ${d.slice(2, 6)}-${d.slice(6)}`;
  return `(${d.slice(0, 2)}) ${d.slice(2, 7)}-${d.slice(7)}`;
}

/** Texto sem acentos e minúsculo, para busca. */
export function normalizarBusca(texto) {
  return String(texto ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();
}

/** Escapa texto para uso dentro de templates HTML. */
export function esc(texto) {
  return String(texto ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
}
FIM_ARQUIVO_PW

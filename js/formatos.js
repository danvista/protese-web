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

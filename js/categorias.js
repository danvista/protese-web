// Categorias de serviço: sugestões iniciais e agrupamento para as listas.
import { normalizarBusca } from './formatos.js';

export const CATEGORIAS_SUGERIDAS = ['Metal', 'Cerâmica', 'Zircônia', 'Resina', 'Acrílico', 'Implante', 'Ortodontia'];
export const SEM_CATEGORIA = 'Sem categoria';

/** Categorias já usadas pelo laboratório + sugestões, sem repetir (ignora maiúsculas/acentos). */
export function categoriasDisponiveis(servicos) {
  const vistas = new Map();
  for (const nome of [...servicos.map((s) => s.categoria).filter(Boolean), ...CATEGORIAS_SUGERIDAS]) {
    const chave = normalizarBusca(nome);
    if (!vistas.has(chave)) vistas.set(chave, nome);
  }
  return [...vistas.values()].sort((a, b) => a.localeCompare(b, 'pt-BR'));
}

/** Agrupa serviços por categoria: [[categoria, servicos[]]], em ordem alfabética e "Sem categoria" no fim. */
export function agruparPorCategoria(servicos) {
  const grupos = new Map();
  for (const s of servicos) {
    const cat = s.categoria?.trim() || SEM_CATEGORIA;
    if (!grupos.has(cat)) grupos.set(cat, []);
    grupos.get(cat).push(s);
  }
  return [...grupos.entries()].sort(([a], [b]) => {
    if (a === SEM_CATEGORIA) return 1;
    if (b === SEM_CATEGORIA) return -1;
    return a.localeCompare(b, 'pt-BR');
  });
}

import { iniciarAreaLogada } from '../layout.js';
import { listarServicos, salvarServico } from '../dados.js';
import { esc, formatarMoeda, lerMoeda, moedaParaCampo, normalizarBusca } from '../formatos.js';
import { categoriasDisponiveis, agruparPorCategoria } from '../categorias.js';
import { ligarFormulario, limparFormulario, preencherFormulario, modal, mostrarToast, mostrarAlerta } from '../ui.js';

const { podeGerenciar } = await iniciarAreaLogada('servicos');

const lista = document.getElementById('lista');
const vazio = document.getElementById('vazio');
const busca = document.getElementById('busca');
const mostrarInativos = document.getElementById('mostrar-inativos');
const elModal = document.getElementById('modal-servico');
const form = document.getElementById('form-servico');
const alerta = document.getElementById('alerta-servico');

let servicos = [];
let editandoId = null;
let filtroCategoria = 'TODAS';

// ---------- Lista ----------

async function carregar() {
  try {
    servicos = await listarServicos();
    desenharFiltros();
    desenhar();
  } catch (erro) {
    lista.innerHTML = '';
    vazio.textContent = erro.message;
    vazio.hidden = false;
  }
}

function desenharFiltros() {
  const usados = servicos.filter((s) => mostrarInativos.checked || s.ativo);
  const grupos = agruparPorCategoria(usados);
  if (filtroCategoria !== 'TODAS' && !grupos.some(([cat]) => cat === filtroCategoria)) filtroCategoria = 'TODAS';
  const opcoes = [['TODAS', 'Todas', usados.length], ...grupos.map(([cat, itens]) => [cat, cat, itens.length])];
  // Só mostra os filtros quando há mais de uma categoria
  document.getElementById('filtros').hidden = grupos.length < 2;
  document.getElementById('filtros').innerHTML = opcoes
    .map(
      ([chave, rotulo, qtd]) => `
      <button type="button" class="chip ${chave === filtroCategoria ? 'ativo' : ''}" data-filtro="${esc(chave)}" role="tab"
              aria-selected="${chave === filtroCategoria}">${esc(rotulo)} <span class="contador">${qtd}</span></button>`,
    )
    .join('');
}

document.getElementById('filtros').addEventListener('click', (e) => {
  const botao = e.target.closest('[data-filtro]');
  if (!botao) return;
  filtroCategoria = botao.dataset.filtro;
  desenharFiltros();
  desenhar();
});

function linhaServico(s, i) {
  return `
      <tr class="${s.ativo ? '' : 'text-secondary'}" style="animation-delay:${Math.min(i, 15) * 25}ms">
        <td class="fw-medium">${esc(s.nome)}</td>
        <td class="d-none d-md-table-cell text-truncate texto-curto">${esc(s.descricao)}</td>
        <td class="text-end text-nowrap">${formatarMoeda(s.preco_padrao)}</td>
        <td class="text-center d-none d-sm-table-cell">${s.prazo_padrao_dias != null ? `${s.prazo_padrao_dias} d` : '—'}</td>
        <td class="text-center">${s.ativo ? '<span class="badge text-bg-success">Ativo</span>' : '<span class="badge text-bg-secondary">Inativo</span>'}</td>
        <td class="text-end">
          ${podeGerenciar ? `<button class="btn btn-sm btn-outline-primary" data-editar="${s.id}" aria-label="Editar ${esc(s.nome)}"><i class="bi bi-pencil"></i></button>` : ''}
        </td>
      </tr>`;
}

function desenhar() {
  const termo = normalizarBusca(busca.value);
  const visiveis = servicos.filter(
    (s) =>
      (mostrarInativos.checked || s.ativo) &&
      normalizarBusca(`${s.nome} ${s.categoria ?? ''} ${s.descricao ?? ''}`).includes(termo),
  );
  const grupos = agruparPorCategoria(visiveis).filter(([cat]) => filtroCategoria === 'TODAS' || cat === filtroCategoria);

  let i = 0;
  lista.innerHTML = grupos
    .map(
      ([cat, itens]) => `
      <tr class="linha-categoria">
        <th colspan="6"><i class="bi bi-folder2-open"></i> ${esc(cat)} <span class="contador">${itens.length}</span></th>
      </tr>
      ${itens.map((s) => linhaServico(s, i++)).join('')}`,
    )
    .join('');
  const totalVisiveis = grupos.reduce((n, [, itens]) => n + itens.length, 0);

  if (!servicos.length) {
    vazio.textContent = podeGerenciar
      ? 'Nenhum serviço cadastrado. Clique em "Novo serviço" para começar.'
      : 'Nenhum serviço cadastrado.';
  } else {
    vazio.textContent = 'Nenhum serviço encontrado.';
  }
  vazio.hidden = totalVisiveis > 0;
}

busca.addEventListener('input', desenhar);
mostrarInativos.addEventListener('change', () => {
  desenharFiltros();
  desenhar();
});

// ---------- Cadastro / edição ----------

function abrir(servico = null) {
  editandoId = servico?.id ?? null;
  limparFormulario(form, alerta);
  document.getElementById('lista-categorias').innerHTML = categoriasDisponiveis(servicos)
    .map((c) => `<option value="${esc(c)}">`)
    .join('');
  document.getElementById('titulo-modal').textContent = servico ? 'Editar serviço' : 'Novo serviço';
  if (servico) {
    preencherFormulario(form, { ...servico, preco_padrao: moedaParaCampo(servico.preco_padrao) });
  }
  modal(elModal).show();
}

elModal.addEventListener('shown.bs.modal', () => form.elements.nome.focus());

if (podeGerenciar) {
  const btnNovo = document.getElementById('btn-novo');
  btnNovo.hidden = false;
  btnNovo.addEventListener('click', () => abrir());
}

lista.addEventListener('click', (evento) => {
  const botao = evento.target.closest('[data-editar]');
  if (botao) abrir(servicos.find((s) => s.id === botao.dataset.editar));
});

/** Reaproveita a grafia já usada (ex.: "metal" vira "Metal") para não criar categorias duplicadas. */
function padronizarCategoria(texto) {
  const limpo = texto.trim().replace(/\s+/g, ' ');
  if (!limpo) return null;
  const existente = categoriasDisponiveis(servicos).find((c) => normalizarBusca(c) === normalizarBusca(limpo));
  return existente ?? limpo.charAt(0).toUpperCase() + limpo.slice(1);
}

ligarFormulario(form, {
  alerta,
  validacaoExtra: (f) => {
    const preco = lerMoeda(f.elements.preco_padrao.value);
    f.elements.preco_padrao.setCustomValidity(preco === null || Number.isNaN(preco) || preco < 0 ? 'inválido' : '');
  },
  aoEnviar: async (dados) => {
    const registro = {
      nome: dados.nome.trim(),
      categoria: padronizarCategoria(dados.categoria),
      descricao: dados.descricao.trim() || null,
      preco_padrao: lerMoeda(dados.preco_padrao),
      prazo_padrao_dias: dados.prazo_padrao_dias === '' ? null : Number(dados.prazo_padrao_dias),
      ativo: form.elements.ativo.checked,
    };
    if (!registro.nome) {
      mostrarAlerta(alerta, 'danger', 'Informe o nome do serviço.');
      return;
    }
    await salvarServico(registro, editandoId);
    modal(elModal).hide();
    mostrarToast(editandoId ? 'Serviço atualizado.' : 'Serviço cadastrado.');
    await carregar();
  },
});

await carregar();

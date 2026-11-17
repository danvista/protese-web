mkdir -p "js/paginas"
cat > "js/paginas/ordens.js" <<'FIM_ARQUIVO_PW'
import { iniciarAreaLogada, somenteLeitura } from '../layout.js';
import { ehGestor } from '../auth.js';
import {
  listarOrdens, obterOrdem, salvarOrdem, alterarStatusOrdem, listarHistorico,
  listarDentistas, listarServicos, listarUsuarios, listarPrecosDentista,
} from '../dados.js';
import { esc, formatarMoeda, lerMoeda, moedaParaCampo, normalizarBusca } from '../formatos.js';
import { ligarFormulario, limparFormulario, modal, mostrarToast, mostrarAlerta, esconderAlerta } from '../ui.js';
import { STATUS, PROXIMA_ETAPA, ABERTAS, badgeStatus, estaAtrasada } from '../status.js';

const { perfil, laboratorio } = await iniciarAreaLogada('ordens');
const gestor = ehGestor(perfil);
const podeEditar = !somenteLeitura(laboratorio);
document.body.classList.toggle('modo-tecnico', !gestor);

const el = (id) => document.getElementById(id);
const lista = el('lista');
const busca = el('busca');
const soAtrasadas = el('so-atrasadas');

const dataCurta = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit' });
const dataHora = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });

let ordens = [];
let dentistas = [];
let servicos = [];
let usuarios = [];
let filtroStatus = 'ABERTAS';

// ===================== Lista =====================

async function carregar() {
  lista.innerHTML = Array.from({ length: 6 }, () => '<div class="cartao-os esqueleto"></div>').join('');
  try {
    ordens = await listarOrdens();
    desenharFiltros();
    desenhar();
  } catch (erro) {
    lista.innerHTML = '';
    mostrarVazio(erro.message);
  }
}

function contar(status) {
  if (status === 'ABERTAS') return ordens.filter((o) => ABERTAS.includes(o.status)).length;
  if (status === 'ATRASADAS') return ordens.filter(estaAtrasada).length;
  if (status === 'TODAS') return ordens.length;
  return ordens.filter((o) => o.status === status).length;
}

function desenharFiltros() {
  const opcoes = [
    ['ABERTAS', 'Em aberto', 'bi-hourglass-split'],
    ...Object.entries(STATUS).map(([chave, s]) => [chave, s.rotulo, s.icone]),
    ['TODAS', 'Todas', 'bi-list-ul'],
  ];
  el('filtros').innerHTML = opcoes
    .map(
      ([chave, rotulo, icone]) => `
      <button type="button" class="chip ${chave === filtroStatus ? 'ativo' : ''}" data-filtro="${chave}" role="tab"
              aria-selected="${chave === filtroStatus}">
        <i class="bi ${icone}"></i> ${rotulo} <span class="contador">${contar(chave)}</span>
      </button>`,
    )
    .join('');

  const atrasadas = contar('ATRASADAS');
  el('resumo').innerHTML = `${contar('ABERTAS')} em aberto${
    atrasadas ? ` · <span class="text-danger fw-semibold">${atrasadas} atrasada${atrasadas > 1 ? 's' : ''}</span>` : ''
  }`;
}

el('filtros').addEventListener('click', (e) => {
  const botao = e.target.closest('[data-filtro]');
  if (!botao) return;
  filtroStatus = botao.dataset.filtro;
  desenharFiltros();
  desenhar();
});
busca.addEventListener('input', desenhar);
soAtrasadas.addEventListener('change', desenhar);

function passaFiltro(o) {
  if (filtroStatus === 'ABERTAS' && !ABERTAS.includes(o.status)) return false;
  if (!['ABERTAS', 'TODAS'].includes(filtroStatus) && o.status !== filtroStatus) return false;
  if (soAtrasadas.checked && !estaAtrasada(o)) return false;
  const termo = normalizarBusca(busca.value.replace('#', ''));
  return !termo || normalizarBusca(`${o.numero} ${o.paciente} ${o.dentista?.nome ?? ''}`).includes(termo);
}

function textoPrazo(o) {
  if (o.status === 'ENTREGUE' && o.data_entrega) return `Entregue ${dataCurta.format(new Date(o.data_entrega))}`;
  const dias = Math.ceil((new Date(o.prazo_entrega) - new Date()) / 86400000);
  if (!ABERTAS.includes(o.status)) return `Prazo ${dataCurta.format(new Date(o.prazo_entrega))}`;
  if (dias < 0) return `Atrasada ${-dias} dia${dias < -1 ? 's' : ''}`;
  if (dias === 0) return 'Entrega hoje';
  if (dias === 1) return 'Entrega amanhã';
  return `Entrega em ${dias} dias · ${dataCurta.format(new Date(o.prazo_entrega))}`;
}

function desenhar() {
  const visiveis = ordens.filter(passaFiltro);
  lista.innerHTML = visiveis
    .map((o, i) => {
      const atrasada = estaAtrasada(o);
      const servicosTexto = (o.itens ?? []).map((it) => `${it.quantidade > 1 ? `${it.quantidade}× ` : ''}${it.servico?.nome ?? ''}`).join(', ');
      return `
      <button type="button" class="cartao-os borda-${STATUS[o.status].cor} ${atrasada ? 'atrasada' : ''}" data-id="${o.id}"
              style="animation-delay:${Math.min(i, 12) * 35}ms">
        <div class="d-flex align-items-start gap-2">
          <span class="numero-os">#${o.numero}</span>
          <span class="ms-auto">${badgeStatus(o.status)}</span>
        </div>
        <div class="paciente">${esc(o.paciente)}</div>
        <div class="text-secondary small text-truncate"><i class="bi bi-person-vcard"></i> ${esc(o.dentista?.nome)}</div>
        <div class="small text-truncate servicos-os">${esc(servicosTexto)}</div>
        <div class="d-flex align-items-center mt-auto pt-2 small">
          <span class="${atrasada ? 'text-danger fw-semibold' : 'text-secondary'}"><i class="bi bi-calendar-event"></i> ${textoPrazo(o)}</span>
          ${gestor ? `<span class="ms-auto fw-semibold">${formatarMoeda(o.valor_total)}</span>` : ''}
        </div>
        ${o.cor ? `<span class="cor-dente" title="Cor">${esc(o.cor)}</span>` : ''}
      </button>`;
    })
    .join('');

  if (!visiveis.length) {
    mostrarVazio(
      ordens.length
        ? 'Nenhuma ordem encontrada com esses filtros.'
        : podeEditar
          ? 'Nenhuma ordem de serviço ainda. Clique em "Nova OS" para lançar a primeira.'
          : 'Nenhuma ordem de serviço ainda.',
    );
  } else {
    el('vazio').hidden = true;
  }
}

function mostrarVazio(texto) {
  el('vazio-texto').textContent = texto;
  el('vazio').hidden = false;
}

lista.addEventListener('click', (e) => {
  const cartao = e.target.closest('[data-id]');
  if (cartao) abrirOrdem(cartao.dataset.id);
});

// ===================== Modal da OS =====================

const elModal = el('modal-os');
const form = el('form-os');
const alerta = el('alerta-os');
const corpoItens = el('itens');
const modeloItem = el('modelo-item');
let ordemAtual = null;
let precosDentista = new Map();
let prazoTocado = false;
let cadastrosCarregados = false;

async function carregarCadastros() {
  if (cadastrosCarregados) return;
  [dentistas, servicos, usuarios] = await Promise.all([listarDentistas(), listarServicos(), listarUsuarios()]);
  cadastrosCarregados = true;
}

function opcoesDentista(selecionado) {
  const ativos = dentistas.filter((d) => d.ativo || d.id === selecionado);
  form.elements.dentista_id.innerHTML =
    '<option value="">Selecione...</option>' +
    ativos.map((d) => `<option value="${d.id}">${esc(d.nome)}${d.clinica ? ` — ${esc(d.clinica)}` : ''}</option>`).join('');
}

function opcoesTecnico() {
  form.elements.tecnico_responsavel_id.innerHTML =
FIM_ARQUIVO_PW

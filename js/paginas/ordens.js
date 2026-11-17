import { iniciarAreaLogada, somenteLeitura } from '../layout.js';
import { ehGestor } from '../auth.js';
import {
  listarOrdens, obterOrdem, salvarOrdem, alterarStatusOrdem, listarHistorico,
  listarDentistas, listarServicos, listarUsuarios, listarPrecosDentista,
} from '../dados.js';
import { esc, formatarMoeda, lerMoeda, moedaParaCampo, normalizarBusca } from '../formatos.js';
import { ligarFormulario, limparFormulario, modal, mostrarToast, mostrarAlerta, esconderAlerta } from '../ui.js';
import { agruparPorCategoria } from '../categorias.js';
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
    '<option value="">Ninguém definido</option>' + usuarios.map((u) => `<option value="${u.id}">${esc(u.nome)}</option>`).join('');
}

function opcoesServico(select, selecionado) {
  const ativos = servicos.filter((s) => s.ativo || s.id === selecionado);
  const opcao = (s) => `<option value="${s.id}">${esc(s.nome)}</option>`;
  const grupos = agruparPorCategoria(ativos);
  // Uma categoria só (ou nenhuma): lista simples; várias: agrupa (ex.: barra de protocolo dentro de "Metal")
  select.innerHTML =
    '<option value="">Selecione...</option>' +
    (grupos.length < 2
      ? ativos.map(opcao).join('')
      : grupos.map(([cat, itens]) => `<optgroup label="${esc(cat)}">${itens.map(opcao).join('')}</optgroup>`).join(''));
  if (selecionado) select.value = selecionado;
}

function adicionarItem(item = null) {
  const linha = modeloItem.content.firstElementChild.cloneNode(true);
  opcoesServico(linha.querySelector('[data-campo="servico_id"]'), item?.servico_id);
  linha.querySelector('[data-campo="dentes"]').value = item?.dentes ?? '';
  linha.querySelector('[data-campo="quantidade"]').value = item?.quantidade ?? 1;
  // Item já salvo mantém o preço com que foi lançado
  if (item?.valor_unitario != null) {
    linha.dataset.valorOriginal = item.valor_unitario;
    linha.dataset.servicoOriginal = item.servico_id;
  }
  linha.classList.add('item-novo');
  corpoItens.append(linha);
  atualizarTotais();
  return linha;
}

function precoDoServico(servicoId) {
  if (precosDentista.has(servicoId)) return precosDentista.get(servicoId);
  return Number(servicos.find((s) => s.id === servicoId)?.preco_padrao ?? 0);
}

function valorUnitarioDaLinha(linha) {
  const servicoId = linha.querySelector('[data-campo="servico_id"]').value;
  if (!servicoId) return null;
  if (linha.dataset.valorOriginal && linha.dataset.servicoOriginal === servicoId) return Number(linha.dataset.valorOriginal);
  return precoDoServico(servicoId);
}

function atualizarTotais() {
  let soma = 0;
  corpoItens.querySelectorAll('.linha-item').forEach((linha) => {
    const unit = valorUnitarioDaLinha(linha);
    const qtd = Number(linha.querySelector('[data-campo="quantidade"]').value) || 0;
    const total = unit == null ? null : unit * qtd;
    linha.querySelector('[data-campo="valor"]').textContent = total == null ? '—' : formatarMoeda(total);
    soma += total ?? 0;
  });
  const desconto = lerMoeda(form.elements.desconto.value) || 0;
  el('total-os').textContent = formatarMoeda(Math.max(soma - desconto, 0));
  sugerirPrazo();
}

/** Prazo sugerido: maior prazo padrão entre os serviços (até a pessoa mexer no campo). */
function sugerirPrazo() {
  if (prazoTocado || ordemAtual) return;
  const dias = Math.max(
    0,
    ...[...corpoItens.querySelectorAll('[data-campo="servico_id"]')].map(
      (s) => servicos.find((sv) => sv.id === s.value)?.prazo_padrao_dias ?? 0,
    ),
  );
  if (!dias) return;
  const data = new Date();
  data.setDate(data.getDate() + dias);
  form.elements.prazo.value = paraCampoData(data);
}

function paraCampoData(data) {
  const d = new Date(data);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

corpoItens.addEventListener('input', atualizarTotais);
corpoItens.addEventListener('change', atualizarTotais);
corpoItens.addEventListener('click', (e) => {
  const remover = e.target.closest('[data-remover]');
  if (!remover) return;
  const linha = remover.closest('tr');
  linha.classList.add('item-saindo');
  linha.addEventListener('animationend', () => { linha.remove(); atualizarTotais(); }, { once: true });
});
el('btn-add-item').addEventListener('click', () => adicionarItem().querySelector('select').focus());
form.elements.prazo.addEventListener('input', () => (prazoTocado = true));
form.elements.desconto.addEventListener('input', atualizarTotais);

form.elements.dentista_id.addEventListener('change', async () => {
  precosDentista = new Map();
  const id = form.elements.dentista_id.value;
  // Técnico não lê a tabela de preços (RLS); o banco aplica o preço certo ao salvar.
  if (id && gestor) {
    try { precosDentista = await listarPrecosDentista(id); } catch { /* usa preço padrão */ }
  }
  atualizarTotais();
});

async function abrirOrdem(id = null) {
  limparFormulario(form, alerta);
  corpoItens.innerHTML = '';
  ordemAtual = null;
  prazoTocado = false;
  precosDentista = new Map();
  modal(elModal).show();

  try {
    await carregarCadastros();
    opcoesTecnico();

    if (!id) {
      el('titulo-os').textContent = 'Nova ordem de serviço';
      el('status-atual').innerHTML = '';
      el('painel-etapa').hidden = true;
      opcoesDentista();
      adicionarItem();
      definirEdicao(true);
      return;
    }

    ordemAtual = await obterOrdem(id);
    el('titulo-os').textContent = `OS #${ordemAtual.numero}`;
    el('status-atual').innerHTML = badgeStatus(ordemAtual.status);
    opcoesDentista(ordemAtual.dentista_id);
    form.elements.dentista_id.value = ordemAtual.dentista_id;
    form.elements.paciente.value = ordemAtual.paciente;
    form.elements.cor.value = ordemAtual.cor ?? '';
    form.elements.prazo.value = paraCampoData(ordemAtual.prazo_entrega);
    form.elements.tecnico_responsavel_id.value = ordemAtual.tecnico_responsavel_id ?? '';
    form.elements.observacoes.value = ordemAtual.observacoes ?? '';
    form.elements.desconto.value = Number(ordemAtual.desconto) ? moedaParaCampo(ordemAtual.desconto) : '';
    if (gestor) {
      try { precosDentista = await listarPrecosDentista(ordemAtual.dentista_id); } catch { /* ignora */ }
    }
    ordemAtual.itens.forEach((item) => adicionarItem(item));
    atualizarTotais();

    // Entregue/cancelada: só consulta (muda pela etapa, se precisar)
    definirEdicao(podeEditar && ABERTAS.includes(ordemAtual.status));
    await desenharEtapa();
  } catch (erro) {
    mostrarAlerta(alerta, 'danger', erro.message);
  }
}

function definirEdicao(habilitado) {
  form.querySelectorAll('.col-lg-8 input, .col-lg-8 select, .col-lg-8 textarea, .col-lg-8 button').forEach((c) => (c.disabled = !habilitado));
  el('btn-salvar').hidden = !habilitado;
}

async function desenharEtapa() {
  el('painel-etapa').hidden = false;
  const status = el('status');
  status.innerHTML = Object.entries(STATUS).map(([k, s]) => `<option value="${k}">${s.rotulo}</option>`).join('');
  status.value = ordemAtual.status;
  status.disabled = !podeEditar;

  const proxima = PROXIMA_ETAPA[ordemAtual.status];
  const avancar = el('btn-avancar');
  avancar.hidden = !proxima || !podeEditar;
  if (proxima) avancar.innerHTML = `<i class="bi ${STATUS[proxima].icone}"></i> Marcar como ${STATUS[proxima].rotulo.toLowerCase()}`;

  const historico = await listarHistorico(ordemAtual.id);
  el('historico').innerHTML = historico
    .map(
      (h) => `
      <li>
        <span class="ponto bg-${STATUS[h.status_novo].cor}"></span>
        <div><strong>${STATUS[h.status_novo].rotulo}</strong></div>
        <div class="text-secondary small">${dataHora.format(new Date(h.criado_em))}${h.usuario?.nome ? ` · ${esc(h.usuario.nome)}` : ''}</div>
      </li>`,
    )
    .join('');
}

async function mudarEtapa(novo) {
  if (!ordemAtual || novo === ordemAtual.status) return;
  if (novo === 'CANCELADO' && !confirm(`Cancelar a OS #${ordemAtual.numero}?`)) {
    el('status').value = ordemAtual.status;
    return;
  }
  esconderAlerta(alerta);
  try {
    await alterarStatusOrdem(ordemAtual.id, novo);
    mostrarToast(`OS #${ordemAtual.numero}: ${STATUS[novo].rotulo}.`);
    await carregar();
    await abrirOrdem(ordemAtual.id);
  } catch (erro) {
    el('status').value = ordemAtual.status;
    mostrarAlerta(alerta, 'danger', erro.message);
  }
}

el('status').addEventListener('change', (e) => mudarEtapa(e.target.value));
el('btn-avancar').addEventListener('click', () => mudarEtapa(PROXIMA_ETAPA[ordemAtual.status]));

ligarFormulario(form, {
  alerta,
  validacaoExtra: (f) => {
    const desconto = lerMoeda(f.elements.desconto.value);
    f.elements.desconto.setCustomValidity(desconto !== null && (Number.isNaN(desconto) || desconto < 0) ? 'inválido' : '');
  },
  aoEnviar: async (dados) => {
    const itens = [...corpoItens.querySelectorAll('.linha-item')]
      .map((linha) => {
        const servicoId = linha.querySelector('[data-campo="servico_id"]').value;
        const item = {
          servico_id: servicoId,
          dentes: linha.querySelector('[data-campo="dentes"]').value.trim(),
          quantidade: Number(linha.querySelector('[data-campo="quantidade"]').value) || 1,
        };
        // Mantém o preço original de itens já lançados; os novos usam a tabela de preços do banco
        if (linha.dataset.valorOriginal && linha.dataset.servicoOriginal === servicoId) {
          item.valor_unitario = Number(linha.dataset.valorOriginal);
        }
        return item;
      })
      .filter((i) => i.servico_id);

    // Prazo às 18h do dia escolhido (horário local)
    const [ano, mes, dia] = dados.prazo.split('-').map(Number);
    const registro = {
      dentista_id: dados.dentista_id,
      paciente: dados.paciente.trim(),
      cor: dados.cor.trim() || null,
      observacoes: dados.observacoes.trim() || null,
      prazo_entrega: new Date(ano, mes - 1, dia, 18).toISOString(),
      tecnico_responsavel_id: dados.tecnico_responsavel_id || null,
    };
    if (gestor) registro.desconto = lerMoeda(dados.desconto) || 0;

    const eraNova = !ordemAtual;
    const id = await salvarOrdem(registro, itens, ordemAtual?.id);
    modal(elModal).hide();
    await carregar();
    const salva = ordens.find((o) => o.id === id);
    mostrarToast(eraNova ? `OS #${salva?.numero ?? ''} lançada.` : 'Ordem atualizada.');
  },
});

if (podeEditar) {
  el('btn-nova').hidden = false;
  el('btn-nova').addEventListener('click', () => abrirOrdem());
}

await carregar();

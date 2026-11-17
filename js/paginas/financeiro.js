// Financeiro: fatura mensal por dentista (junta as OS entregues no mês) e recebimentos.
import { iniciarAreaLogada } from '../layout.js';
import { ehGestor } from '../auth.js';
import {
  listarDentistas, resumoFinanceiro, gerarFatura, listarPagamentos, registrarPagamento,
  excluirPagamento, excluirFatura, alterarVencimento, FORMAS_PAGAMENTO, SITUACAO_FATURA,
} from '../dados.js';
import { esc, formatarMoeda, lerMoeda, moedaParaCampo } from '../formatos.js';
import { ligarFormulario, limparFormulario, modal, mostrarToast, mostrarAlerta, esconderAlerta, carregandoBotao } from '../ui.js';
import { ligarCalendario, paraIso, deIso, hoje, somarDias } from '../calendario.js';

const { perfil, podeGerenciar } = await iniciarAreaLogada('financeiro');
if (!ehGestor(perfil)) {
  location.replace('inicio.html');
  await new Promise(() => {}); // para aqui: técnico não acessa o financeiro
}

const el = (id) => document.getElementById(id);
const MESES = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
const dataCurta = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });
const fmtDia = (iso) => (iso ? dataCurta.format(deIso(iso)) : '—');
const nomeMes = (comp) => { const d = deIso(comp); return `${MESES[d.getMonth()]} de ${d.getFullYear()}`; };
const maiuscula = (t) => t.charAt(0).toUpperCase() + t.slice(1);
const mesCurto = (comp) => { const d = deIso(comp); return `${MESES[d.getMonth()].slice(0, 3)}/${d.getFullYear()}`; };

// Mês exibido: ?mes=AAAA-MM na URL ou o mês atual
const param = new URLSearchParams(location.search).get('mes');
let competencia = /^\d{4}-\d{2}$/.test(param ?? '') ? `${param}-01` : paraIso(new Date(hoje().getFullYear(), hoje().getMonth(), 1));

let dentistas = new Map();
let linhas = []; // por dentista
let dadosMes = null;

// ---------- Carregar ----------
async function carregar() {
  el('mes-titulo').textContent = maiuscula(nomeMes(competencia));
  history.replaceState(null, '', `?mes=${competencia.slice(0, 7)}`);
  esconderAlerta(el('alerta'));
  try {
    if (!dentistas.size) dentistas = new Map((await listarDentistas()).map((d) => [d.id, d]));
    dadosMes = await resumoFinanceiro(competencia);
    montarLinhas();
    desenhar();
  } catch (erro) {
    mostrarAlerta(el('alerta'), 'danger', erro.message);
  }
}

function montarLinhas() {
  const porDentista = new Map();
  const linha = (id) => {
    if (!porDentista.has(id)) porDentista.set(id, { dentistaId: id, nome: dentistas.get(id)?.nome ?? 'Dentista', os: [], fatura: null, pendentes: 0 });
    return porDentista.get(id);
  };
  dadosMes.entregues.forEach((o) => linha(o.dentista_id).os.push(o));
  dadosMes.faturas.forEach((f) => (linha(f.dentista_id).fatura = f));
  dadosMes.pendentes.forEach((o) => porDentista.has(o.dentista_id) && linha(o.dentista_id).pendentes++);

  linhas = [...porDentista.values()].map((l) => {
    const valor = l.os.reduce((t, o) => t + Number(o.valor_total || 0), 0);
    // OS entregue que ainda não está na fatura deste mês → fatura precisa ser atualizada
    const foraDaFatura = l.fatura ? l.os.filter((o) => o.fechamento_id !== l.fatura.id).length : 0;
    return { ...l, valor, foraDaFatura };
  });
  linhas.sort((a, b) => b.valor - a.valor || a.nome.localeCompare(b.nome));
}

// ---------- Desenho ----------
function desenhar() {
  const entregue = linhas.reduce((t, l) => t + l.valor, 0);
  const faturado = dadosMes.faturas.reduce((t, f) => t + Number(f.valor_total), 0);
  const recebido = dadosMes.faturas.reduce((t, f) => t + Number(f.valor_pago), 0);
  const aReceber = Math.max(faturado - recebido, 0);
  const semFatura = linhas.filter((l) => l.os.length && !l.fatura).length;
  const pagas = dadosMes.faturas.filter((f) => f.status === 'PAGO').length;

  const kpis = [
    { icone: 'bi-truck', cor: 'roxo', rotulo: 'Entregue no mês', valor: formatarMoeda(entregue),
      extra: `<span class="selo selo-neutro">${linhas.reduce((t, l) => t + l.os.length, 0)} OS entregues</span>` },
    { icone: 'bi-receipt', cor: 'azul', rotulo: 'Faturado', valor: formatarMoeda(faturado),
      extra: semFatura ? `<span class="selo selo-baixa">${semFatura} dentista${semFatura > 1 ? 's' : ''} sem fatura</span>` : '<span class="selo selo-alta">tudo faturado</span>' },
    { icone: 'bi-cash-coin', cor: 'verde', rotulo: 'Recebido', valor: formatarMoeda(recebido),
      extra: `<span class="selo selo-neutro">${pagas} de ${dadosMes.faturas.length} faturas pagas</span>` },
    { icone: 'bi-hourglass-split', cor: 'laranja', rotulo: 'A receber', valor: formatarMoeda(aReceber),
      extra: aReceber ? '<span class="selo selo-baixa">em aberto</span>' : '<span class="selo selo-alta">nada pendente</span>' },
  ];
  el('kpis').innerHTML = kpis
    .map((k, i) => `
    <div class="kpi" style="animation-delay:${i * 60}ms">
      <span class="kpi-icone kpi-${k.cor}"><i class="bi ${k.icone}"></i></span>
      <div class="kpi-rotulo">${k.rotulo}</div>
      <div class="kpi-valor">${k.valor}</div>
      <div class="kpi-extra">${k.extra}</div>
    </div>`)
    .join('');

  const pendentes = dadosMes.pendentes.length;
  el('aviso-pendentes').innerHTML = pendentes
    ? `<i class="bi bi-info-circle"></i> ${pendentes} OS deste mês ainda não ${pendentes > 1 ? 'foram entregues' : 'foi entregue'}`
    : '';

  el('btn-gerar-todas').hidden = !podeGerenciar || !linhas.some((l) => l.os.length && (!l.fatura || l.foraDaFatura));
  el('vazio').hidden = linhas.length > 0;
  el('linhas').innerHTML = linhas.map(desenharLinha).join('');

  const anteriores = dadosMes.anteriores;
  el('anteriores').innerHTML = anteriores.length
    ? anteriores
        .map((f) => {
          const saldo = Number(f.valor_total) - Number(f.valor_pago);
          const vencida = f.vencimento && deIso(f.vencimento) < hoje();
          return `
        <li>
          <div class="me-auto">
            <strong>${esc(dentistas.get(f.dentista_id)?.nome)}</strong>
            <div class="small text-secondary">${mesCurto(f.competencia)}${f.vencimento ? ` · vence ${fmtDia(f.vencimento)}` : ''}
              ${vencida ? '<span class="selo selo-baixa ms-1">vencida</span>' : ''}</div>
          </div>
          <div class="text-end">
            <div class="fw-semibold">${formatarMoeda(saldo)}</div>
            <a class="small" href="?mes=${f.competencia.slice(0, 7)}">abrir mês</a>
          </div>
        </li>`;
        })
        .join('')
    : '<li class="text-secondary small justify-content-center"><i class="bi bi-check2-circle text-success me-1"></i> Nada em aberto.</li>';
}

function desenharLinha(l) {
  const f = l.fatura;
  const sit = f ? SITUACAO_FATURA[f.status] : null;
  const saldo = f ? Number(f.valor_total) - Number(f.valor_pago) : 0;
  const vencida = f && f.status !== 'PAGO' && f.vencimento && deIso(f.vencimento) < hoje();

  let faturaHtml = '<span class="badge rounded-pill text-bg-light border">Sem fatura</span>';
  if (f) {
    faturaHtml = `<span class="badge rounded-pill text-bg-${sit.cor} status-badge"><i class="bi ${sit.icone}"></i> ${sit.rotulo}</span>
      <div class="small text-secondary mt-1">${f.vencimento ? `Vence ${fmtDia(f.vencimento)}` : 'Sem vencimento'}
        ${vencida ? '<span class="selo selo-baixa ms-1">vencida</span>' : ''}</div>
      ${f.status === 'PARCIAL' ? `<div class="small">Falta ${formatarMoeda(saldo)}</div>` : ''}
      ${l.foraDaFatura ? `<div class="small text-warning-emphasis"><i class="bi bi-exclamation-triangle"></i> ${l.foraDaFatura} OS nova${l.foraDaFatura > 1 ? 's' : ''} fora da fatura</div>` : ''}`;
  }

  const acoes = [];
  if (podeGerenciar && l.os.length && !f) {
    acoes.push(`<button type="button" class="btn btn-sm btn-primary" data-acao="gerar"><i class="bi bi-receipt"></i> Gerar fatura</button>`);
  }
  if (f) {
    if (podeGerenciar && l.foraDaFatura) acoes.push(`<button type="button" class="btn btn-sm btn-warning" data-acao="gerar"><i class="bi bi-arrow-repeat"></i> Atualizar</button>`);
    acoes.push(`<a class="btn btn-sm btn-outline-primary" href="fatura.html?id=${encodeURIComponent(f.id)}" target="_blank"><i class="bi bi-printer"></i> Fatura</a>`);
    acoes.push(`<button type="button" class="btn btn-sm ${f.status === 'PAGO' ? 'btn-outline-secondary' : 'btn-success'}" data-acao="receber">
      <i class="bi bi-cash-coin"></i> ${f.status === 'PAGO' ? 'Pagamentos' : 'Receber'}</button>`);
    if (podeGerenciar) {
      acoes.push(`<div class="dropdown d-inline-block">
        <button type="button" class="btn btn-sm btn-light" data-bs-toggle="dropdown" aria-label="Mais opções"><i class="bi bi-three-dots-vertical"></i></button>
        <ul class="dropdown-menu dropdown-menu-end">
          <li><button type="button" class="dropdown-item" data-acao="vencimento"><i class="bi bi-calendar3"></i> Mudar vencimento</button></li>
          <li><button type="button" class="dropdown-item text-danger" data-acao="excluir"><i class="bi bi-trash"></i> Excluir fatura</button></li>
        </ul></div>`);
    }
  }

  return `
    <tr data-dentista="${l.dentistaId}">
      <td>
        <div class="fw-semibold">${esc(l.nome)}</div>
        ${dentistas.get(l.dentistaId)?.clinica ? `<div class="small text-secondary">${esc(dentistas.get(l.dentistaId).clinica)}</div>` : ''}
      </td>
      <td class="text-center">${l.os.length}${l.pendentes ? `<div class="small text-secondary" title="Ainda não entregues">+${l.pendentes} em produção</div>` : ''}</td>
      <td class="text-end fw-semibold">${formatarMoeda(f ? f.valor_total : l.valor)}</td>
      <td>${faturaHtml}</td>
      <td class="text-end"><div class="d-inline-flex flex-wrap gap-1 justify-content-end">${acoes.join('')}</div></td>
    </tr>`;
}

// ---------- Navegação de mês ----------
function mudarMes(delta) {
  const d = deIso(competencia);
  competencia = paraIso(new Date(d.getFullYear(), d.getMonth() + delta, 1));
  carregar();
}
el('mes-anterior').addEventListener('click', () => mudarMes(-1));
el('mes-seguinte').addEventListener('click', () => mudarMes(1));

// ---------- Gerar / atualizar fatura ----------
const formGerar = el('form-gerar');
const modalGerar = el('modal-gerar');
ligarCalendario(formGerar.elements.vencimento, {
  atalhos: [
    { rotulo: 'Hoje', dias: 0 },
    { rotulo: '7 dias', dias: 7 },
    { rotulo: '15 dias', dias: 15 },
    { rotulo: '30 dias', dias: 30 },
  ],
  tomRelativo: true,
});
let alvoGerar = []; // linhas
let somenteVencimento = false;

/** Vencimento padrão: dia 10 do mês seguinte à competência (ou daqui a 7 dias, se já passou). */
function vencimentoPadrao() {
  const d = deIso(competencia);
  const dia10 = new Date(d.getFullYear(), d.getMonth() + 1, 10);
  return paraIso(dia10 < hoje() ? somarDias(hoje(), 7) : dia10);
}

function abrirGerar(alvos, { soVencimento = false } = {}) {
  alvoGerar = alvos;
  somenteVencimento = soVencimento;
  limparFormulario(formGerar, el('alerta-gerar'));
  const unica = alvos.length === 1 ? alvos[0] : null;
  const atualizar = unica?.fatura;
  el('titulo-gerar').textContent = soVencimento ? 'Mudar vencimento' : atualizar ? 'Atualizar fatura' : alvos.length > 1 ? 'Gerar faturas do mês' : 'Gerar fatura';
  el('rotulo-gerar').textContent = soVencimento ? 'Salvar' : atualizar ? 'Atualizar' : alvos.length > 1 ? `Gerar ${alvos.length} faturas` : 'Gerar';
  const total = alvos.reduce((t, l) => t + l.valor, 0);
  const qtdOs = alvos.reduce((t, l) => t + l.os.length, 0);
  el('texto-gerar').innerHTML = unica
    ? `<strong>${esc(unica.nome)}</strong> · ${nomeMes(competencia)}<br>
       <span class="text-secondary">${unica.os.length} OS entregue${unica.os.length > 1 ? 's' : ''} · ${formatarMoeda(unica.valor)}</span>`
    : `${alvos.length} dentistas · ${nomeMes(competencia)}<br><span class="text-secondary">${qtdOs} OS entregues · ${formatarMoeda(total)}</span>`;
  formGerar.elements.vencimento.value = unica?.fatura?.vencimento ?? vencimentoPadrao();
  modal(modalGerar).show();
}

ligarFormulario(formGerar, {
  alerta: el('alerta-gerar'),
  aoEnviar: async ({ vencimento }) => {
    for (const l of alvoGerar) {
      if (somenteVencimento) {
        await alterarVencimento(l.fatura.id, vencimento);
      } else {
        await gerarFatura(l.dentistaId, competencia, vencimento);
      }
    }
    modal(modalGerar).hide();
    mostrarToast(
      somenteVencimento ? 'Vencimento alterado.' : alvoGerar.length > 1 ? `${alvoGerar.length} faturas geradas.` : 'Fatura pronta.',
    );
    await carregar();
  },
});

el('btn-gerar-todas').addEventListener('click', () =>
  abrirGerar(linhas.filter((l) => l.os.length && (!l.fatura || l.foraDaFatura))),
);

// ---------- Ações da tabela ----------
el('linhas').addEventListener('click', async (e) => {
  const botao = e.target.closest('[data-acao]');
  if (!botao) return;
  const l = linhas.find((x) => x.dentistaId === botao.closest('tr').dataset.dentista);
  const acao = botao.dataset.acao;
  if (acao === 'gerar') abrirGerar([l]);
  if (acao === 'vencimento') abrirGerar([l], { soVencimento: true });
  if (acao === 'receber') abrirPagamentos(l);
  if (acao === 'excluir') {
    const temPagamento = Number(l.fatura.valor_pago) > 0;
    const msg = `Excluir a fatura de ${l.nome} (${nomeMes(competencia)})?` +
      (temPagamento ? '\n\nOs pagamentos lançados nela também serão apagados.' : '') +
      '\n\nAs OS continuam salvas e podem entrar em uma nova fatura.';
    if (!confirm(msg)) return;
    try {
      await excluirFatura(l.fatura.id);
      mostrarToast('Fatura excluída.');
      await carregar();
    } catch (erro) {
      mostrarAlerta(el('alerta'), 'danger', erro.message);
    }
  }
});

// ---------- Pagamentos ----------
const formPag = el('form-pagamento');
const modalPag = el('modal-pagamento');
let linhaPag = null;

formPag.elements.forma.innerHTML = Object.entries(FORMAS_PAGAMENTO).map(([k, v]) => `<option value="${k}">${v}</option>`).join('');
ligarCalendario(formPag.elements.data, { atalhos: [{ rotulo: 'Hoje', dias: 0 }, { rotulo: 'Ontem', dias: -1 }], maximo: 'hoje' });

async function abrirPagamentos(l) {
  linhaPag = l;
  limparFormulario(formPag, el('alerta-pagamento'));
  el('erro-valor').style.display = 'none';
  el('titulo-pagamento').textContent = `${l.nome} · ${nomeMes(competencia)}`;
  await desenharPagamentos();
  modal(modalPag).show();
}

async function desenharPagamentos() {
  const f = linhaPag.fatura;
  const saldo = Math.max(Number(f.valor_total) - Number(f.valor_pago), 0);
  const sit = SITUACAO_FATURA[f.status];
  el('resumo-fatura').innerHTML = `
    <div><span>Total da fatura</span><strong>${formatarMoeda(f.valor_total)}</strong></div>
    <div><span>Já recebido</span><strong class="text-success">${formatarMoeda(f.valor_pago)}</strong></div>
    <div><span>Falta receber</span><strong class="${saldo ? 'text-danger' : ''}">${formatarMoeda(saldo)}</strong></div>
    <div><span>Situação</span><span class="badge rounded-pill text-bg-${sit.cor} status-badge"><i class="bi ${sit.icone}"></i> ${sit.rotulo}</span></div>`;

  const quitada = saldo <= 0;
  el('novo-pagamento').hidden = quitada || !podeGerenciar;
  el('btn-registrar').hidden = quitada || !podeGerenciar;
  formPag.elements.valor.value = moedaParaCampo(saldo);
  formPag.elements.data.value = paraIso(hoje());

  const pagamentos = await listarPagamentos(f.id);
  el('pagamentos').innerHTML = pagamentos.length
    ? pagamentos
        .map(
          (p) => `
      <li>
        <span class="pag-icone"><i class="bi bi-cash"></i></span>
        <div class="me-auto">
          <strong>${formatarMoeda(p.valor)}</strong> <span class="text-secondary">· ${FORMAS_PAGAMENTO[p.forma] ?? p.forma}</span>
          <div class="small text-secondary">${fmtDia(p.data)}${p.observacao ? ` · ${esc(p.observacao)}` : ''}</div>
        </div>
        ${podeGerenciar ? `<button type="button" class="btn btn-sm btn-link text-danger" data-excluir-pag="${p.id}" aria-label="Excluir pagamento"><i class="bi bi-trash"></i></button>` : ''}
      </li>`,
        )
        .join('')
    : '<li class="text-secondary small">Nenhum pagamento lançado ainda.</li>';
}

/** Recarrega a fatura do mês depois de mexer em pagamentos. */
async function atualizarFaturaAberta() {
  await carregar();
  linhaPag = linhas.find((x) => x.dentistaId === linhaPag.dentistaId) ?? linhaPag;
  await desenharPagamentos();
}

ligarFormulario(formPag, {
  alerta: el('alerta-pagamento'),
  validacaoExtra: (f) => {
    const v = lerMoeda(f.elements.valor.value);
    const invalido = !(v > 0);
    f.elements.valor.setCustomValidity(invalido ? 'inválido' : '');
    el('erro-valor').style.display = invalido && f.classList.contains('was-validated') ? 'block' : 'none';
  },
  aoEnviar: async (dados) => {
    const valor = lerMoeda(dados.valor);
    const saldo = Number(linhaPag.fatura.valor_total) - Number(linhaPag.fatura.valor_pago);
    if (valor > saldo + 0.001 && !confirm(`O valor é maior que o que falta (${formatarMoeda(saldo)}). Registrar mesmo assim?`)) return;
    await registrarPagamento(linhaPag.fatura.id, { valor, data: dados.data, forma: dados.forma, observacao: dados.observacao.trim() });
    mostrarToast('Pagamento registrado.');
    formPag.classList.remove('was-validated');
    el('erro-valor').style.display = 'none';
    formPag.elements.observacao.value = '';
    await atualizarFaturaAberta();
  },
});

// ligarFormulario marca o formulário como validado só depois de checar; mostra o erro do valor no envio
formPag.addEventListener('submit', () => {
  el('erro-valor').style.display = formPag.elements.valor.validity.valid ? 'none' : 'block';
});

el('pagamentos').addEventListener('click', async (e) => {
  const botao = e.target.closest('[data-excluir-pag]');
  if (!botao || !confirm('Excluir este pagamento?')) return;
  carregandoBotao(botao, true);
  try {
    await excluirPagamento(botao.dataset.excluirPag);
    mostrarToast('Pagamento excluído.');
    await atualizarFaturaAberta();
  } catch (erro) {
    carregandoBotao(botao, false);
    mostrarAlerta(el('alerta-pagamento'), 'danger', erro.message);
  }
});

await carregar();

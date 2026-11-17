import { iniciarAreaLogada } from '../layout.js';
import { ehGestor } from '../auth.js';
import { dadosPainel } from '../dados.js';
import { esc, formatarMoeda } from '../formatos.js';
import { STATUS, ABERTAS, estaAtrasada } from '../status.js';

const { perfil } = await iniciarAreaLogada('inicio');
const gestor = ehGestor(perfil);
document.body.classList.toggle('modo-tecnico', !gestor);

const el = (id) => document.getElementById(id);
const DIA = 86400000;
const nomeMes = new Intl.DateTimeFormat('pt-BR', { month: 'long' });
const mesCurto = new Intl.DateTimeFormat('pt-BR', { month: 'short' });
const dataCurta = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit' });
const semMovimento = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// ---------- Saudação ----------
const hora = new Date().getHours();
const primeiroNome = (perfil?.nome ?? '').split(' ')[0];
el('saudacao').textContent = `${hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite'}${primeiroNome ? `, ${primeiroNome}` : ''}!`;

// ---------- Períodos ----------
const agora = new Date();
const inicioMes = new Date(agora.getFullYear(), agora.getMonth(), 1);
const inicioMesAnterior = new Date(agora.getFullYear(), agora.getMonth() - 1, 1);
// Mesmo ponto do mês passado (comparação justa: dia 17 com dia 17)
const limiteMesAnterior = new Date(Math.min(inicioMesAnterior.getTime() + (agora - inicioMes), inicioMes.getTime()));
const inicioGrafico = new Date(agora.getFullYear(), agora.getMonth() - 5, 1);

const soma = (lista, f) => lista.reduce((t, x) => t + Number(f(x) || 0), 0);
const entre = (o, de, ate) => {
  const d = new Date(o.data_entrada);
  return d >= de && d < ate;
};

/** Anima um número de 0 até o valor final. */
function contar(elemento, valor, moeda = false) {
  const mostrar = (v) => (elemento.textContent = moeda ? formatarMoeda(v) : Math.round(v).toLocaleString('pt-BR'));
  if (semMovimento || !valor) return mostrar(valor);
  const inicio = performance.now();
  const duracao = 900;
  const passo = (t) => {
    const p = Math.min((t - inicio) / duracao, 1);
    mostrar(valor * (1 - Math.pow(1 - p, 3)));
    if (p < 1) requestAnimationFrame(passo);
  };
  requestAnimationFrame(passo);
}

function variacaoPct(atual, anterior) {
  if (!anterior) return null;
  return ((atual - anterior) / anterior) * 100;
}

function selo(pct, sufixo = 'vs. mês passado') {
  if (pct === null) return '<span class="selo selo-neutro"><i class="bi bi-dash"></i> sem comparação</span>';
  const cls = pct >= 5 ? 'selo-alta' : pct <= -5 ? 'selo-baixa' : 'selo-neutro';
  const icone = pct >= 5 ? 'bi-arrow-up-right' : pct <= -5 ? 'bi-arrow-down-right' : 'bi-arrow-right';
  return `<span class="selo ${cls}"><i class="bi ${icone}"></i> ${pct > 0 ? '+' : ''}${pct.toFixed(0)}% <span class="selo-txt">${sufixo}</span></span>`;
}

// ---------- Carregar ----------
let periodo = [];
let abertas = [];
try {
  ({ periodo, abertas } = await dadosPainel(inicioGrafico));
} catch (erro) {
  el('hero-titulo').textContent = 'Não foi possível carregar o painel';
  el('hero-sub').textContent = erro.message;
  throw erro;
}

const vendidas = periodo.filter((o) => o.status !== 'CANCELADO');
const doMes = vendidas.filter((o) => entre(o, inicioMes, new Date(agora.getTime() + DIA)));
const mesPassadoParcial = vendidas.filter((o) => entre(o, inicioMesAnterior, limiteMesAnterior));

const faturamentoMes = soma(doMes, (o) => o.valor_total);
const faturamentoAnterior = soma(mesPassadoParcial, (o) => o.valor_total);
const varFaturamento = variacaoPct(faturamentoMes, faturamentoAnterior);
const varQuantidade = variacaoPct(doMes.length, mesPassadoParcial.length);
const ticket = doMes.length ? faturamentoMes / doMes.length : 0;
const ticketAnterior = mesPassadoParcial.length ? faturamentoAnterior / mesPassadoParcial.length : 0;
const entreguesMes = periodo.filter((o) => o.status === 'ENTREGUE' && o.data_entrega && new Date(o.data_entrega) >= inicioMes).length;

const atrasadas = abertas.filter(estaAtrasada);
const fimHoje = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate() + 1);
const paraHoje = abertas.filter((o) => !estaAtrasada(o) && new Date(o.prazo_entrega) < fimHoje);

// ---------- Destaque ----------
const mes = nomeMes.format(agora);
el('hero-rotulo-mes').textContent = `Faturamento de ${mes}`;

if (gestor) {
  let titulo;
  if (!doMes.length) titulo = 'Nenhuma ordem lançada este mês ainda';
  else if (varFaturamento === null) titulo = 'Seu laboratório começou a vender este mês';
  else if (varFaturamento >= 10) titulo = 'Você está vendendo mais que no mês passado';
  else if (varFaturamento <= -10) titulo = 'As vendas estão mais fracas que no mês passado';
  else titulo = 'Suas vendas estão estáveis';
  el('hero-titulo').textContent = titulo;

  el('hero-sub').textContent = doMes.length
    ? `${doMes.length} ${doMes.length === 1 ? 'ordem lançada' : 'ordens lançadas'} até hoje` +
      (faturamentoAnterior
        ? `, contra ${formatarMoeda(faturamentoAnterior)} no mesmo período do mês passado.`
        : '.')
    : 'Lance a primeira ordem de serviço do mês para ver as estatísticas aqui.';
  contar(el('hero-faturamento'), faturamentoMes, true);
  el('hero-tendencia').innerHTML = selo(varFaturamento, 'vs. mesmo período do mês passado');
} else {
  el('hero-titulo').textContent = atrasadas.length
    ? `${atrasadas.length} ${atrasadas.length === 1 ? 'ordem atrasada' : 'ordens atrasadas'} precisando de atenção`
    : 'Nenhuma ordem atrasada. Bom trabalho!';
  el('hero-sub').textContent = paraHoje.length
    ? `${paraHoje.length} para entregar hoje.`
    : 'Nada vence hoje.';
  contar(el('hero-abertas'), abertas.length);
  el('hero-atrasadas-txt').innerHTML = `<span class="selo ${atrasadas.length ? 'selo-baixa' : 'selo-alta'}">${atrasadas.length} atrasada${atrasadas.length === 1 ? '' : 's'}</span>`;
}

// ---------- Indicadores ----------
const kpis = [
  gestor && { icone: 'bi-cash-stack', cor: 'roxo', rotulo: 'Faturamento do mês', valor: faturamentoMes, moeda: true, extra: selo(varFaturamento) },
  { icone: 'bi-clipboard2-plus', cor: 'azul', rotulo: 'Ordens lançadas no mês', valor: doMes.length, extra: selo(varQuantidade) },
  gestor && { icone: 'bi-receipt', cor: 'verde', rotulo: 'Ticket médio', valor: ticket, moeda: true, extra: selo(variacaoPct(ticket, ticketAnterior)) },
  { icone: 'bi-truck', cor: 'ciano', rotulo: 'Entregues no mês', valor: entreguesMes, extra: '<span class="selo selo-neutro">finalizadas e entregues</span>' },
  { icone: 'bi-hourglass-split', cor: 'laranja', rotulo: 'Em aberto', valor: abertas.length, extra: `<span class="selo selo-neutro">${paraHoje.length} para hoje</span>` },
  {
    icone: 'bi-exclamation-triangle',
    cor: 'vermelho',
    rotulo: 'Atrasadas',
    valor: atrasadas.length,
    extra: atrasadas.length
      ? '<a class="selo selo-baixa text-decoration-none" href="ordens.html">ver ordens</a>'
      : '<span class="selo selo-alta">tudo em dia</span>',
  },
].filter(Boolean);

el('kpis').innerHTML = kpis
  .map(
    (k, i) => `
    <div class="kpi" style="animation-delay:${i * 60}ms">
      <span class="kpi-icone kpi-${k.cor}"><i class="bi ${k.icone}"></i></span>
      <div class="kpi-rotulo">${k.rotulo}</div>
      <div class="kpi-valor" data-kpi="${i}">${k.moeda ? formatarMoeda(0) : 0}</div>
      <div class="kpi-extra">${k.extra}</div>
    </div>`,
  )
  .join('');
kpis.forEach((k, i) => contar(document.querySelector(`[data-kpi="${i}"]`), k.valor, k.moeda));

// ---------- Faturamento por mês ----------
if (gestor) {
  const meses = Array.from({ length: 6 }, (_, i) => {
    const de = new Date(agora.getFullYear(), agora.getMonth() - 5 + i, 1);
    const ate = new Date(agora.getFullYear(), agora.getMonth() - 4 + i, 1);
    const lista = vendidas.filter((o) => entre(o, de, ate));
    return { rotulo: mesCurto.format(de).replace('.', ''), valor: soma(lista, (o) => o.valor_total), qtd: lista.length, atual: i === 5 };
  });
  const maior = Math.max(...meses.map((m) => m.valor), 1);
  el('grafico-meses').innerHTML = meses
    .map(
      (m, i) => `
      <div class="barra-col ${m.atual ? 'atual' : ''}" title="${formatarMoeda(m.valor)} · ${m.qtd} OS">
        <span class="barra-valor">${m.valor ? formatarMoeda(m.valor).replace(',00', '') : '—'}</span>
        <div class="barra-trilho"><div class="barra" style="--altura:${Math.max((m.valor / maior) * 100, m.valor ? 4 : 0)}%; animation-delay:${i * 70}ms"></div></div>
        <span class="barra-rotulo">${m.rotulo}</span>
      </div>`,
    )
    .join('');

  // ---------- Rankings ----------
  function ranking(alvo, linhas, vazio) {
    const total = soma(linhas, (l) => l.valor) || 1;
    const maiorValor = Math.max(...linhas.map((l) => l.valor), 1);
    el(alvo).innerHTML = linhas.length
      ? linhas
          .slice(0, 5)
          .map(
            (l, i) => `
          <div class="ranking-item" style="animation-delay:${i * 60}ms">
            <div class="d-flex justify-content-between gap-2 small mb-1">
              <span class="text-truncate"><span class="ranking-pos">${i + 1}</span>${esc(l.nome)}</span>
              <span class="fw-semibold text-nowrap">${formatarMoeda(l.valor)} <span class="text-secondary fw-normal">${((l.valor / total) * 100).toFixed(0)}%</span></span>
            </div>
            <div class="ranking-trilho"><div class="ranking-barra" style="--largura:${(l.valor / maiorValor) * 100}%"></div></div>
          </div>`,
          )
          .join('')
      : `<p class="text-secondary small mb-0">${vazio}</p>`;
  }

  const porDentista = new Map();
  doMes.forEach((o) => {
    const nome = o.dentista?.nome ?? 'Sem dentista';
    porDentista.set(nome, (porDentista.get(nome) ?? 0) + Number(o.valor_total));
  });
  ranking(
    'ranking-dentistas',
    [...porDentista].map(([nome, valor]) => ({ nome, valor })).sort((a, b) => b.valor - a.valor),
    'Ainda não há vendas neste mês.',
  );

  const porCategoria = new Map();
  doMes.forEach((o) =>
    (o.itens ?? []).forEach((it) => {
      const cat = it.servico?.categoria || 'Sem categoria';
      porCategoria.set(cat, (porCategoria.get(cat) ?? 0) + Number(it.valor_total));
    }),
  );
  ranking(
    'ranking-categorias',
    [...porCategoria].map(([nome, valor]) => ({ nome, valor })).sort((a, b) => b.valor - a.valor),
    'Ainda não há vendas neste mês.',
  );
}

// ---------- Próximas entregas ----------
function textoPrazo(o) {
  const dias = Math.floor((new Date(o.prazo_entrega).setHours(0, 0, 0, 0) - new Date().setHours(0, 0, 0, 0)) / DIA);
  if (dias < 0) return { txt: `Atrasada ${-dias}d`, cls: 'prazo-atrasado' };
  if (dias === 0) return { txt: 'Hoje', cls: 'prazo-hoje' };
  if (dias === 1) return { txt: 'Amanhã', cls: 'prazo-breve' };
  return { txt: dataCurta.format(new Date(o.prazo_entrega)), cls: '' };
}

const proximas = abertas.slice(0, 7);
el('entregas').innerHTML = proximas.length
  ? proximas
      .map((o, i) => {
        const p = textoPrazo(o);
        return `
        <li style="animation-delay:${i * 50}ms">
          <a href="ordens.html">
            <span class="entrega-num">#${o.numero}</span>
            <span class="entrega-info"><strong>${esc(o.paciente)}</strong><small>${esc(o.dentista?.nome)} · ${STATUS[o.status].rotulo}</small></span>
            <span class="entrega-prazo ${p.cls}">${p.txt}</span>
          </a>
        </li>`;
      })
      .join('')
  : '<li class="text-secondary small">Nenhuma ordem em aberto.</li>';

// ---------- Etapas ----------
const totalAbertas = abertas.length || 1;
el('etapas').innerHTML = abertas.length
  ? `<div class="etapas-barra">${ABERTAS.map((s) => {
      const n = abertas.filter((o) => o.status === s).length;
      return n ? `<div class="bg-${STATUS[s].cor}" style="--largura:${(n / totalAbertas) * 100}%" title="${STATUS[s].rotulo}: ${n}"></div>` : '';
    }).join('')}</div>
    <div class="etapas-legenda">${ABERTAS.map((s) => {
      const n = abertas.filter((o) => o.status === s).length;
      return `<a href="ordens.html" class="etapa-item"><span class="ponto bg-${STATUS[s].cor}"></span>${STATUS[s].rotulo}<strong>${n}</strong></a>`;
    }).join('')}</div>`
  : '<p class="text-secondary small mb-0">Nenhuma ordem em aberto no momento.</p>';

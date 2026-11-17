cat >> /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
+++ b/js/dados.js
@@ -125,6 +125,25 @@ export async function salvarOrdem(dados, itens, id = null) {
   return ordemId;
 }
 
+/** Dados do painel: OS lançadas desde a data (para faturamento) + todas em aberto (para atrasos/entregas). */
+export async function dadosPainel(desde) {
+  const campos = `id, numero, paciente, status, data_entrada, prazo_entrega, data_entrega, valor_total,
+    dentista:dentistas(nome),
+    itens:itens_ordem_servico(quantidade, valor_total, servico:servicos(nome, categoria))`;
+  const [periodo, abertas] = await Promise.all([
+    supabase.from('ordens_servico').select(campos).gte('data_entrada', desde.toISOString()).limit(5000),
+    supabase
+      .from('ordens_servico')
+      .select(campos)
+      .in('status', ['RECEBIDO', 'EM_PRODUCAO', 'EM_PROVA', 'RETORNO', 'FINALIZADO'])
+      .order('prazo_entrega')
+      .limit(1000),
+  ]);
+  if (periodo.error) throw erroAmigavel(periodo.error);
+  if (abertas.error) throw erroAmigavel(abertas.error);
+  return { periodo: periodo.data, abertas: abertas.data };
+}
+
 export async function alterarStatusOrdem(id, status) {
   const { error } = await supabase.from('ordens_servico').update({ status }).eq('id', id);
   if (error) throw erroAmigavel(error);
diff --git a/js/paginas/inicio.js b/js/paginas/inicio.js
index e2bfa9b..4b6f79e 100644
--- a/js/paginas/inicio.js
+++ b/js/paginas/inicio.js
@@ -1,5 +1,256 @@
 import { iniciarAreaLogada } from '../layout.js';
+import { ehGestor } from '../auth.js';
+import { dadosPainel } from '../dados.js';
+import { esc, formatarMoeda } from '../formatos.js';
+import { STATUS, ABERTAS, estaAtrasada } from '../status.js';
 
 const { perfil } = await iniciarAreaLogada('inicio');
+const gestor = ehGestor(perfil);
+document.body.classList.toggle('modo-tecnico', !gestor);
 
-document.getElementById('nome-usuario').textContent = perfil?.nome ?? '';
+const el = (id) => document.getElementById(id);
+const DIA = 86400000;
+const nomeMes = new Intl.DateTimeFormat('pt-BR', { month: 'long' });
+const mesCurto = new Intl.DateTimeFormat('pt-BR', { month: 'short' });
+const dataCurta = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit' });
+const semMovimento = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
+
+// ---------- Saudação ----------
+const hora = new Date().getHours();
+const primeiroNome = (perfil?.nome ?? '').split(' ')[0];
+el('saudacao').textContent = `${hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite'}${primeiroNome ? `, ${primeiroNome}` : ''}!`;
+
+// ---------- Períodos ----------
+const agora = new Date();
+const inicioMes = new Date(agora.getFullYear(), agora.getMonth(), 1);
+const inicioMesAnterior = new Date(agora.getFullYear(), agora.getMonth() - 1, 1);
+// Mesmo ponto do mês passado (comparação justa: dia 17 com dia 17)
+const limiteMesAnterior = new Date(Math.min(inicioMesAnterior.getTime() + (agora - inicioMes), inicioMes.getTime()));
+const inicioGrafico = new Date(agora.getFullYear(), agora.getMonth() - 5, 1);
+
+const soma = (lista, f) => lista.reduce((t, x) => t + Number(f(x) || 0), 0);
+const entre = (o, de, ate) => {
+  const d = new Date(o.data_entrada);
+  return d >= de && d < ate;
+};
+
+/** Anima um número de 0 até o valor final. */
+function contar(elemento, valor, moeda = false) {
+  const mostrar = (v) => (elemento.textContent = moeda ? formatarMoeda(v) : Math.round(v).toLocaleString('pt-BR'));
+  if (semMovimento || !valor) return mostrar(valor);
+  const inicio = performance.now();
+  const duracao = 900;
+  const passo = (t) => {
+    const p = Math.min((t - inicio) / duracao, 1);
+    mostrar(valor * (1 - Math.pow(1 - p, 3)));
+    if (p < 1) requestAnimationFrame(passo);
+  };
+  requestAnimationFrame(passo);
+}
+
+function variacaoPct(atual, anterior) {
+  if (!anterior) return null;
+  return ((atual - anterior) / anterior) * 100;
+}
+
+function selo(pct, sufixo = 'vs. mês passado') {
+  if (pct === null) return '<span class="selo selo-neutro"><i class="bi bi-dash"></i> sem comparação</span>';
+  const cls = pct >= 5 ? 'selo-alta' : pct <= -5 ? 'selo-baixa' : 'selo-neutro';
+  const icone = pct >= 5 ? 'bi-arrow-up-right' : pct <= -5 ? 'bi-arrow-down-right' : 'bi-arrow-right';
+  return `<span class="selo ${cls}"><i class="bi ${icone}"></i> ${pct > 0 ? '+' : ''}${pct.toFixed(0)}% <span class="selo-txt">${sufixo}</span></span>`;
+}
+
+// ---------- Carregar ----------
+let periodo = [];
+let abertas = [];
+try {
+  ({ periodo, abertas } = await dadosPainel(inicioGrafico));
+} catch (erro) {
+  el('hero-titulo').textContent = 'Não foi possível carregar o painel';
+  el('hero-sub').textContent = erro.message;
+  throw erro;
+}
+
+const vendidas = periodo.filter((o) => o.status !== 'CANCELADO');
+const doMes = vendidas.filter((o) => entre(o, inicioMes, new Date(agora.getTime() + DIA)));
+const mesPassadoParcial = vendidas.filter((o) => entre(o, inicioMesAnterior, limiteMesAnterior));
+
+const faturamentoMes = soma(doMes, (o) => o.valor_total);
+const faturamentoAnterior = soma(mesPassadoParcial, (o) => o.valor_total);
+const varFaturamento = variacaoPct(faturamentoMes, faturamentoAnterior);
+const varQuantidade = variacaoPct(doMes.length, mesPassadoParcial.length);
+const ticket = doMes.length ? faturamentoMes / doMes.length : 0;
+const ticketAnterior = mesPassadoParcial.length ? faturamentoAnterior / mesPassadoParcial.length : 0;
+const entreguesMes = periodo.filter((o) => o.status === 'ENTREGUE' && o.data_entrega && new Date(o.data_entrega) >= inicioMes).length;
+
+const atrasadas = abertas.filter(estaAtrasada);
+const fimHoje = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate() + 1);
+const paraHoje = abertas.filter((o) => !estaAtrasada(o) && new Date(o.prazo_entrega) < fimHoje);
+
+// ---------- Destaque ----------
+const mes = nomeMes.format(agora);
+el('hero-rotulo-mes').textContent = `Faturamento de ${mes}`;
+
+if (gestor) {
+  let titulo;
+  if (!doMes.length) titulo = 'Nenhuma ordem lançada este mês ainda';
+  else if (varFaturamento === null) titulo = 'Seu laboratório começou a vender este mês';
+  else if (varFaturamento >= 10) titulo = 'Você está vendendo mais que no mês passado';
+  else if (varFaturamento <= -10) titulo = 'As vendas estão mais fracas que no mês passado';
+  else titulo = 'Suas vendas estão estáveis';
+  el('hero-titulo').textContent = titulo;
+
+  el('hero-sub').textContent = doMes.length
+    ? `${doMes.length} ${doMes.length === 1 ? 'ordem lançada' : 'ordens lançadas'} até hoje` +
+      (faturamentoAnterior
+        ? `, contra ${formatarMoeda(faturamentoAnterior)} no mesmo período do mês passado.`
+        : '.')
+    : 'Lance a primeira ordem de serviço do mês para ver as estatísticas aqui.';
+  contar(el('hero-faturamento'), faturamentoMes, true);
+  el('hero-tendencia').innerHTML = selo(varFaturamento, 'vs. mesmo período do mês passado');
+} else {
+  el('hero-titulo').textContent = atrasadas.length
+    ? `${atrasadas.length} ${atrasadas.length === 1 ? 'ordem atrasada' : 'ordens atrasadas'} precisando de atenção`
+    : 'Nenhuma ordem atrasada. Bom trabalho!';
+  el('hero-sub').textContent = paraHoje.length
+    ? `${paraHoje.length} para entregar hoje.`
+    : 'Nada vence hoje.';
+  contar(el('hero-abertas'), abertas.length);
+  el('hero-atrasadas-txt').innerHTML = `<span class="selo ${atrasadas.length ? 'selo-baixa' : 'selo-alta'}">${atrasadas.length} atrasada${atrasadas.length === 1 ? '' : 's'}</span>`;
+}
+
+// ---------- Indicadores ----------
+const kpis = [
+  gestor && { icone: 'bi-cash-stack', cor: 'roxo', rotulo: 'Faturamento do mês', valor: faturamentoMes, moeda: true, extra: selo(varFaturamento) },
+  { icone: 'bi-clipboard2-plus', cor: 'azul', rotulo: 'Ordens lançadas no mês', valor: doMes.length, extra: selo(varQuantidade) },
+  gestor && { icone: 'bi-receipt', cor: 'verde', rotulo: 'Ticket médio', valor: ticket, moeda: true, extra: selo(variacaoPct(ticket, ticketAnterior)) },
+  { icone: 'bi-truck', cor: 'ciano', rotulo: 'Entregues no mês', valor: entreguesMes, extra: '<span class="selo selo-neutro">finalizadas e entregues</span>' },
FIM_ARQUIVO_PW

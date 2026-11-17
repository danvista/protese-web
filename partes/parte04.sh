cat >> /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
+  { icone: 'bi-hourglass-split', cor: 'laranja', rotulo: 'Em aberto', valor: abertas.length, extra: `<span class="selo selo-neutro">${paraHoje.length} para hoje</span>` },
+  {
+    icone: 'bi-exclamation-triangle',
+    cor: 'vermelho',
+    rotulo: 'Atrasadas',
+    valor: atrasadas.length,
+    extra: atrasadas.length
+      ? '<a class="selo selo-baixa text-decoration-none" href="ordens.html">ver ordens</a>'
+      : '<span class="selo selo-alta">tudo em dia</span>',
+  },
+].filter(Boolean);
+
+el('kpis').innerHTML = kpis
+  .map(
+    (k, i) => `
+    <div class="kpi" style="animation-delay:${i * 60}ms">
+      <span class="kpi-icone kpi-${k.cor}"><i class="bi ${k.icone}"></i></span>
+      <div class="kpi-rotulo">${k.rotulo}</div>
+      <div class="kpi-valor" data-kpi="${i}">${k.moeda ? formatarMoeda(0) : 0}</div>
+      <div class="kpi-extra">${k.extra}</div>
+    </div>`,
+  )
+  .join('');
+kpis.forEach((k, i) => contar(document.querySelector(`[data-kpi="${i}"]`), k.valor, k.moeda));
+
+// ---------- Faturamento por mês ----------
+if (gestor) {
+  const meses = Array.from({ length: 6 }, (_, i) => {
+    const de = new Date(agora.getFullYear(), agora.getMonth() - 5 + i, 1);
+    const ate = new Date(agora.getFullYear(), agora.getMonth() - 4 + i, 1);
+    const lista = vendidas.filter((o) => entre(o, de, ate));
+    return { rotulo: mesCurto.format(de).replace('.', ''), valor: soma(lista, (o) => o.valor_total), qtd: lista.length, atual: i === 5 };
+  });
+  const maior = Math.max(...meses.map((m) => m.valor), 1);
+  el('grafico-meses').innerHTML = meses
+    .map(
+      (m, i) => `
+      <div class="barra-col ${m.atual ? 'atual' : ''}" title="${formatarMoeda(m.valor)} · ${m.qtd} OS">
+        <span class="barra-valor">${m.valor ? formatarMoeda(m.valor).replace(',00', '') : '—'}</span>
+        <div class="barra-trilho"><div class="barra" style="--altura:${Math.max((m.valor / maior) * 100, m.valor ? 4 : 0)}%; animation-delay:${i * 70}ms"></div></div>
+        <span class="barra-rotulo">${m.rotulo}</span>
+      </div>`,
+    )
+    .join('');
+
+  // ---------- Rankings ----------
+  function ranking(alvo, linhas, vazio) {
+    const total = soma(linhas, (l) => l.valor) || 1;
+    const maiorValor = Math.max(...linhas.map((l) => l.valor), 1);
+    el(alvo).innerHTML = linhas.length
+      ? linhas
+          .slice(0, 5)
+          .map(
+            (l, i) => `
+          <div class="ranking-item" style="animation-delay:${i * 60}ms">
+            <div class="d-flex justify-content-between gap-2 small mb-1">
+              <span class="text-truncate"><span class="ranking-pos">${i + 1}</span>${esc(l.nome)}</span>
+              <span class="fw-semibold text-nowrap">${formatarMoeda(l.valor)} <span class="text-secondary fw-normal">${((l.valor / total) * 100).toFixed(0)}%</span></span>
+            </div>
+            <div class="ranking-trilho"><div class="ranking-barra" style="--largura:${(l.valor / maiorValor) * 100}%"></div></div>
+          </div>`,
+          )
+          .join('')
+      : `<p class="text-secondary small mb-0">${vazio}</p>`;
+  }
+
+  const porDentista = new Map();
+  doMes.forEach((o) => {
+    const nome = o.dentista?.nome ?? 'Sem dentista';
+    porDentista.set(nome, (porDentista.get(nome) ?? 0) + Number(o.valor_total));
+  });
+  ranking(
+    'ranking-dentistas',
+    [...porDentista].map(([nome, valor]) => ({ nome, valor })).sort((a, b) => b.valor - a.valor),
+    'Ainda não há vendas neste mês.',
+  );
+
+  const porCategoria = new Map();
+  doMes.forEach((o) =>
+    (o.itens ?? []).forEach((it) => {
+      const cat = it.servico?.categoria || 'Sem categoria';
+      porCategoria.set(cat, (porCategoria.get(cat) ?? 0) + Number(it.valor_total));
+    }),
+  );
+  ranking(
+    'ranking-categorias',
+    [...porCategoria].map(([nome, valor]) => ({ nome, valor })).sort((a, b) => b.valor - a.valor),
+    'Ainda não há vendas neste mês.',
+  );
+}
+
+// ---------- Próximas entregas ----------
+function textoPrazo(o) {
+  const dias = Math.floor((new Date(o.prazo_entrega).setHours(0, 0, 0, 0) - new Date().setHours(0, 0, 0, 0)) / DIA);
+  if (dias < 0) return { txt: `Atrasada ${-dias}d`, cls: 'prazo-atrasado' };
+  if (dias === 0) return { txt: 'Hoje', cls: 'prazo-hoje' };
+  if (dias === 1) return { txt: 'Amanhã', cls: 'prazo-breve' };
+  return { txt: dataCurta.format(new Date(o.prazo_entrega)), cls: '' };
+}
+
+const proximas = abertas.slice(0, 7);
+el('entregas').innerHTML = proximas.length
+  ? proximas
+      .map((o, i) => {
+        const p = textoPrazo(o);
+        return `
+        <li style="animation-delay:${i * 50}ms">
+          <a href="ordens.html">
+            <span class="entrega-num">#${o.numero}</span>
+            <span class="entrega-info"><strong>${esc(o.paciente)}</strong><small>${esc(o.dentista?.nome)} · ${STATUS[o.status].rotulo}</small></span>
+            <span class="entrega-prazo ${p.cls}">${p.txt}</span>
+          </a>
+        </li>`;
+      })
+      .join('')
+  : '<li class="text-secondary small">Nenhuma ordem em aberto.</li>';
+
+// ---------- Etapas ----------
+const totalAbertas = abertas.length || 1;
+el('etapas').innerHTML = abertas.length
+  ? `<div class="etapas-barra">${ABERTAS.map((s) => {
+      const n = abertas.filter((o) => o.status === s).length;
+      return n ? `<div class="bg-${STATUS[s].cor}" style="--largura:${(n / totalAbertas) * 100}%" title="${STATUS[s].rotulo}: ${n}"></div>` : '';
+    }).join('')}</div>
+    <div class="etapas-legenda">${ABERTAS.map((s) => {
+      const n = abertas.filter((o) => o.status === s).length;
+      return `<a href="ordens.html" class="etapa-item"><span class="ponto bg-${STATUS[s].cor}"></span>${STATUS[s].rotulo}<strong>${n}</strong></a>`;
+    }).join('')}</div>`
+  : '<p class="text-secondary small mb-0">Nenhuma ordem em aberto no momento.</p>';
diff --git a/js/paginas/ordens.js b/js/paginas/ordens.js
index 4558ba0..6dc23cd 100644
--- a/js/paginas/ordens.js
+++ b/js/paginas/ordens.js
@@ -179,20 +179,112 @@ function opcoesTecnico() {
 
 function opcoesServico(select, selecionado) {
   const ativos = servicos.filter((s) => s.ativo || s.id === selecionado);
-  const opcao = (s) => `<option value="${s.id}">${esc(s.nome)}</option>`;
-  const grupos = agruparPorCategoria(ativos);
-  // Uma categoria só (ou nenhuma): lista simples; várias: agrupa (ex.: barra de protocolo dentro de "Metal")
   select.innerHTML =
-    '<option value="">Selecione...</option>' +
-    (grupos.length < 2
-      ? ativos.map(opcao).join('')
-      : grupos.map(([cat, itens]) => `<optgroup label="${esc(cat)}">${itens.map(opcao).join('')}</optgroup>`).join(''));
+    '<option value="">Selecione...</option>' + ativos.map((s) => `<option value="${s.id}">${esc(s.nome)}</option>`).join('');
   if (selecionado) select.value = selecionado;
 }
 
+// ---------- Seletor de serviço em 2 passos: categoria → serviço ----------
+
+function servicosDisponiveis(linha) {
+  const atual = linha.querySelector('[data-campo="servico_id"]').value;
+  return servicos.filter((s) => s.ativo || s.id === atual);
+}
+
+function atualizarRotulo(linha) {
+  const botao = linha.querySelector('[data-rotulo]');
+  const servico = servicos.find((s) => s.id === linha.querySelector('[data-campo="servico_id"]').value);
+  botao.innerHTML = servico
+    ? `${servico.categoria ? `<span class="text-secondary">${esc(servico.categoria)} ›</span> ` : ''}${esc(servico.nome)}`
+    : '<span class="text-secondary">Escolher serviço...</span>';
+}
+
+/** Desenha o menu: sem categoria escolhida mostra as categorias; com categoria, os serviços dela. */
+function desenharMenu(linha, categoria = null) {
+  const menu = linha.querySelector('[data-menu]');
+  const grupos = agruparPorCategoria(servicosDisponiveis(linha));
+  const atual = linha.querySelector('[data-campo="servico_id"]').value;
+
+  if (!grupos.length) {
+    menu.innerHTML = '<div class="px-3 py-2 text-secondary small">Nenhum serviço ativo. Cadastre em Serviços.</div>';
+    return;
+  }
+  // Com uma categoria só, vai direto para os serviços
+  if (grupos.length === 1) categoria = grupos[0][0];
+
+  if (categoria === null) {
+    menu.innerHTML =
+      '<div class="dropdown-header">Categorias</div>' +
FIM_ARQUIVO_PW

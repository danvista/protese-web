cat >> /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
+  white-space: nowrap;
+}
+
+.barra-trilho {
+  flex: 1;
+  width: 100%;
+  max-width: 3.5rem;
+  display: flex;
+  align-items: flex-end;
+  border-radius: 0.6rem;
+  background: #f2f4f7;
+}
+
+.barra {
+  width: 100%;
+  height: var(--altura);
+  border-radius: 0.6rem;
+  background: linear-gradient(180deg, #c4b5fd, #818cf8);
+  animation: crescer 0.9s var(--ease) backwards;
+  transform-origin: bottom;
+}
+
+.barra-col.atual .barra {
+  background: var(--grad-primario);
+  box-shadow: 0 10px 20px -10px rgba(124, 58, 237, 0.8);
+}
+
+.barra-col.atual .barra-valor,
+.barra-col.atual .barra-rotulo {
+  color: var(--cor-primaria);
+  font-weight: 700;
+}
+
+.barra-rotulo {
+  font-size: 0.8rem;
+  color: #475467;
+  text-transform: capitalize;
+}
+
+@keyframes crescer {
+  from { transform: scaleY(0); }
+}
+
+/* Rankings */
+.ranking-item {
+  margin-bottom: 0.85rem;
+  animation: surgir 0.4s var(--ease) backwards;
+}
+
+.ranking-pos {
+  display: inline-grid;
+  place-items: center;
+  width: 1.3rem;
+  height: 1.3rem;
+  margin-right: 0.4rem;
+  border-radius: 50%;
+  background: var(--cor-primaria-suave);
+  color: var(--cor-primaria);
+  font-size: 0.7rem;
+  font-weight: 700;
+}
+
+.ranking-trilho {
+  height: 0.5rem;
+  border-radius: 999px;
+  background: #f2f4f7;
+  overflow: hidden;
+}
+
+.ranking-barra {
+  height: 100%;
+  width: var(--largura);
+  border-radius: 999px;
+  background: var(--grad-primario);
+  animation: encher 0.9s var(--ease) backwards;
+  transform-origin: left;
+}
+
+@keyframes encher {
+  from { transform: scaleX(0); }
+}
+
+/* Próximas entregas */
+.lista-entregas {
+  list-style: none;
+  padding: 0;
+  margin: 0;
+}
+
+.lista-entregas li {
+  animation: surgir 0.35s var(--ease) backwards;
+}
+
+.lista-entregas a {
+  display: flex;
+  align-items: center;
+  gap: 0.75rem;
+  padding: 0.55rem 0.6rem;
+  border-radius: 0.6rem;
+  color: inherit;
+  text-decoration: none;
+  transition: background-color 0.15s;
+}
+
+.lista-entregas a:hover {
+  background: #f5f6ff;
+}
+
+.entrega-num {
+  font-weight: 700;
+  color: #98a2b3;
+  font-size: 0.8rem;
+  min-width: 2.2rem;
+}
+
+.entrega-info {
+  display: flex;
+  flex-direction: column;
+  min-width: 0;
+  flex: 1;
+}
+
+.entrega-info strong,
+.entrega-info small {
+  white-space: nowrap;
+  overflow: hidden;
+  text-overflow: ellipsis;
+}
+
+.entrega-info small {
+  color: #667085;
+}
+
+.entrega-prazo {
+  font-size: 0.75rem;
+  font-weight: 600;
+  padding: 0.15rem 0.5rem;
+  border-radius: 999px;
+  background: #f2f4f7;
+  color: #475467;
+  white-space: nowrap;
+}
+
+.prazo-atrasado { background: #fee2e2; color: #b91c1c; }
+.prazo-hoje { background: #fef3c7; color: #92400e; }
+.prazo-breve { background: #e0f2fe; color: #0369a1; }
+
+/* Etapas */
+.etapas-barra {
+  display: flex;
+  height: 0.8rem;
+  border-radius: 999px;
+  overflow: hidden;
+  gap: 3px;
+  margin-bottom: 1rem;
+}
+
+.etapas-barra > div {
+  width: var(--largura);
+  animation: encher 0.8s var(--ease) backwards;
+  transform-origin: left;
+}
+
+.etapas-legenda {
+  display: flex;
+  flex-wrap: wrap;
+  gap: 0.5rem 1.25rem;
+}
+
+.etapa-item {
+  display: inline-flex;
+  align-items: center;
+  gap: 0.4rem;
+  color: #475467;
+  text-decoration: none;
+  font-size: 0.9rem;
+}
+
+.etapa-item strong {
+  color: #101828;
+}
+
+.etapa-item .ponto {
+  width: 0.65rem;
+  height: 0.65rem;
+  border-radius: 50%;
+}
+
+@media (max-width: 576px) {
+  .painel-hero { padding: 1.4rem; }
+  .grafico-barras { gap: 0.4rem; height: 12rem; }
+  .barra-valor { font-size: 0.62rem; }
+  .grade-kpi { grid-template-columns: repeat(2, 1fr); gap: 0.6rem; }
+  .kpi { padding: 0.9rem; }
+  .kpi-valor { font-size: 1.2rem; }
+  .kpi-icone { width: 2rem; height: 2rem; font-size: 0.95rem; }
+  .kpi .selo-txt { display: none; }
+}
diff --git a/inicio.html b/inicio.html
index fabd765..285a964 100644
--- a/inicio.html
+++ b/inicio.html
@@ -8,16 +8,95 @@
   <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
   <link rel="stylesheet" href="css/estilo.css">
 </head>
-<body class="carregando">
+<body class="carregando pagina-painel">
   <header id="topo"></header>
   <div class="aviso-wrapper"><div id="aviso-assinatura" hidden role="status"></div></div>
 
   <main class="conteudo">
-    <h1 class="h3 mb-3">Olá, <span id="nome-usuario"></span>!</h1>
-    <div class="card">
-      <div class="card-body">
-        Sua conta está pronta. Nas próximas etapas, aqui vai aparecer o painel do dia: ordens que entram,
-        que saem e que estão atrasadas.
+    <!-- Destaque do mês -->
+    <section class="painel-hero mb-4">
+      <div class="hero-bolhas" aria-hidden="true"><span></span><span></span><span></span></div>
+      <div class="row g-4 align-items-center position-relative">
+        <div class="col-lg-7">
+          <p class="hero-saudacao mb-1" id="saudacao"></p>
+          <h1 class="hero-titulo mb-2" id="hero-titulo">Carregando o painel...</h1>
+          <p class="hero-sub mb-0" id="hero-sub"></p>
+        </div>
+        <div class="col-lg-5 so-gestor">
+          <div class="hero-valor">
+            <span class="hero-rotulo" id="hero-rotulo-mes">Faturamento do mês</span>
+            <strong id="hero-faturamento" data-contador="0" data-moeda>R$ 0,00</strong>
+            <span class="hero-tendencia" id="hero-tendencia"></span>
+          </div>
+        </div>
+        <div class="col-lg-5 so-tecnico">
+          <div class="hero-valor">
+            <span class="hero-rotulo">Ordens em aberto</span>
+            <strong id="hero-abertas" data-contador="0">0</strong>
+            <span class="hero-tendencia" id="hero-atrasadas-txt"></span>
+          </div>
+        </div>
+      </div>
+    </section>
+
+    <!-- Indicadores -->
+    <section class="grade-kpi mb-4" id="kpis"></section>
+
+    <div class="row g-4">
+      <!-- Faturamento por mês -->
+      <div class="col-xl-8 so-gestor">
+        <div class="card h-100 cartao-painel">
+          <div class="card-body">
+            <div class="d-flex align-items-center mb-3">
+              <h2 class="h6 mb-0 me-auto"><i class="bi bi-bar-chart-line text-primary"></i> Faturamento por mês</h2>
+              <span class="small text-secondary">últimos 6 meses</span>
+            </div>
+            <div class="grafico-barras" id="grafico-meses" role="img" aria-label="Faturamento dos últimos 6 meses"></div>
+          </div>
+        </div>
+      </div>
+
+      <!-- Entregas próximas -->
+      <div class="col-xl-4">
+        <div class="card h-100 cartao-painel">
+          <div class="card-body">
+            <div class="d-flex align-items-center mb-3">
+              <h2 class="h6 mb-0 me-auto"><i class="bi bi-calendar-check text-primary"></i> Próximas entregas</h2>
+              <a href="ordens.html" class="small">Ver todas</a>
+            </div>
+            <ul class="lista-entregas" id="entregas"></ul>
+          </div>
+        </div>
+      </div>
+
+      <!-- Ranking de dentistas -->
+      <div class="col-lg-6 so-gestor">
+        <div class="card h-100 cartao-painel">
+          <div class="card-body">
+            <h2 class="h6 mb-3"><i class="bi bi-trophy text-primary"></i> Dentistas que mais compraram no mês</h2>
+            <div id="ranking-dentistas" class="ranking"></div>
+          </div>
+        </div>
+      </div>
+
+      <!-- Por categoria -->
+      <div class="col-lg-6 so-gestor">
+        <div class="card h-100 cartao-painel">
+          <div class="card-body">
+            <h2 class="h6 mb-3"><i class="bi bi-pie-chart text-primary"></i> Vendas por categoria no mês</h2>
+            <div id="ranking-categorias" class="ranking"></div>
+          </div>
+        </div>
+      </div>
+
+      <!-- Etapas (técnico vê no lugar dos valores) -->
+      <div class="col-12">
+        <div class="card cartao-painel">
+          <div class="card-body">
+            <h2 class="h6 mb-3"><i class="bi bi-kanban text-primary"></i> Ordens em aberto por etapa</h2>
+            <div class="etapas" id="etapas"></div>
+          </div>
+        </div>
       </div>
     </div>
   </main>
diff --git a/js/dados.js b/js/dados.js
index c7d0212..77c57a4 100644
--- a/js/dados.js
FIM_ARQUIVO_PW

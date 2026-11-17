cat > /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
diff --git a/css/estilo.css b/css/estilo.css
index 814c083..f10ac54 100644
--- a/css/estilo.css
+++ b/css/estilo.css
@@ -118,11 +118,11 @@ body.carregando {
 
 .conteudo,
 .auth-card {
-  animation: surgir 0.45s var(--ease) both;
+  animation: surgir 0.45s var(--ease) backwards;
 }
 
 .table tbody tr {
-  animation: surgir 0.35s var(--ease) both;
+  animation: surgir 0.35s var(--ease) backwards;
 }
 
 .modal.fade .modal-dialog {
@@ -141,7 +141,7 @@ body.carregando {
 }
 
 .toast {
-  animation: surgir 0.3s var(--ease) both;
+  animation: surgir 0.3s var(--ease) backwards;
   border-radius: 0.75rem;
 }
 
@@ -251,7 +251,7 @@ body.carregando {
   text-align: center;
   color: #667085;
   padding: 3rem 1rem;
-  animation: surgir 0.4s var(--ease) both;
+  animation: surgir 0.4s var(--ease) backwards;
 }
 
 .estado-vazio .bi {
@@ -329,7 +329,7 @@ body.carregando {
   border-radius: var(--raio);
   padding: 0.9rem 1rem;
   box-shadow: var(--sombra-1);
-  animation: surgirEscala 0.4s var(--ease) both;
+  animation: surgirEscala 0.4s var(--ease) backwards;
   transition: transform 0.25s var(--ease), box-shadow 0.25s var(--ease);
 }
 
@@ -396,7 +396,7 @@ body.carregando {
 }
 
 .tabela-itens .item-novo {
-  animation: surgir 0.3s var(--ease) both;
+  animation: surgir 0.3s var(--ease) backwards;
 }
 
 .tabela-itens .item-saindo {
@@ -418,7 +418,7 @@ body.carregando {
 .linha-tempo li {
   position: relative;
   padding: 0 0 0.9rem 1.4rem;
-  animation: surgir 0.35s var(--ease) both;
+  animation: surgir 0.35s var(--ease) backwards;
 }
 
 .linha-tempo li::before {
@@ -468,3 +468,473 @@ body.carregando {
   font-size: 0.7rem;
   text-align: center;
 }
+
+/* Seletor de serviço da OS (categoria → serviço) */
+.seletor-servico > [data-rotulo] {
+  min-width: 12rem;
+  overflow: hidden;
+  white-space: nowrap;
+  text-overflow: ellipsis;
+}
+
+.seletor-menu {
+  min-width: 18rem;
+  max-height: 20rem;
+  overflow-y: auto;
+  border: 0;
+  border-radius: 0.75rem;
+  padding: 0.35rem;
+}
+
+.seletor-menu .dropdown-item {
+  border-radius: 0.5rem;
+  padding: 0.45rem 0.7rem;
+  transition: background-color 0.15s;
+}
+
+.seletor-menu .dropdown-item.active,
+.seletor-menu .dropdown-item:active {
+  background: var(--cor-primaria);
+}
+
+.seletor-menu.menu-trocando > * {
+  animation: surgir 0.22s var(--ease) backwards;
+}
+
+.was-validated .seletor-servico:has(select:invalid) > [data-rotulo] {
+  border-color: var(--bs-form-invalid-border-color, #dc3545);
+}
+
+/* =========================================================
+   Gradientes (tema geral)
+   ========================================================= */
+:root {
+  --grad-primario: linear-gradient(135deg, #4f46e5 0%, #7c3aed 55%, #c026d3 100%);
+  --grad-hero: linear-gradient(120deg, #312e81 0%, #4f46e5 35%, #7c3aed 70%, #db2777 100%);
+}
+
+body {
+  background:
+    radial-gradient(70rem 40rem at 100% -10%, rgba(124, 58, 237, 0.10), transparent 60%),
+    radial-gradient(60rem 35rem at -10% 10%, rgba(14, 165, 233, 0.08), transparent 60%),
+    var(--cor-fundo);
+  background-attachment: fixed;
+}
+
+.btn-primary {
+  background-image: var(--grad-primario);
+  border: 0;
+  background-size: 150% 150%;
+  background-position: 0% 50%;
+  transition: background-position 0.4s var(--ease), transform 0.15s var(--ease), box-shadow 0.2s;
+}
+
+.btn-primary:hover {
+  background-position: 100% 50%;
+  box-shadow: 0 8px 20px -8px rgba(124, 58, 237, 0.7);
+}
+
+#topo .navbar-brand {
+  background: var(--grad-primario);
+  -webkit-background-clip: text;
+  background-clip: text;
+  color: transparent !important;
+}
+
+#topo .navbar-brand .bi {
+  -webkit-text-fill-color: #7c3aed;
+}
+
+#topo .nav-link.active {
+  background: linear-gradient(135deg, rgba(79, 70, 229, 0.12), rgba(192, 38, 211, 0.12));
+}
+
+.chip.ativo {
+  background: var(--grad-primario);
+  border-color: transparent;
+}
+
+/* =========================================================
+   Painel inicial
+   ========================================================= */
+body:not(.modo-tecnico) .so-tecnico {
+  display: none !important;
+}
+
+.painel-hero {
+  position: relative;
+  overflow: hidden;
+  border-radius: 1.25rem;
+  padding: 2rem;
+  color: #fff;
+  background: var(--grad-hero);
+  background-size: 200% 200%;
+  animation: surgir 0.5s var(--ease) backwards, deslizarGradiente 14s ease-in-out infinite alternate;
+  box-shadow: 0 24px 50px -24px rgba(79, 70, 229, 0.75);
+}
+
+@keyframes deslizarGradiente {
+  from { background-position: 0% 50%; }
+  to { background-position: 100% 50%; }
+}
+
+.hero-bolhas span {
+  position: absolute;
+  border-radius: 50%;
+  filter: blur(40px);
+  opacity: 0.45;
+  animation: flutuar 10s ease-in-out infinite alternate;
+}
+
+.hero-bolhas span:nth-child(1) { width: 16rem; height: 16rem; background: #22d3ee; top: -6rem; right: 10%; }
+.hero-bolhas span:nth-child(2) { width: 12rem; height: 12rem; background: #f472b6; bottom: -5rem; left: 30%; animation-delay: -3s; }
+.hero-bolhas span:nth-child(3) { width: 9rem; height: 9rem; background: #a78bfa; top: 20%; left: -3rem; animation-delay: -6s; }
+
+@keyframes flutuar {
+  from { transform: translate(0, 0) scale(1); }
+  to { transform: translate(2rem, 1rem) scale(1.15); }
+}
+
+.hero-saudacao {
+  opacity: 0.85;
+  font-weight: 500;
+}
+
+.hero-titulo {
+  font-size: clamp(1.4rem, 2.6vw, 2rem);
+  font-weight: 700;
+  color: #fff;
+  letter-spacing: -0.02em;
+}
+
+.hero-sub {
+  opacity: 0.85;
+}
+
+.hero-valor {
+  display: flex;
+  flex-direction: column;
+  gap: 0.35rem;
+  padding: 1.25rem 1.5rem;
+  border-radius: 1rem;
+  background: rgba(255, 255, 255, 0.12);
+  border: 1px solid rgba(255, 255, 255, 0.25);
+  backdrop-filter: blur(8px);
+}
+
+.hero-rotulo {
+  font-size: 0.85rem;
+  opacity: 0.85;
+}
+
+.hero-valor strong {
+  font-size: clamp(1.8rem, 3.5vw, 2.6rem);
+  line-height: 1.1;
+  font-variant-numeric: tabular-nums;
+}
+
+.painel-hero .selo {
+  background: rgba(255, 255, 255, 0.18);
+  color: #fff;
+}
+
+.selo {
+  display: inline-flex;
+  align-items: center;
+  gap: 0.25rem;
+  padding: 0.15rem 0.55rem;
+  border-radius: 999px;
+  font-size: 0.75rem;
+  font-weight: 600;
+}
+
+.selo-txt {
+  font-weight: 400;
+  opacity: 0.85;
+}
+
+.selo-alta { background: #dcfce7; color: #15803d; }
+.selo-baixa { background: #fee2e2; color: #b91c1c; }
+.selo-neutro { background: #f2f4f7; color: #475467; }
+
+/* Indicadores */
+.grade-kpi {
+  display: grid;
+  grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr));
+  gap: 1rem;
+}
+
+.kpi {
+  position: relative;
+  padding: 1.1rem 1.2rem;
+  border-radius: 1rem;
+  background: rgba(255, 255, 255, 0.85);
+  border: 1px solid rgba(16, 24, 40, 0.06);
+  box-shadow: var(--sombra-1);
+  backdrop-filter: blur(6px);
+  animation: surgirEscala 0.45s var(--ease) backwards;
+  transition: transform 0.25s var(--ease), box-shadow 0.25s;
+}
+
+.kpi:hover {
+  transform: translateY(-3px);
+  box-shadow: var(--sombra-2);
+}
+
+.kpi-icone {
+  display: inline-grid;
+  place-items: center;
+  width: 2.4rem;
+  height: 2.4rem;
+  border-radius: 0.75rem;
+  color: #fff;
+  font-size: 1.1rem;
+  margin-bottom: 0.6rem;
+}
+
+.kpi-roxo { background: linear-gradient(135deg, #6366f1, #a855f7); }
+.kpi-azul { background: linear-gradient(135deg, #3b82f6, #06b6d4); }
+.kpi-verde { background: linear-gradient(135deg, #10b981, #84cc16); }
+.kpi-ciano { background: linear-gradient(135deg, #06b6d4, #3b82f6); }
+.kpi-laranja { background: linear-gradient(135deg, #f59e0b, #f97316); }
+.kpi-vermelho { background: linear-gradient(135deg, #ef4444, #db2777); }
+
+.kpi-rotulo {
+  font-size: 0.82rem;
+  color: #667085;
+}
+
+.kpi-valor {
+  font-size: 1.55rem;
+  font-weight: 700;
+  letter-spacing: -0.02em;
+  font-variant-numeric: tabular-nums;
+}
+
+.kpi-extra {
+  margin-top: 0.3rem;
+}
+
+.cartao-painel {
+  border-radius: 1rem;
+  animation: surgir 0.5s var(--ease) backwards;
+}
+
+/* Gráfico de barras */
+.grafico-barras {
+  display: grid;
+  grid-template-columns: repeat(6, 1fr);
+  gap: 0.75rem;
+  height: 15rem;
+  align-items: end;
+}
+
+.barra-col {
+  display: flex;
+  flex-direction: column;
+  align-items: center;
+  height: 100%;
+  gap: 0.35rem;
+}
+
+.barra-valor {
+  font-size: 0.72rem;
+  color: #667085;
FIM_ARQUIVO_PW

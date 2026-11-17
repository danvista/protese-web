cat >> /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
+++ b/js/paginas/ordens.js
@@ -388,6 +388,7 @@ async function abrirOrdem(id = null) {
       el('titulo-os').textContent = 'Nova ordem de serviço';
       el('status-atual').innerHTML = '';
       el('painel-etapa').hidden = true;
+      el('btn-nota').hidden = true;
       opcoesDentista();
       adicionarItem();
       definirEdicao(true);
@@ -396,6 +397,8 @@ async function abrirOrdem(id = null) {
 
     ordemAtual = await obterOrdem(id);
     el('titulo-os').textContent = `OS #${ordemAtual.numero}`;
+    el('btn-nota').href = `nota.html?id=${encodeURIComponent(ordemAtual.id)}`;
+    el('btn-nota').hidden = false;
     el('status-atual').innerHTML = badgeStatus(ordemAtual.status);
     opcoesDentista(ordemAtual.dentista_id);
     form.elements.dentista_id.value = ordemAtual.dentista_id;
diff --git a/nota.html b/nota.html
new file mode 100644
index 0000000..203080b
--- /dev/null
+++ b/nota.html
@@ -0,0 +1,28 @@
+<!doctype html>
+<html lang="pt-BR">
+<head>
+  <meta charset="utf-8">
+  <meta name="viewport" content="width=device-width, initial-scale=1">
+  <title>Nota da OS | Protese Web</title>
+  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css">
+  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
+  <link rel="stylesheet" href="css/estilo.css">
+</head>
+<body class="carregando pagina-nota">
+  <!-- Barra de ações (não sai na impressão) -->
+  <div class="nota-acoes nao-imprimir">
+    <a href="ordens.html" class="btn btn-outline-secondary btn-sm"><i class="bi bi-arrow-left"></i> Voltar</a>
+    <div class="form-check form-switch mb-0 so-gestor">
+      <input class="form-check-input" type="checkbox" role="switch" id="mostrar-valores" checked>
+      <label class="form-check-label small" for="mostrar-valores">Mostrar valores</label>
+    </div>
+    <button type="button" class="btn btn-primary btn-sm" id="btn-imprimir"><i class="bi bi-printer"></i> Imprimir / salvar PDF</button>
+  </div>
+
+  <article class="nota" id="nota">
+    <div class="text-center text-secondary py-5" id="nota-carregando">Carregando...</div>
+  </article>
+
+  <script type="module" src="js/paginas/nota.js"></script>
+</body>
+</html>
diff --git a/ordens.html b/ordens.html
index 5e5ac50..4b5eb0b 100644
--- a/ordens.html
+++ b/ordens.html
@@ -150,6 +150,7 @@
         </div>
 
         <div class="modal-footer">
+          <a class="btn btn-outline-primary me-auto" id="btn-nota" target="_blank" hidden><i class="bi bi-printer"></i> Imprimir nota</a>
           <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Fechar</button>
           <button type="submit" class="btn btn-primary btn-animado" id="btn-salvar">Salvar</button>
         </div>
FIM_ARQUIVO_PW

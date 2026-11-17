cat >> /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
+      grupos
+        .map(
+          ([cat, itens]) => `
+          <button type="button" class="dropdown-item d-flex align-items-center gap-2" data-categoria="${esc(cat)}">
+            <i class="bi bi-folder2"></i><span class="me-auto">${esc(cat)}</span>
+            <span class="badge rounded-pill text-bg-light">${itens.length}</span><i class="bi bi-chevron-right small"></i>
+          </button>`,
+        )
+        .join('');
+  } else {
+    const itens = grupos.find(([cat]) => cat === categoria)?.[1] ?? [];
+    menu.innerHTML =
+      (grupos.length > 1
+        ? `<button type="button" class="dropdown-item text-primary small" data-voltar><i class="bi bi-chevron-left"></i> Categorias</button>
+           <div class="dropdown-divider my-1"></div>`
+        : '') +
+      `<div class="dropdown-header">${esc(categoria)}</div>` +
+      itens
+        .map(
+          (s) => `
+          <button type="button" class="dropdown-item d-flex justify-content-between gap-3 ${s.id === atual ? 'active' : ''}" data-servico="${s.id}">
+            <span>${esc(s.nome)}</span>
+            ${gestor ? `<span class="small ${s.id === atual ? '' : 'text-secondary'}">${formatarMoeda(precoDoServico(s.id))}</span>` : ''}
+          </button>`,
+        )
+        .join('');
+  }
+  menu.classList.remove('menu-trocando');
+  void menu.offsetWidth; // reinicia a animação
+  menu.classList.add('menu-trocando');
+}
+
+// Esc fecha só o menu de serviços, não a janela da OS inteira
+corpoItens.addEventListener('keydown', (e) => {
+  if (e.key !== 'Escape') return;
+  const aberto = e.target.closest('.linha-item')?.querySelector('[data-menu].show') ?? corpoItens.querySelector('[data-menu].show');
+  if (!aberto) return;
+  e.stopPropagation();
+  const botao = aberto.closest('.seletor-servico').querySelector('[data-rotulo]');
+  window.bootstrap.Dropdown.getOrCreateInstance(botao).hide();
+  botao.focus();
+});
+
+corpoItens.addEventListener('show.bs.dropdown', (e) => desenharMenu(e.target.closest('.linha-item')));
+
+corpoItens.addEventListener('click', (e) => {
+  const linha = e.target.closest('.linha-item');
+  if (!linha) return;
+  const cat = e.target.closest('[data-categoria]');
+  if (cat) return desenharMenu(linha, cat.dataset.categoria);
+  if (e.target.closest('[data-voltar]')) return desenharMenu(linha);
+  const opcao = e.target.closest('[data-servico]');
+  if (opcao) {
+    const select = linha.querySelector('[data-campo="servico_id"]');
+    select.value = opcao.dataset.servico;
+    select.dispatchEvent(new Event('change', { bubbles: true }));
+    atualizarRotulo(linha);
+    window.bootstrap.Dropdown.getOrCreateInstance(linha.querySelector('[data-rotulo]')).hide();
+    linha.querySelector('[data-campo="dentes"]').focus();
+  }
+});
+
 function adicionarItem(item = null) {
   const linha = modeloItem.content.firstElementChild.cloneNode(true);
   opcoesServico(linha.querySelector('[data-campo="servico_id"]'), item?.servico_id);
+  atualizarRotulo(linha);
+  // Menu "flutuante" (fixed) para não ser cortado pela tabela/rolagem do modal
+  new window.bootstrap.Dropdown(linha.querySelector('[data-rotulo]'), {
+    popperConfig: (padrao) => ({ ...padrao, strategy: 'fixed' }),
+  });
   linha.querySelector('[data-campo="dentes"]').value = item?.dentes ?? '';
   linha.querySelector('[data-campo="quantidade"]').value = item?.quantidade ?? 1;
   // Item já salvo mantém o preço com que foi lançado
@@ -261,7 +353,12 @@ corpoItens.addEventListener('click', (e) => {
   linha.classList.add('item-saindo');
   linha.addEventListener('animationend', () => { linha.remove(); atualizarTotais(); }, { once: true });
 });
-el('btn-add-item').addEventListener('click', () => adicionarItem().querySelector('select').focus());
+el('btn-add-item').addEventListener('click', () => {
+  // Já abre a lista de categorias da linha nova
+  // (depois do clique terminar, senão o Bootstrap fecha o menu na hora)
+  const botao = adicionarItem().querySelector('[data-rotulo]');
+  setTimeout(() => window.bootstrap.Dropdown.getOrCreateInstance(botao).show(), 0);
+});
 form.elements.prazo.addEventListener('input', () => (prazoTocado = true));
 form.elements.desconto.addEventListener('input', atualizarTotais);
 
diff --git a/ordens.html b/ordens.html
index bd5a8d1..5e5ac50 100644
--- a/ordens.html
+++ b/ordens.html
@@ -160,7 +160,13 @@
   <template id="modelo-item">
     <tr class="linha-item">
       <td>
-        <select class="form-select form-select-sm" data-campo="servico_id" required aria-label="Serviço"></select>
+        <div class="dropdown seletor-servico">
+          <button type="button" class="form-select form-select-sm text-start" data-bs-toggle="dropdown"
+                  data-bs-auto-close="outside" aria-expanded="false"
+                  data-rotulo aria-label="Escolher serviço">Escolher serviço...</button>
+          <div class="dropdown-menu seletor-menu shadow" data-menu></div>
+          <select data-campo="servico_id" required hidden aria-hidden="true" tabindex="-1"></select>
+        </div>
       </td>
       <td><input type="text" class="form-control form-control-sm" data-campo="dentes" placeholder="11, 21" maxlength="60" aria-label="Dentes"></td>
       <td><input type="number" class="form-control form-control-sm" data-campo="quantidade" min="1" max="99" value="1" required aria-label="Quantidade"></td>
FIM_ARQUIVO_PW

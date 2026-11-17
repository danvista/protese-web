cat >> /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
+  border-bottom: 1px solid #eaecf0;
+  vertical-align: top;
+}
+
+.nota-tabela td small {
+  display: block;
+  color: #98a2b3;
+  font-size: 0.72rem;
+}
+
+.nota-totais {
+  margin: 0.8rem 0 0 auto;
+  width: 16rem;
+}
+
+.nota-totais > div {
+  display: flex;
+  justify-content: space-between;
+  padding: 0.2rem 0;
+}
+
+.nota-total {
+  margin-top: 0.3rem;
+  padding: 0.55rem 0.75rem !important;
+  border-radius: 0.5rem;
+  background: var(--grad-primario);
+  color: #fff;
+  font-weight: 700;
+  font-size: 1.05rem;
+}
+
+.nota-obs {
+  margin-top: 1rem;
+  padding: 0.6rem 0.75rem;
+  border: 1px dashed #d0d5dd;
+  border-radius: 0.5rem;
+}
+
+.nota-obs p {
+  margin: 0;
+  white-space: pre-wrap;
+}
+
+.nota-assinaturas {
+  display: grid;
+  grid-template-columns: 1fr 1fr;
+  gap: 3rem;
+  margin-top: auto;
+  padding-top: 3rem;
+  text-align: center;
+  font-size: 0.8rem;
+  color: #475467;
+}
+
+.nota-assinaturas span {
+  display: block;
+  border-top: 1px solid #98a2b3;
+  margin-bottom: 0.3rem;
+}
+
+.nota-rodape {
+  margin-top: 1rem;
+  text-align: center;
+  font-size: 0.7rem;
+  color: #98a2b3;
+}
+
+.nota.sem-valores .col-valor {
+  display: none !important;
+}
+
+@media (max-width: 768px) {
+  .nota { padding: 1rem; min-height: 0; margin: 0.75rem; }
+  .nota-blocos { grid-template-columns: 1fr 1fr; }
+  .nota-cabecalho { flex-direction: column; }
+  .nota-numero { text-align: left; }
+}
+
+@media print {
+  @page { size: A4; margin: 10mm; }
+  body, .pagina-nota { background: #fff !important; }
+  .nao-imprimir { display: none !important; }
+  .nota { margin: 0; padding: 0; box-shadow: none; border-radius: 0; max-width: none; min-height: 275mm; }
+  .nota-total, .nota-tabela th { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
+  .nota-cabecalho { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
+}
diff --git a/js/auth.js b/js/auth.js
index c3448fb..2713cfc 100644
--- a/js/auth.js
+++ b/js/auth.js
@@ -32,7 +32,7 @@ export async function exigirVisitante() {
 export async function carregarPerfil(usuarioId) {
   const [usuario, laboratorio] = await Promise.all([
     supabase.from('usuarios').select('id, nome, email, papel').eq('id', usuarioId).single(),
-    supabase.from('laboratorios').select('id, nome, status_assinatura, teste_ate').single(),
+    supabase.from('laboratorios').select('id, nome, logo_url, status_assinatura, teste_ate').single(),
   ]);
   return { perfil: usuario.data, laboratorio: laboratorio.data };
 }
diff --git a/js/dados.js b/js/dados.js
index 77c57a4..e32016f 100644
--- a/js/dados.js
+++ b/js/dados.js
@@ -59,6 +59,59 @@ export async function salvarDentista(dados, id = null) {
   if (error) throw erroAmigavel(error);
 }
 
+// ---------------- Laboratório ----------------
+
+const CAMPOS_LAB = 'id, nome, documento, email, telefone, endereco, cidade, logo_url';
+
+export async function obterLaboratorio() {
+  const { data, error } = await supabase.from('laboratorios').select(CAMPOS_LAB).single();
+  if (error) throw erroAmigavel(error);
+  return data;
+}
+
+/** Só o DONO consegue gravar (RLS). */
+export async function salvarLaboratorio(id, dados) {
+  const { data, error } = await supabase.from('laboratorios').update(dados).eq('id', id).select('id');
+  if (error) throw erroAmigavel(error);
+  if (!data?.length) throw new Error('Só o dono do laboratório pode alterar estes dados.');
+}
+
+const TIPOS_LOGO = ['image/png', 'image/jpeg', 'image/webp'];
+
+/** Envia a logo para o Storage (pasta do laboratório) e grava o endereço público. */
+export async function enviarLogo(laboratorioId, arquivo) {
+  if (!TIPOS_LOGO.includes(arquivo.type)) throw new Error('Use uma imagem PNG, JPG ou WEBP.');
+  if (arquivo.size > 1024 * 1024) throw new Error('A imagem deve ter no máximo 1 MB.');
+  const caminho = `${laboratorioId}/logo`;
+  const { error } = await supabase.storage
+    .from('logos')
+    .upload(caminho, arquivo, { upsert: true, contentType: arquivo.type, cacheControl: '60' });
+  if (error) throw new Error('Não foi possível enviar a logo. Tente novamente.');
+  const { data } = supabase.storage.from('logos').getPublicUrl(caminho);
+  const url = `${data.publicUrl}?v=${Date.now()}`; // força o navegador a buscar a imagem nova
+  await salvarLaboratorio(laboratorioId, { logo_url: url });
+  return url;
+}
+
+export async function removerLogo(laboratorioId) {
+  await supabase.storage.from('logos').remove([`${laboratorioId}/logo`]);
+  await salvarLaboratorio(laboratorioId, { logo_url: null });
+}
+
+/** OS completa para a nota impressa. */
+export async function obterNotaOrdem(id) {
+  const { data, error } = await supabase
+    .from('ordens_servico')
+    .select(`id, numero, paciente, cor, observacoes, status, data_entrada, prazo_entrega, data_entrega, desconto, valor_total,
+      dentista:dentistas(nome, clinica, cro, telefone),
+      tecnico:usuarios(nome),
+      itens:itens_ordem_servico(id, dentes, quantidade, valor_unitario, valor_total, servico:servicos(nome, categoria))`)
+    .eq('id', id)
+    .single();
+  if (error) throw erroAmigavel(error);
+  return data;
+}
+
 // ---------------- Equipe ----------------
 
 export async function listarUsuarios() {
diff --git a/js/layout.js b/js/layout.js
index 95e269f..9a62974 100644
--- a/js/layout.js
+++ b/js/layout.js
@@ -11,6 +11,7 @@ const MENU = [
   { id: 'ordens', rotulo: 'Ordens de serviço', icone: 'bi-clipboard2-pulse', pagina: 'ordens.html' },
   { id: 'dentistas', rotulo: 'Dentistas', icone: 'bi-person-vcard', pagina: 'dentistas.html' },
   { id: 'servicos', rotulo: 'Serviços', icone: 'bi-tools', pagina: 'servicos.html' },
+  { id: 'configuracoes', rotulo: 'Configurações', icone: 'bi-gear', pagina: 'configuracoes.html', soGestor: true },
 ];
 
 /**
@@ -35,7 +36,7 @@ function montarTopo(perfil, laboratorio, paginaAtiva) {
     <nav class="navbar navbar-expand-md bg-white border-bottom">
       <div class="container-fluid">
         <a class="navbar-brand fw-bold" href="inicio.html">
-          <i class="bi bi-box-seam text-primary"></i> <span data-nome-lab></span>
+          <img data-logo-lab alt="" hidden> <i class="bi bi-box-seam text-primary" data-icone-lab></i> <span data-nome-lab></span>
         </a>
         <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#menuPrincipal"
                 aria-controls="menuPrincipal" aria-expanded="false" aria-label="Abrir menu">
@@ -43,7 +44,7 @@ function montarTopo(perfil, laboratorio, paginaAtiva) {
         </button>
         <div class="collapse navbar-collapse" id="menuPrincipal">
           <ul class="navbar-nav me-auto">
-            ${MENU.map(
+            ${MENU.filter((item) => !item.soGestor || ehGestor(perfil)).map(
               (item) => `
               <li class="nav-item">
                 <a class="nav-link ${item.id === paginaAtiva ? 'active fw-semibold' : ''}" href="${item.pagina}"
@@ -65,6 +66,12 @@ function montarTopo(perfil, laboratorio, paginaAtiva) {
 
   // textContent: dados do usuário nunca entram como HTML
   topo.querySelector('[data-nome-lab]').textContent = laboratorio?.nome ?? NOME_SISTEMA;
+  if (laboratorio?.logo_url) {
+    const logo = topo.querySelector('[data-logo-lab]');
+    logo.src = laboratorio.logo_url;
+    logo.hidden = false;
+    topo.querySelector('[data-icone-lab]').hidden = true;
+  }
   topo.querySelector('[data-nome-usuario]').textContent = perfil?.nome ?? '';
   topo.querySelector('[data-sair]').addEventListener('click', sair);
 }
diff --git a/js/paginas/configuracoes.js b/js/paginas/configuracoes.js
new file mode 100644
index 0000000..2d4de1a
--- /dev/null
+++ b/js/paginas/configuracoes.js
@@ -0,0 +1,97 @@
+import { iniciarAreaLogada, somenteLeitura } from '../layout.js';
+import { obterLaboratorio, salvarLaboratorio, enviarLogo, removerLogo } from '../dados.js';
+import { formatarTelefone } from '../formatos.js';
+import { ligarFormulario, preencherFormulario, mostrarToast, mostrarAlerta, esconderAlerta, carregandoBotao } from '../ui.js';
+
+const { perfil, laboratorio: labSessao } = await iniciarAreaLogada('configuracoes');
+const el = (id) => document.getElementById(id);
+const form = el('form-lab');
FIM_ARQUIVO_PW

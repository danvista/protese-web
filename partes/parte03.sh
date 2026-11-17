cat >> /tmp/mudancas.patch <<'FIM_ARQUIVO_PW'
+const ehDono = perfil?.papel === 'DONO' && !somenteLeitura(labSessao);
+
+let lab = null;
+
+function mostrarLogo(url) {
+  const img = el('logo-img');
+  img.hidden = !url;
+  el('logo-vazio').hidden = !!url;
+  el('btn-remover-logo').hidden = !url;
+  if (url) img.src = url;
+  // Atualiza também a logo do topo, sem recarregar a página
+  const topo = document.querySelector('[data-logo-lab]');
+  if (topo) {
+    topo.hidden = !url;
+    if (url) topo.src = url;
+    document.querySelector('[data-icone-lab]').hidden = !!url;
+  }
+}
+
+try {
+  lab = await obterLaboratorio();
+  preencherFormulario(form, lab);
+  mostrarLogo(lab.logo_url);
+} catch (erro) {
+  mostrarAlerta(el('alerta-lab'), 'danger', erro.message);
+}
+
+if (!ehDono) {
+  el('aviso-somente-dono').hidden = false;
+  form.querySelectorAll('input').forEach((c) => (c.disabled = true));
+  document.querySelectorAll('.so-dono').forEach((c) => (c.hidden = true));
+}
+
+form.elements.telefone.addEventListener('blur', (e) => {
+  if (e.target.value) e.target.value = formatarTelefone(e.target.value);
+});
+
+ligarFormulario(form, {
+  alerta: el('alerta-lab'),
+  aoEnviar: async (dados) => {
+    const registro = {
+      nome: dados.nome.trim(),
+      documento: dados.documento.trim() || null,
+      email: dados.email.trim(),
+      telefone: dados.telefone.trim() || null,
+      endereco: dados.endereco.trim() || null,
+      cidade: dados.cidade.trim() || null,
+    };
+    await salvarLaboratorio(lab.id, registro);
+    Object.assign(lab, registro);
+    document.querySelector('[data-nome-lab]').textContent = registro.nome;
+    mostrarToast('Dados do laboratório salvos.');
+  },
+});
+
+// ---------- Logo ----------
+const arquivo = el('logo-arquivo');
+el('btn-trocar-logo').addEventListener('click', () => arquivo.click());
+
+arquivo.addEventListener('change', async () => {
+  const escolhido = arquivo.files[0];
+  arquivo.value = '';
+  if (!escolhido) return;
+  esconderAlerta(el('alerta-logo'));
+  const botao = el('btn-trocar-logo');
+  carregandoBotao(botao, true);
+  try {
+    const url = await enviarLogo(lab.id, escolhido);
+    lab.logo_url = url;
+    mostrarLogo(url);
+    mostrarToast('Logo atualizada.');
+  } catch (erro) {
+    mostrarAlerta(el('alerta-logo'), 'danger', erro.message);
+  } finally {
+    carregandoBotao(botao, false);
+  }
+});
+
+el('btn-remover-logo').addEventListener('click', async () => {
+  if (!confirm('Remover a logo do laboratório?')) return;
+  try {
+    await removerLogo(lab.id);
+    lab.logo_url = null;
+    mostrarLogo(null);
+    mostrarToast('Logo removida.');
+  } catch (erro) {
+    mostrarAlerta(el('alerta-logo'), 'danger', erro.message);
+  }
+});
diff --git a/js/paginas/nota.js b/js/paginas/nota.js
new file mode 100644
index 0000000..620ba55
--- /dev/null
+++ b/js/paginas/nota.js
@@ -0,0 +1,123 @@
+// Nota impressa de uma OS: dados do laboratório, dentista, paciente, serviços, total e colaborador.
+import { exigirLogin, carregarPerfil, ehGestor } from '../auth.js';
+import { obterLaboratorio, obterNotaOrdem } from '../dados.js';
+import { esc, formatarMoeda } from '../formatos.js';
+import { STATUS } from '../status.js';
+
+const sessao = await exigirLogin();
+const { perfil } = await carregarPerfil(sessao.user.id);
+const gestor = ehGestor(perfil);
+document.body.classList.toggle('modo-tecnico', !gestor);
+document.body.classList.remove('carregando');
+
+const nota = document.getElementById('nota');
+const id = new URLSearchParams(location.search).get('id');
+const data = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });
+const dataHora = new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
+const fmtData = (d) => (d ? data.format(new Date(d)) : '—');
+const linha = (rotulo, valor) => (valor ? `<div><span>${rotulo}</span> ${esc(valor)}</div>` : '');
+
+try {
+  if (!id) throw new Error('Ordem de serviço não informada.');
+  const [lab, os] = await Promise.all([obterLaboratorio(), obterNotaOrdem(id)]);
+  document.title = `OS #${os.numero} - ${os.paciente} | ${lab.nome}`;
+
+  const subtotal = (os.itens ?? []).reduce((t, it) => t + Number(it.valor_total || 0), 0);
+  const desconto = Number(os.desconto || 0);
+
+  nota.innerHTML = `
+    <header class="nota-cabecalho">
+      <div class="nota-lab">
+        ${lab.logo_url ? `<img src="${esc(lab.logo_url)}" alt="" class="nota-logo">` : ''}
+        <div>
+          <h1>${esc(lab.nome)}</h1>
+          <div class="nota-lab-dados">
+            ${linha('', lab.documento ? `CNPJ/CPF: ${lab.documento}` : '')}
+            ${linha('', [lab.endereco, lab.cidade].filter(Boolean).join(' · '))}
+            ${linha('', [lab.telefone, lab.email].filter(Boolean).join(' · '))}
+          </div>
+        </div>
+      </div>
+      <div class="nota-numero">
+        <span>Ordem de serviço</span>
+        <strong>Nº ${os.numero}</strong>
+        <small>${STATUS[os.status]?.rotulo ?? ''}</small>
+      </div>
+    </header>
+
+    <section class="nota-blocos">
+      <div class="nota-bloco">
+        <h2>Dentista</h2>
+        <strong>${esc(os.dentista?.nome)}</strong>
+        ${linha('CRO:', os.dentista?.cro)}
+        ${linha('Clínica:', os.dentista?.clinica)}
+        ${linha('Telefone:', os.dentista?.telefone)}
+      </div>
+      <div class="nota-bloco">
+        <h2>Paciente</h2>
+        <strong>${esc(os.paciente)}</strong>
+        ${linha('Cor:', os.cor)}
+      </div>
+      <div class="nota-bloco">
+        <h2>Datas</h2>
+        <div><span>Entrada:</span> ${fmtData(os.data_entrada)}</div>
+        <div><span>Prazo:</span> ${fmtData(os.prazo_entrega)}</div>
+        ${os.data_entrega ? `<div><span>Entregue:</span> ${fmtData(os.data_entrega)}</div>` : ''}
+      </div>
+      <div class="nota-bloco">
+        <h2>Colaborador responsável</h2>
+        <strong>${esc(os.tecnico?.nome ?? 'Não definido')}</strong>
+      </div>
+    </section>
+
+    <table class="nota-tabela">
+      <thead>
+        <tr>
+          <th>Serviço</th>
+          <th>Dentes</th>
+          <th class="text-center">Qtd.</th>
+          <th class="text-end col-valor">Valor unit.</th>
+          <th class="text-end col-valor">Total</th>
+        </tr>
+      </thead>
+      <tbody>
+        ${(os.itens ?? [])
+          .map(
+            (it) => `
+          <tr>
+            <td>${esc(it.servico?.nome)}${it.servico?.categoria ? `<small>${esc(it.servico.categoria)}</small>` : ''}</td>
+            <td>${esc(it.dentes) || '—'}</td>
+            <td class="text-center">${it.quantidade}</td>
+            <td class="text-end col-valor">${formatarMoeda(it.valor_unitario)}</td>
+            <td class="text-end col-valor">${formatarMoeda(it.valor_total)}</td>
+          </tr>`,
+          )
+          .join('')}
+      </tbody>
+    </table>
+
+    <section class="nota-totais col-valor">
+      ${desconto ? `<div><span>Subtotal</span><span>${formatarMoeda(subtotal)}</span></div>
+      <div><span>Desconto</span><span>- ${formatarMoeda(desconto)}</span></div>` : ''}
+      <div class="nota-total"><span>Total</span><span>${formatarMoeda(os.valor_total)}</span></div>
+    </section>
+
+    ${os.observacoes ? `<section class="nota-obs"><h2>Observações</h2><p>${esc(os.observacoes)}</p></section>` : ''}
+
+    <section class="nota-assinaturas">
+      <div><span></span>${esc(os.tecnico?.nome ?? 'Laboratório')}</div>
+      <div><span></span>Recebido por (${esc(os.dentista?.nome)})</div>
+    </section>
+
+    <footer class="nota-rodape">Emitido em ${dataHora.format(new Date())} · ${esc(lab.nome)}</footer>`;
+} catch (erro) {
+  nota.innerHTML = `<div class="alert alert-danger m-4">${esc(erro.message)}</div>`;
+}
+
+// Técnico nunca vê valores; gestor pode esconder (ex.: nota que acompanha o trabalho)
+const chave = document.getElementById('mostrar-valores');
+const aplicarValores = () => nota.classList.toggle('sem-valores', !gestor || !chave.checked);
+chave.addEventListener('change', aplicarValores);
+aplicarValores();
+
+document.getElementById('btn-imprimir').addEventListener('click', () => window.print());
diff --git a/js/paginas/ordens.js b/js/paginas/ordens.js
index 6dc23cd..cf238af 100644
--- a/js/paginas/ordens.js
FIM_ARQUIVO_PW

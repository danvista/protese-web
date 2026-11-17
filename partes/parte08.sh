mkdir -p "js"
cat > "js/ui.js" <<'FIM_ARQUIVO_PW'
// Utilitários de interface reaproveitados por todas as páginas.

/** Mostra um alerta do Bootstrap dentro do elemento. tipo: 'danger' | 'success' | 'info' | 'warning' */
export function mostrarAlerta(elemento, tipo, mensagem) {
  elemento.className = `alert alert-${tipo}`;
  elemento.textContent = mensagem;
  elemento.hidden = false;
}

export function esconderAlerta(elemento) {
  elemento.hidden = true;
  elemento.textContent = '';
}

/** Desabilita o botão e mostra um spinner enquanto a ação roda. */
export function carregandoBotao(botao, carregando) {
  if (carregando) {
    botao.dataset.textoOriginal = botao.innerHTML;
    botao.disabled = true;
    botao.innerHTML = '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Aguarde...';
  } else {
    botao.disabled = false;
    botao.innerHTML = botao.dataset.textoOriginal ?? botao.innerHTML;
  }
}

/**
 * Liga um formulário com validação do Bootstrap.
 * `aoEnviar(dados)` recebe os campos como objeto; erros lançados viram alerta.
 * `validacaoExtra(form)` (opcional) pode marcar campos com setCustomValidity.
 */
export function ligarFormulario(form, { alerta, aoEnviar, validacaoExtra }) {
  // Revalida enquanto o usuário digita (ex.: some o erro de "senhas não conferem" ao corrigir)
  if (validacaoExtra) form.addEventListener('input', () => validacaoExtra(form));

  form.addEventListener('submit', async (evento) => {
    evento.preventDefault();
    esconderAlerta(alerta);
    validacaoExtra?.(form);
    form.classList.add('was-validated');
    if (!form.checkValidity()) return;

    const botao = form.querySelector('[type="submit"]');
    carregandoBotao(botao, true);
    try {
      const dados = Object.fromEntries(new FormData(form));
      await aoEnviar(dados);
    } catch (erro) {
      mostrarAlerta(alerta, 'danger', erro.message);
    } finally {
      carregandoBotao(botao, false);
    }
  });
}

/** Valida que `senha` e `confirmacao` do formulário são iguais. */
export function validarSenhasIguais(form) {
  const confirmacao = form.elements.confirmacao;
  confirmacao.setCustomValidity(confirmacao.value !== form.elements.senha.value ? 'As senhas não conferem.' : '');
}

/** Limpa campos, validação e alerta de um formulário (ex.: ao abrir modal). */
export function limparFormulario(form, alerta) {
  form.reset();
  form.classList.remove('was-validated');
  form.querySelectorAll('input, textarea, select').forEach((campo) => campo.setCustomValidity?.(''));
  if (alerta) esconderAlerta(alerta);
}

/** Preenche campos pelo atributo name. Checkbox recebe boolean. */
export function preencherFormulario(form, dados) {
  for (const [nome, valor] of Object.entries(dados)) {
    const campo = form.elements[nome];
    if (!campo) continue;
    if (campo.type === 'checkbox') campo.checked = Boolean(valor);
    else campo.value = valor ?? '';
  }
}

/** Abre/fecha modal do Bootstrap (bootstrap.bundle carregado na página). */
export function modal(elemento) {
  return window.bootstrap.Modal.getOrCreateInstance(elemento);
}

/** Mensagem rápida no canto da tela. tipo: 'success' | 'danger' */
export function mostrarToast(mensagem, tipo = 'success') {
  let area = document.getElementById('area-toasts');
  if (!area) {
    area = document.createElement('div');
    area.id = 'area-toasts';
    area.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    document.body.append(area);
  }
  const toast = document.createElement('div');
  toast.className = `toast align-items-center text-bg-${tipo} border-0`;
  toast.setAttribute('role', 'status');
  toast.innerHTML = `<div class="d-flex"><div class="toast-body"></div>
    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Fechar"></button></div>`;
  toast.querySelector('.toast-body').textContent = mensagem;
  area.append(toast);
  toast.addEventListener('hidden.bs.toast', () => toast.remove());
  window.bootstrap.Toast.getOrCreateInstance(toast, { delay: 3000 }).show();
}

/** Botão de mostrar/ocultar senha: <button data-alternar-senha="idDoInput"> */
export function ligarAlternarSenha(raiz = document) {
  raiz.querySelectorAll('[data-alternar-senha]').forEach((botao) => {
    botao.addEventListener('click', () => {
      const input = document.getElementById(botao.dataset.alternarSenha);
      const mostrar = input.type === 'password';
      input.type = mostrar ? 'text' : 'password';
      botao.querySelector('i').className = mostrar ? 'bi bi-eye-slash' : 'bi bi-eye';
      botao.setAttribute('aria-label', mostrar ? 'Ocultar senha' : 'Mostrar senha');
    });
  });
}
FIM_ARQUIVO_PW
cat > "recuperar-senha.html" <<'FIM_ARQUIVO_PW'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Recuperar senha | Protese Web</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="css/estilo.css">
</head>
<body>
  <main class="auth-pagina">
    <div class="card shadow-sm auth-card">
      <div class="card-body p-4">
        <div class="auth-marca mb-1"><i class="bi bi-box-seam"></i> Protese Web</div>

        <div id="sucesso" hidden>
          <p class="text-secondary">Verifique seu e-mail</p>
          <div class="alert alert-success">
            Se este e-mail estiver cadastrado, você vai receber um link para criar uma nova senha.
          </div>
        </div>

        <div id="etapa-formulario">
          <p class="text-secondary mb-4">Informe seu e-mail para receber o link de redefinição.</p>

          <div id="alerta" hidden role="alert"></div>

          <form id="form-recuperar" class="vstack gap-3" novalidate>
            <div>
              <label for="email" class="form-label">E-mail</label>
              <input type="email" class="form-control" id="email" name="email" autocomplete="email" required>
              <div class="invalid-feedback">Informe um e-mail válido.</div>
            </div>
            <button type="submit" class="btn btn-primary w-100">Enviar link</button>
          </form>
        </div>

        <p class="text-center small mt-4 mb-0"><a href="entrar.html">Voltar para o login</a></p>
      </div>
    </div>
  </main>

  <script type="module" src="js/paginas/recuperar-senha.js"></script>
</body>
</html>
FIM_ARQUIVO_PW
cat > "redefinir-senha.html" <<'FIM_ARQUIVO_PW'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Nova senha | Protese Web</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="css/estilo.css">
</head>
<body>
  <main class="auth-pagina">
    <div class="card shadow-sm auth-card">
      <div class="card-body p-4">
        <div class="auth-marca mb-1"><i class="bi bi-box-seam"></i> Protese Web</div>

        <p id="verificando" class="text-secondary">Verificando link...</p>

        <div id="link-invalido" hidden>
          <div class="alert alert-danger">Este link é inválido ou expirou. Peça um novo.</div>
          <p class="text-center small mb-0"><a href="recuperar-senha.html">Pedir novo link</a></p>
        </div>

        <div id="etapa-formulario" hidden>
          <p class="text-secondary mb-4">Escolha sua nova senha.</p>

          <div id="alerta" hidden role="alert"></div>

          <form id="form-redefinir" class="vstack gap-3" novalidate>
            <div>
              <label for="senha" class="form-label">Nova senha</label>
              <div class="input-group has-validation">
                <input type="password" class="form-control" id="senha" name="senha" autocomplete="new-password" minlength="8" required>
                <button class="btn btn-outline-secondary" type="button" data-alternar-senha="senha" aria-label="Mostrar senha">
                  <i class="bi bi-eye"></i>
                </button>
                <div class="invalid-feedback">A senha precisa ter pelo menos 8 caracteres.</div>
              </div>
            </div>

            <div>
              <label for="confirmacao" class="form-label">Confirme a nova senha</label>
              <input type="password" class="form-control" id="confirmacao" name="confirmacao" autocomplete="new-password" required>
              <div class="invalid-feedback">As senhas não conferem.</div>
            </div>

            <button type="submit" class="btn btn-primary w-100">Salvar nova senha</button>
          </form>
        </div>
      </div>
    </div>
  </main>

  <script type="module" src="js/paginas/redefinir-senha.js"></script>
</body>
</html>
FIM_ARQUIVO_PW

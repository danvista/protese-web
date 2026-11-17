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

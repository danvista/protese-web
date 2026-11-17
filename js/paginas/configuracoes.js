import { iniciarAreaLogada, somenteLeitura } from '../layout.js';
import { obterLaboratorio, salvarLaboratorio, enviarLogo, removerLogo } from '../dados.js';
import { formatarTelefone } from '../formatos.js';
import { ligarFormulario, preencherFormulario, mostrarToast, mostrarAlerta, esconderAlerta, carregandoBotao } from '../ui.js';

const { perfil, laboratorio: labSessao } = await iniciarAreaLogada('configuracoes');
const el = (id) => document.getElementById(id);
const form = el('form-lab');
const ehDono = perfil?.papel === 'DONO' && !somenteLeitura(labSessao);

let lab = null;

function mostrarLogo(url) {
  const img = el('logo-img');
  img.hidden = !url;
  el('logo-vazio').hidden = !!url;
  el('btn-remover-logo').hidden = !url;
  if (url) img.src = url;
  // Atualiza também a logo do topo, sem recarregar a página
  const topo = document.querySelector('[data-logo-lab]');
  if (topo) {
    topo.hidden = !url;
    if (url) topo.src = url;
    document.querySelector('[data-icone-lab]').hidden = !!url;
  }
}

try {
  lab = await obterLaboratorio();
  preencherFormulario(form, lab);
  mostrarLogo(lab.logo_url);
} catch (erro) {
  mostrarAlerta(el('alerta-lab'), 'danger', erro.message);
}

if (!ehDono) {
  el('aviso-somente-dono').hidden = false;
  form.querySelectorAll('input, textarea').forEach((c) => (c.disabled = true));
  document.querySelectorAll('.so-dono').forEach((c) => (c.hidden = true));
}

form.elements.telefone.addEventListener('blur', (e) => {
  if (e.target.value) e.target.value = formatarTelefone(e.target.value);
});

ligarFormulario(form, {
  alerta: el('alerta-lab'),
  aoEnviar: async (dados) => {
    const registro = {
      nome: dados.nome.trim(),
      documento: dados.documento.trim() || null,
      email: dados.email.trim(),
      telefone: dados.telefone.trim() || null,
      endereco: dados.endereco.trim() || null,
      cidade: dados.cidade.trim() || null,
      dados_pagamento: dados.dados_pagamento.trim() || null,
    };
    await salvarLaboratorio(lab.id, registro);
    Object.assign(lab, registro);
    document.querySelector('[data-nome-lab]').textContent = registro.nome;
    mostrarToast('Dados do laboratório salvos.');
  },
});

// ---------- Logo ----------
const arquivo = el('logo-arquivo');
el('btn-trocar-logo').addEventListener('click', () => arquivo.click());

arquivo.addEventListener('change', async () => {
  const escolhido = arquivo.files[0];
  arquivo.value = '';
  if (!escolhido) return;
  esconderAlerta(el('alerta-logo'));
  const botao = el('btn-trocar-logo');
  carregandoBotao(botao, true);
  try {
    const url = await enviarLogo(lab.id, escolhido);
    lab.logo_url = url;
    mostrarLogo(url);
    mostrarToast('Logo atualizada.');
  } catch (erro) {
    mostrarAlerta(el('alerta-logo'), 'danger', erro.message);
  } finally {
    carregandoBotao(botao, false);
  }
});

el('btn-remover-logo').addEventListener('click', async () => {
  if (!confirm('Remover a logo do laboratório?')) return;
  try {
    await removerLogo(lab.id);
    lab.logo_url = null;
    mostrarLogo(null);
    mostrarToast('Logo removida.');
  } catch (erro) {
    mostrarAlerta(el('alerta-logo'), 'danger', erro.message);
  }
});

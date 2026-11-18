import { iniciarAreaLogada, somenteLeitura } from '../layout.js';
import { obterLaboratorio, salvarLaboratorio, enviarLogo, removerLogo } from '../dados.js';
import { formatarTelefone } from '../formatos.js';
import {
  ligarFormulario, preencherFormulario, mostrarToast, mostrarAlerta, esconderAlerta, carregandoBotao,
  validarSenhasIguais, limparFormulario,
} from '../ui.js';
import { redefinirSenha } from '../auth.js';

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

// ---------- Abas (o endereço guarda a aba: configuracoes.html#aparencia) ----------
const ABAS = { laboratorio: 'aba-laboratorio', aparencia: 'aba-aparencia', conta: 'aba-conta' };
const abaInicial = ABAS[location.hash.slice(1)];
if (abaInicial) window.bootstrap.Tab.getOrCreateInstance(el(abaInicial)).show();
document.querySelectorAll('#abas [data-bs-toggle="pill"]').forEach((botao) => {
  botao.addEventListener('shown.bs.tab', () => {
    const nome = Object.keys(ABAS).find((k) => ABAS[k] === botao.id);
    history.replaceState(null, '', `#${nome}`);
  });
});

// ---------- Aparência (fica salva neste navegador, vale só para a pessoa) ----------
const formAparencia = el('form-aparencia');
const Aparencia = window.AparenciaPW;

function marcarAparencia() {
  const pref = Aparencia.ler();
  for (const nome of ['modo', 'cor', 'fonte']) {
    const opcao = formAparencia.querySelector(`input[name="${nome}"][value="${pref[nome]}"]`);
    if (opcao) opcao.checked = true;
  }
  formAparencia.elements.animacoes.checked = pref.animacoes;
}

formAparencia.addEventListener('change', (e) => {
  const campo = e.target;
  if (campo.name === 'animacoes') Aparencia.salvar({ animacoes: campo.checked });
  else if (campo.type === 'radio') Aparencia.salvar({ [campo.name]: campo.value });
});

el('btn-tema-padrao').addEventListener('click', () => {
  Aparencia.salvar({ ...Aparencia.PADRAO });
  marcarAparencia();
  mostrarToast('Aparência padrão restaurada.');
});

marcarAparencia();

// ---------- Minha conta ----------
const NOMES_PAPEL = { DONO: 'Dono do laboratório', GERENTE: 'Gerente', TECNICO: 'Técnico' };
el('conta-nome').textContent = perfil?.nome ?? '—';
el('conta-email').textContent = perfil?.email ?? '—';
el('conta-papel').textContent = NOMES_PAPEL[perfil?.papel] ?? perfil?.papel ?? '—';

const formSenha = el('form-senha');
ligarFormulario(formSenha, {
  alerta: el('alerta-senha'),
  validacaoExtra: validarSenhasIguais,
  aoEnviar: async ({ senha }) => {
    await redefinirSenha(senha);
    limparFormulario(formSenha, el('alerta-senha'));
    mostrarToast('Senha alterada.');
  },
});

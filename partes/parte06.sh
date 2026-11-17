mkdir -p "js/paginas"
cat > "js/paginas/dentistas.js" <<'FIM_ARQUIVO_PW'
import { iniciarAreaLogada } from '../layout.js';
import { listarDentistas, salvarDentista, listarServicos, listarPrecosDentista, salvarPrecosDentista } from '../dados.js';
import { esc, formatarMoeda, formatarTelefone, lerMoeda, moedaParaCampo, normalizarBusca } from '../formatos.js';
import { ligarFormulario, limparFormulario, preencherFormulario, modal, mostrarToast, mostrarAlerta } from '../ui.js';

const { podeGerenciar } = await iniciarAreaLogada('dentistas');

const lista = document.getElementById('lista');
const vazio = document.getElementById('vazio');
const busca = document.getElementById('busca');
const mostrarInativos = document.getElementById('mostrar-inativos');

let dentistas = [];

// ================= Lista =================

async function carregar() {
  try {
    dentistas = await listarDentistas();
    desenhar();
  } catch (erro) {
    lista.innerHTML = '';
    vazio.textContent = erro.message;
    vazio.hidden = false;
  }
}

function desenhar() {
  const termo = normalizarBusca(busca.value);
  const visiveis = dentistas.filter(
    (d) =>
      (mostrarInativos.checked || d.ativo) &&
      normalizarBusca(`${d.nome} ${d.clinica ?? ''} ${d.cro ?? ''}`).includes(termo),
  );

  lista.innerHTML = visiveis
    .map(
      (d) => `
      <tr class="${d.ativo ? '' : 'text-secondary'}">
        <td class="fw-medium">${esc(d.nome)}</td>
        <td class="d-none d-md-table-cell">${esc(d.clinica)}</td>
        <td class="d-none d-lg-table-cell">${esc(d.cro)}</td>
        <td class="d-none d-sm-table-cell text-nowrap">${esc(d.telefone)}</td>
        <td class="text-center">${d.ativo ? '<span class="badge text-bg-success">Ativo</span>' : '<span class="badge text-bg-secondary">Inativo</span>'}</td>
        <td class="text-end text-nowrap">
          ${
            podeGerenciar
              ? `<button class="btn btn-sm btn-outline-secondary" data-precos="${d.id}" title="Tabela de preços" aria-label="Tabela de preços de ${esc(d.nome)}"><i class="bi bi-currency-dollar"></i></button>
                 <button class="btn btn-sm btn-outline-primary" data-editar="${d.id}" title="Editar" aria-label="Editar ${esc(d.nome)}"><i class="bi bi-pencil"></i></button>`
              : ''
          }
        </td>
      </tr>`,
    )
    .join('');

  if (!dentistas.length) {
    vazio.textContent = podeGerenciar
      ? 'Nenhum dentista cadastrado. Clique em "Novo dentista" para começar.'
      : 'Nenhum dentista cadastrado.';
  } else {
    vazio.textContent = 'Nenhum dentista encontrado.';
  }
  vazio.hidden = visiveis.length > 0;
}

busca.addEventListener('input', desenhar);
mostrarInativos.addEventListener('change', desenhar);

lista.addEventListener('click', (evento) => {
  const editar = evento.target.closest('[data-editar]');
  if (editar) abrirDentista(dentistas.find((d) => d.id === editar.dataset.editar));
  const precos = evento.target.closest('[data-precos]');
  if (precos) abrirPrecos(dentistas.find((d) => d.id === precos.dataset.precos));
});

// ================= Cadastro / edição =================

const elModal = document.getElementById('modal-dentista');
const form = document.getElementById('form-dentista');
const alerta = document.getElementById('alerta-dentista');
let editandoId = null;

function abrirDentista(dentista = null) {
  editandoId = dentista?.id ?? null;
  limparFormulario(form, alerta);
  document.getElementById('titulo-modal').textContent = dentista ? 'Editar dentista' : 'Novo dentista';
  if (dentista) preencherFormulario(form, dentista);
  modal(elModal).show();
}

elModal.addEventListener('shown.bs.modal', () => form.elements.nome.focus());
form.elements.telefone.addEventListener('input', (e) => (e.target.value = formatarTelefone(e.target.value)));

if (podeGerenciar) {
  const btnNovo = document.getElementById('btn-novo');
  btnNovo.hidden = false;
  btnNovo.addEventListener('click', () => abrirDentista());
}

const textoOuNulo = (valor) => valor?.trim() || null;

ligarFormulario(form, {
  alerta,
  aoEnviar: async (dados) => {
    const registro = {
      nome: dados.nome.trim(),
      cro: textoOuNulo(dados.cro),
      clinica: textoOuNulo(dados.clinica),
      telefone: textoOuNulo(dados.telefone),
      email: textoOuNulo(dados.email),
      endereco: textoOuNulo(dados.endereco),
      observacoes: textoOuNulo(dados.observacoes),
      ativo: form.elements.ativo.checked,
    };
    if (!registro.nome) {
      mostrarAlerta(alerta, 'danger', 'Informe o nome do dentista.');
      return;
    }
    await salvarDentista(registro, editandoId);
    modal(elModal).hide();
    mostrarToast(editandoId ? 'Dentista atualizado.' : 'Dentista cadastrado.');
    await carregar();
  },
});

// ================= Tabela de preços =================

const elModalPrecos = document.getElementById('modal-precos');
const formPrecos = document.getElementById('form-precos');
const alertaPrecos = document.getElementById('alerta-precos');
const listaPrecos = document.getElementById('lista-precos');
const precosVazio = document.getElementById('precos-vazio');
let dentistaPrecos = null;
let precosOriginais = new Map();

async function abrirPrecos(dentista) {
  dentistaPrecos = dentista;
  limparFormulario(formPrecos, alertaPrecos);
  document.getElementById('titulo-precos').textContent = `Tabela de preços: ${dentista.nome}`;
  listaPrecos.innerHTML = '<tr><td colspan="3" class="text-center text-secondary py-3">Carregando...</td></tr>';
  precosVazio.hidden = true;
  modal(elModalPrecos).show();

  try {
    const [servicos, precos] = await Promise.all([listarServicos(), listarPrecosDentista(dentista.id)]);
    precosOriginais = precos;
    // Ativos + inativos que ainda têm preço especial salvo (para poder limpar)
    const visiveis = servicos.filter((s) => s.ativo || precos.has(s.id));
    precosVazio.hidden = visiveis.length > 0;
    listaPrecos.innerHTML = visiveis
      .map(
        (s) => `
        <tr>
          <td>${esc(s.nome)}${s.ativo ? '' : ' <span class="badge text-bg-secondary">Inativo</span>'}</td>
          <td class="text-end text-nowrap">${formatarMoeda(s.preco_padrao)}</td>
          <td>
            <div class="input-group input-group-sm has-validation preco-especial">
              <span class="input-group-text">R$</span>
              <input type="text" class="form-control text-end" inputmode="decimal" data-servico="${s.id}"
                     value="${precos.has(s.id) ? moedaParaCampo(precos.get(s.id)) : ''}"
                     placeholder="${moedaParaCampo(s.preco_padrao)}" aria-label="Preço de ${esc(s.nome)} para este dentista">
              <div class="invalid-feedback">Valor inválido.</div>
            </div>
          </td>
        </tr>`,
      )
      .join('');
  } catch (erro) {
    listaPrecos.innerHTML = '';
    mostrarAlerta(alertaPrecos, 'danger', erro.message);
  }
}

ligarFormulario(formPrecos, {
  alerta: alertaPrecos,
  validacaoExtra: (f) => {
    f.querySelectorAll('[data-servico]').forEach((campo) => {
      const valor = lerMoeda(campo.value);
      campo.setCustomValidity(valor !== null && (Number.isNaN(valor) || valor < 0) ? 'inválido' : '');
    });
  },
  aoEnviar: async () => {
    // Envia só o que mudou
    const alterados = new Map();
    formPrecos.querySelectorAll('[data-servico]').forEach((campo) => {
      const servicoId = campo.dataset.servico;
      const novo = lerMoeda(campo.value);
      const antigo = precosOriginais.get(servicoId) ?? null;
      if (novo !== antigo) alterados.set(servicoId, novo);
    });
    if (alterados.size) await salvarPrecosDentista(dentistaPrecos.id, alterados);
    modal(elModalPrecos).hide();
    mostrarToast(alterados.size ? 'Tabela de preços salva.' : 'Nenhuma alteração.');
  },
});

await carregar();
FIM_ARQUIVO_PW
mkdir -p "js/paginas"
cat > "js/paginas/entrar.js" <<'FIM_ARQUIVO_PW'
import { exigirVisitante, entrar } from '../auth.js';
import { ligarFormulario, ligarAlternarSenha } from '../ui.js';

await exigirVisitante();

ligarAlternarSenha();
ligarFormulario(document.getElementById('form-entrar'), {
  alerta: document.getElementById('alerta'),
  aoEnviar: async ({ email, senha }) => {
    await entrar(email.trim(), senha);
    location.replace('inicio.html');
  },
});
FIM_ARQUIVO_PW
mkdir -p "js/paginas"
cat > "js/paginas/inicio.js" <<'FIM_ARQUIVO_PW'
import { iniciarAreaLogada } from '../layout.js';

const { perfil } = await iniciarAreaLogada('inicio');

document.getElementById('nome-usuario').textContent = perfil?.nome ?? '';
FIM_ARQUIVO_PW
mkdir -p "js/paginas"
cat > "js/paginas/recuperar-senha.js" <<'FIM_ARQUIVO_PW'
import { exigirVisitante, enviarLinkRecuperacao } from '../auth.js';
import { ligarFormulario } from '../ui.js';

await exigirVisitante();

ligarFormulario(document.getElementById('form-recuperar'), {
  alerta: document.getElementById('alerta'),
  aoEnviar: async ({ email }) => {
    await enviarLinkRecuperacao(email.trim());
    document.getElementById('etapa-formulario').hidden = true;
    document.getElementById('sucesso').hidden = false;
  },
});
FIM_ARQUIVO_PW

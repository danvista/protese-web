// Monta o topo da área logada e o aviso de teste/assinatura.
// Uso em cada página logada:  const { perfil, laboratorio } = await iniciarAreaLogada('inicio');
import { exigirLogin, carregarPerfil, sair, ehGestor } from './auth.js';
import { NOME_SISTEMA } from './config.js';

const UM_DIA_MS = 24 * 60 * 60 * 1000;

// Itens do menu: { id, rotulo, icone, pagina }. Novas telas entram aqui.
const MENU = [
  { id: 'inicio', rotulo: 'Início', icone: 'bi-house', pagina: 'inicio.html' },
  { id: 'ordens', rotulo: 'Ordens de serviço', icone: 'bi-clipboard2-pulse', pagina: 'ordens.html' },
  { id: 'dentistas', rotulo: 'Dentistas', icone: 'bi-person-vcard', pagina: 'dentistas.html' },
  { id: 'servicos', rotulo: 'Serviços', icone: 'bi-tools', pagina: 'servicos.html' },
  { id: 'financeiro', rotulo: 'Financeiro', icone: 'bi-cash-coin', pagina: 'financeiro.html', soGestor: true },
  { id: 'configuracoes', rotulo: 'Configurações', icone: 'bi-gear', pagina: 'configuracoes.html', soGestor: true },
];

/**
 * Retorna { sessao, perfil, laboratorio, podeGerenciar }.
 * podeGerenciar: DONO/GERENTE com assinatura em dia (o banco aplica a mesma regra via RLS).
 */
export async function iniciarAreaLogada(paginaAtiva) {
  const sessao = await exigirLogin();
  const { perfil, laboratorio } = await carregarPerfil(sessao.user.id);

  montarTopo(perfil, laboratorio, paginaAtiva);
  montarAvisoAssinatura(laboratorio);
  document.body.classList.remove('carregando');

  const podeGerenciar = ehGestor(perfil) && !somenteLeitura(laboratorio);
  return { sessao, perfil, laboratorio, podeGerenciar };
}

function montarTopo(perfil, laboratorio, paginaAtiva) {
  const topo = document.getElementById('topo');
  topo.innerHTML = `
    <nav class="navbar navbar-expand-md bg-white border-bottom">
      <div class="container-fluid">
        <a class="navbar-brand fw-bold" href="inicio.html">
          <img data-logo-lab alt="" hidden> <i class="bi bi-box-seam text-primary" data-icone-lab></i> <span data-nome-lab></span>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#menuPrincipal"
                aria-controls="menuPrincipal" aria-expanded="false" aria-label="Abrir menu">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="menuPrincipal">
          <ul class="navbar-nav me-auto">
            ${MENU.filter((item) => !item.soGestor || ehGestor(perfil)).map(
              (item) => `
              <li class="nav-item">
                <a class="nav-link ${item.id === paginaAtiva ? 'active fw-semibold' : ''}" href="${item.pagina}"
                   ${item.id === paginaAtiva ? 'aria-current="page"' : ''}>
                  <i class="bi ${item.icone}"></i> ${item.rotulo}
                </a>
              </li>`,
            ).join('')}
          </ul>
          <div class="d-flex align-items-center gap-2">
            <span class="small text-secondary" data-nome-usuario></span>
            <button class="btn btn-outline-secondary btn-sm" type="button" data-sair>
              <i class="bi bi-box-arrow-right"></i> Sair
            </button>
          </div>
        </div>
      </div>
    </nav>`;

  // textContent: dados do usuário nunca entram como HTML
  topo.querySelector('[data-nome-lab]').textContent = laboratorio?.nome ?? NOME_SISTEMA;
  if (laboratorio?.logo_url) {
    const logo = topo.querySelector('[data-logo-lab]');
    logo.src = laboratorio.logo_url;
    logo.hidden = false;
    topo.querySelector('[data-icone-lab]').hidden = true;
  }
  topo.querySelector('[data-nome-usuario]').textContent = perfil?.nome ?? '';
  topo.querySelector('[data-sair]').addEventListener('click', sair);
}

export function diasRestantesTeste(laboratorio) {
  if (laboratorio?.status_assinatura !== 'TESTE') return null;
  return Math.max(0, Math.ceil((new Date(laboratorio.teste_ate).getTime() - Date.now()) / UM_DIA_MS));
}

/** Sem assinatura válida o banco bloqueia gravações; aqui só avisamos na tela. */
export function somenteLeitura(laboratorio) {
  if (!laboratorio) return false;
  return (
    laboratorio.status_assinatura === 'BLOQUEADA' ||
    laboratorio.status_assinatura === 'CANCELADA' ||
    diasRestantesTeste(laboratorio) === 0
  );
}

function montarAvisoAssinatura(laboratorio) {
  const aviso = document.getElementById('aviso-assinatura');
  if (!aviso) return;
  const dias = diasRestantesTeste(laboratorio);

  if (somenteLeitura(laboratorio)) {
    aviso.className = 'alert alert-danger mb-0';
    aviso.textContent =
      'Seu período de teste terminou ou a assinatura está suspensa. Você ainda pode consultar seus dados, mas não pode fazer alterações.';
    aviso.hidden = false;
  } else if (dias !== null) {
    aviso.className = 'alert alert-info mb-0';
    aviso.textContent = `Teste grátis: ${dias} ${dias === 1 ? 'dia restante' : 'dias restantes'}.`;
    aviso.hidden = false;
  }
}

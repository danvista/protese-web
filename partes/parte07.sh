mkdir -p "css"
cat > "css/estilo.css" <<'FIM_ARQUIVO_PW'
/* =========================================================
   Tema
   ========================================================= */
:root {
  --cor-fundo: #f3f5fb;
  --cor-primaria: #4f46e5;
  --cor-primaria-escura: #4338ca;
  --cor-primaria-suave: #eef0ff;
  --sombra-1: 0 1px 2px rgba(16, 24, 40, 0.06), 0 1px 3px rgba(16, 24, 40, 0.08);
  --sombra-2: 0 10px 24px -8px rgba(16, 24, 40, 0.18);
  --raio: 0.85rem;
  --ease: cubic-bezier(0.22, 1, 0.36, 1);

  --bs-primary: var(--cor-primaria);
  --bs-primary-rgb: 79, 70, 229;
  --bs-link-color: var(--cor-primaria);
  --bs-link-color-rgb: 79, 70, 229;
  --bs-link-hover-color: var(--cor-primaria-escura);
  --bs-border-radius: 0.6rem;
  --bs-body-font-family: Inter, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
}

body {
  background: var(--cor-fundo);
  min-height: 100vh;
  -webkit-font-smoothing: antialiased;
}

/* Evita "piscar" a página logada antes de confirmar a sessão */
body.carregando {
  visibility: hidden;
}

.btn-primary {
  --bs-btn-bg: var(--cor-primaria);
  --bs-btn-border-color: var(--cor-primaria);
  --bs-btn-hover-bg: var(--cor-primaria-escura);
  --bs-btn-hover-border-color: var(--cor-primaria-escura);
  --bs-btn-active-bg: var(--cor-primaria-escura);
  --bs-btn-active-border-color: var(--cor-primaria-escura);
  --bs-btn-disabled-bg: var(--cor-primaria);
  --bs-btn-disabled-border-color: var(--cor-primaria);
  box-shadow: 0 4px 14px -6px rgba(79, 70, 229, 0.6);
}

.btn-outline-primary {
  --bs-btn-color: var(--cor-primaria);
  --bs-btn-border-color: var(--cor-primaria);
  --bs-btn-hover-bg: var(--cor-primaria);
  --bs-btn-hover-border-color: var(--cor-primaria);
  --bs-btn-active-bg: var(--cor-primaria-escura);
}

.text-primary {
  color: var(--cor-primaria) !important;
}

.btn {
  transition: transform 0.15s var(--ease), box-shadow 0.2s var(--ease), background-color 0.2s, border-color 0.2s, color 0.2s;
}

.btn:active {
  transform: scale(0.97);
}

.btn-animado:hover {
  transform: translateY(-1px);
}

.form-control,
.form-select {
  transition: border-color 0.2s, box-shadow 0.2s;
}

.form-control:focus,
.form-select:focus,
.form-check-input:focus {
  border-color: #a5a1f6;
  box-shadow: 0 0 0 0.22rem rgba(79, 70, 229, 0.15);
}

.form-check-input:checked {
  background-color: var(--cor-primaria);
  border-color: var(--cor-primaria);
}

.card {
  border: 1px solid rgba(16, 24, 40, 0.06);
  border-radius: var(--raio);
  box-shadow: var(--sombra-1);
}

.cartao-suave {
  background: #fafbff;
}

/* =========================================================
   Animações
   ========================================================= */
@keyframes surgir {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: none; }
}

@keyframes surgirEscala {
  from { opacity: 0; transform: scale(0.96); }
  to { opacity: 1; transform: none; }
}

@keyframes sair {
  to { opacity: 0; transform: translateX(16px); }
}

@keyframes brilho {
  from { background-position: -400px 0; }
  to { background-position: 400px 0; }
}

.conteudo,
.auth-card {
  animation: surgir 0.45s var(--ease) both;
}

.table tbody tr {
  animation: surgir 0.35s var(--ease) both;
}

.modal.fade .modal-dialog {
  transform: translateY(24px) scale(0.98);
  transition: transform 0.35s var(--ease), opacity 0.25s;
}

.modal.show .modal-dialog {
  transform: none;
}

.modal-content {
  border: 0;
  border-radius: 1rem;
  box-shadow: 0 30px 60px -20px rgba(16, 24, 40, 0.35);
}

.toast {
  animation: surgir 0.3s var(--ease) both;
  border-radius: 0.75rem;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation: none !important;
    transition: none !important;
  }
}

/* =========================================================
   Telas de autenticação
   ========================================================= */
.auth-pagina {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
  background:
    radial-gradient(60rem 30rem at 10% -10%, rgba(79, 70, 229, 0.18), transparent 60%),
    radial-gradient(50rem 30rem at 110% 110%, rgba(14, 165, 233, 0.16), transparent 60%),
    var(--cor-fundo);
}

.auth-card {
  width: 100%;
  max-width: 26rem;
  border: 0;
  box-shadow: var(--sombra-2);
}

.auth-marca {
  font-weight: 700;
  font-size: 1.25rem;
}

.auth-marca .bi {
  color: var(--cor-primaria);
}

/* =========================================================
   Área logada
   ========================================================= */
#topo .navbar {
  position: sticky;
  top: 0;
  z-index: 1020;
  background: rgba(255, 255, 255, 0.85) !important;
  backdrop-filter: saturate(180%) blur(10px);
}

#topo .nav-link {
  border-radius: 0.6rem;
  padding: 0.45rem 0.8rem !important;
  margin: 0 0.1rem;
  color: #475467;
  transition: background-color 0.2s, color 0.2s;
}

#topo .nav-link:hover {
  background: #f2f4f7;
  color: #101828;
}

#topo .nav-link.active {
  background: var(--cor-primaria-suave);
  color: var(--cor-primaria);
}

.conteudo {
  max-width: 80rem;
  margin: 0 auto;
  padding: 1.5rem;
}

.aviso-wrapper {
  max-width: 80rem;
  margin: 1rem auto 0;
  padding: 0 1.5rem;
}

/* =========================================================
   Listas
   ========================================================= */
.busca {
  max-width: 22rem;
}

.col-acoes {
  width: 1%;
  white-space: nowrap;
}

.texto-curto {
  max-width: 18rem;
}

.preco-especial {
  max-width: 10rem;
  margin-left: auto;
}

.estado-vazio {
  text-align: center;
  color: #667085;
  padding: 3rem 1rem;
  animation: surgir 0.4s var(--ease) both;
}

.estado-vazio .bi {
  font-size: 2.5rem;
  color: #c4c8f5;
  display: block;
  margin-bottom: 0.5rem;
}

/* =========================================================
   Ordens de serviço
   ========================================================= */
.filtros-status {
  display: flex;
  gap: 0.5rem;
  overflow-x: auto;
  padding-bottom: 0.25rem;
  scrollbar-width: thin;
}

.chip {
  border: 1px solid #e4e7ec;
  background: #fff;
  border-radius: 999px;
  padding: 0.35rem 0.8rem;
  font-size: 0.875rem;
  white-space: nowrap;
  color: #344054;
  transition: all 0.2s var(--ease);
}

.chip:hover {
  border-color: #c7c9f7;
  transform: translateY(-1px);
}

.chip.ativo {
  background: var(--cor-primaria);
  border-color: var(--cor-primaria);
  color: #fff;
  box-shadow: 0 6px 16px -8px rgba(79, 70, 229, 0.8);
}

.chip .contador {
  display: inline-block;
  min-width: 1.4rem;
  margin-left: 0.25rem;
  padding: 0 0.35rem;
  border-radius: 999px;
  background: rgba(16, 24, 40, 0.07);
  font-size: 0.75rem;
  font-weight: 600;
}

.chip.ativo .contador {
  background: rgba(255, 255, 255, 0.25);
}

.grade-os {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(17rem, 1fr));
  gap: 1rem;
}

.cartao-os {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  min-height: 10.5rem;
  text-align: left;
FIM_ARQUIVO_PW

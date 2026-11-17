cat > "entrar.html" <<'FIM_ARQUIVO_PW'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Entrar | Protese Web</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="css/estilo.css">
</head>
<body>
  <main class="auth-pagina">
    <div class="card shadow-sm auth-card">
      <div class="card-body p-4">
        <div class="auth-marca mb-1"><i class="bi bi-box-seam"></i> Protese Web</div>
        <p class="text-secondary mb-4">Entre para acessar seu laboratório</p>

        <div id="alerta" hidden role="alert"></div>

        <form id="form-entrar" class="vstack gap-3" novalidate>
          <div>
            <label for="email" class="form-label">E-mail</label>
            <input type="email" class="form-control" id="email" name="email" autocomplete="email" required>
            <div class="invalid-feedback">Informe um e-mail válido.</div>
          </div>

          <div>
            <label for="senha" class="form-label">Senha</label>
            <div class="input-group has-validation">
              <input type="password" class="form-control" id="senha" name="senha" autocomplete="current-password" required>
              <button class="btn btn-outline-secondary" type="button" data-alternar-senha="senha" aria-label="Mostrar senha">
                <i class="bi bi-eye"></i>
              </button>
              <div class="invalid-feedback">Informe sua senha.</div>
            </div>
          </div>

          <a class="align-self-end small" href="recuperar-senha.html">Esqueci minha senha</a>

          <button type="submit" class="btn btn-primary w-100">Entrar</button>
        </form>

        <p class="text-center text-secondary small mt-4 mb-0">
          Ainda não tem conta? <a href="cadastro.html">Teste grátis por 30 dias</a>
        </p>
      </div>
    </div>
  </main>

  <script type="module" src="js/paginas/entrar.js"></script>
</body>
</html>
FIM_ARQUIVO_PW
cat > "index.html" <<'FIM_ARQUIVO_PW'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <title>Protese Web</title>
  <!-- A página inicial manda para o sistema; sem login, o sistema manda para entrar.html -->
  <meta http-equiv="refresh" content="0; url=inicio.html">
</head>
<body>
  <a href="inicio.html">Abrir o sistema</a>
</body>
</html>
FIM_ARQUIVO_PW
cat > "inicio.html" <<'FIM_ARQUIVO_PW'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Início | Protese Web</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="css/estilo.css">
</head>
<body class="carregando">
  <header id="topo"></header>
  <div class="aviso-wrapper"><div id="aviso-assinatura" hidden role="status"></div></div>

  <main class="conteudo">
    <h1 class="h3 mb-3">Olá, <span id="nome-usuario"></span>!</h1>
    <div class="card">
      <div class="card-body">
        Sua conta está pronta. Nas próximas etapas, aqui vai aparecer o painel do dia: ordens que entram,
        que saem e que estão atrasadas.
      </div>
    </div>
  </main>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>
  <script type="module" src="js/paginas/inicio.js"></script>
</body>
</html>
FIM_ARQUIVO_PW
mkdir -p "js"
cat > "js/auth.js" <<'FIM_ARQUIVO_PW'
import { supabase } from './supabase.js';

/** URL absoluta de uma página do sistema (funciona também em subpastas, ex.: GitHub Pages). */
export function urlDaPagina(pagina) {
  return new URL(pagina, location.href).href;
}

export async function obterSessao() {
  const { data } = await supabase.auth.getSession();
  return data.session;
}

/** Usar no topo das páginas da área logada. Sem sessão, manda para o login. */
export async function exigirLogin() {
  const sessao = await obterSessao();
  if (!sessao) {
    location.replace('entrar.html');
    return new Promise(() => {}); // interrompe o resto da página enquanto redireciona
  }
  return sessao;
}

/** Usar nas telas de login/cadastro. Logado, vai direto para o sistema. */
export async function exigirVisitante() {
  if (await obterSessao()) {
    location.replace('inicio.html');
    return new Promise(() => {});
  }
}

/** Usuário logado + laboratório dele (o RLS só devolve o laboratório do próprio usuário). */
export async function carregarPerfil(usuarioId) {
  const [usuario, laboratorio] = await Promise.all([
    supabase.from('usuarios').select('id, nome, email, papel').eq('id', usuarioId).single(),
    supabase.from('laboratorios').select('id, nome, status_assinatura, teste_ate').single(),
  ]);
  return { perfil: usuario.data, laboratorio: laboratorio.data };
}

export function ehGestor(perfil) {
  return perfil?.papel === 'DONO' || perfil?.papel === 'GERENTE';
}

export async function cadastrar({ nome, nomeLaboratorio, email, senha }) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password: senha,
    options: {
      // Lidos pela trigger tg_novo_usuario para criar o laboratório
      data: { nome, nome_laboratorio: nomeLaboratorio },
      emailRedirectTo: urlDaPagina('entrar.html'),
    },
  });
  if (error) throw new Error(traduzirErro(error));
  // Com confirmação de e-mail ligada, o Supabase não acusa e-mail repetido: devolve usuário sem identidades.
  if (data.user && data.user.identities?.length === 0) {
    throw new Error('Este e-mail já está cadastrado.');
  }
  return { precisaConfirmarEmail: !data.session };
}

export async function entrar(email, senha) {
  const { error } = await supabase.auth.signInWithPassword({ email, password: senha });
  if (error) throw new Error(traduzirErro(error));
}

export async function sair() {
  await supabase.auth.signOut();
  location.replace('entrar.html');
}

export async function enviarLinkRecuperacao(email) {
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: urlDaPagina('redefinir-senha.html'),
  });
  if (error) throw new Error(traduzirErro(error));
}

export async function redefinirSenha(novaSenha) {
  const { error } = await supabase.auth.updateUser({ password: novaSenha });
  if (error) throw new Error(traduzirErro(error));
}

function traduzirErro(erro) {
  switch (erro.code) {
    case 'invalid_credentials':
      return 'E-mail ou senha incorretos.';
    case 'email_not_confirmed':
      return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
    case 'user_already_exists':
    case 'email_exists':
      return 'Este e-mail já está cadastrado.';
    case 'weak_password':
      return 'Senha muito fraca. Use pelo menos 8 caracteres.';
    case 'same_password':
      return 'A nova senha precisa ser diferente da atual.';
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    case 'email_address_invalid':
      return 'E-mail inválido.';
    default:
      return 'Não foi possível concluir. Tente novamente.';
  }
}
FIM_ARQUIVO_PW

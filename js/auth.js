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

import { obterSessao, redefinirSenha } from '../auth.js';
import { ligarFormulario, ligarAlternarSenha, validarSenhasIguais } from '../ui.js';

// O supabase-js lê o token do link de recuperação na URL e abre a sessão.
const sessao = await obterSessao();
document.getElementById('verificando').hidden = true;

if (!sessao) {
  document.getElementById('link-invalido').hidden = false;
} else {
  document.getElementById('etapa-formulario').hidden = false;
  ligarAlternarSenha();
  ligarFormulario(document.getElementById('form-redefinir'), {
    alerta: document.getElementById('alerta'),
    validacaoExtra: validarSenhasIguais,
    aoEnviar: async ({ senha }) => {
      await redefinirSenha(senha);
      location.replace('inicio.html');
    },
  });
}

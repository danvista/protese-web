import { exigirVisitante, cadastrar } from '../auth.js';
import { ligarFormulario, ligarAlternarSenha, validarSenhasIguais } from '../ui.js';

await exigirVisitante();

ligarAlternarSenha();
ligarFormulario(document.getElementById('form-cadastro'), {
  alerta: document.getElementById('alerta'),
  validacaoExtra: validarSenhasIguais,
  aoEnviar: async ({ nome, nomeLaboratorio, email, senha }) => {
    const { precisaConfirmarEmail } = await cadastrar({
      nome: nome.trim(),
      nomeLaboratorio: nomeLaboratorio.trim(),
      email: email.trim(),
      senha,
    });

    if (!precisaConfirmarEmail) {
      location.replace('inicio.html');
      return;
    }
    document.getElementById('email-enviado').textContent = email.trim();
    document.getElementById('etapa-formulario').hidden = true;
    document.getElementById('sucesso').hidden = false;
  },
});

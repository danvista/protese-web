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

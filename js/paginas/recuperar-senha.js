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

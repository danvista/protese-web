import { iniciarAreaLogada } from '../layout.js';

const { perfil } = await iniciarAreaLogada('inicio');

document.getElementById('nome-usuario').textContent = perfil?.nome ?? '';

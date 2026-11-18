// Aparência escolhida por cada pessoa (fica salva neste navegador).
// Carregado no <head> de todas as páginas, antes do CSS aparecer, para não "piscar".
// <script src="js/tema.js" data-so-cor></script> aplica só a cor (páginas de impressão ficam claras).
(function () {
  var CHAVE = 'pw-aparencia';
  var PADRAO = { modo: 'claro', cor: 'roxo', fonte: 'normal', animacoes: true };
  var raiz = document.documentElement;
  var soCor = document.currentScript && document.currentScript.hasAttribute('data-so-cor');
  var escuroSistema = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  function ler() {
    try {
      var salvo = JSON.parse(localStorage.getItem(CHAVE) || '{}');
      return Object.assign({}, PADRAO, salvo);
    } catch (e) {
      return Object.assign({}, PADRAO);
    }
  }

  function aplicar(pref) {
    pref = pref || ler();
    var escuro = pref.modo === 'escuro' || (pref.modo === 'auto' && escuroSistema && escuroSistema.matches);
    raiz.setAttribute('data-bs-theme', !soCor && escuro ? 'dark' : 'light');
    raiz.setAttribute('data-cor', pref.cor);
    if (soCor) return;
    raiz.setAttribute('data-fonte', pref.fonte);
    raiz.toggleAttribute('data-sem-animacao', !pref.animacoes);
  }

  function salvar(pref) {
    var atual = Object.assign(ler(), pref);
    try { localStorage.setItem(CHAVE, JSON.stringify(atual)); } catch (e) { /* navegador sem armazenamento */ }
    aplicar(atual);
    return atual;
  }

  if (escuroSistema && escuroSistema.addEventListener) {
    escuroSistema.addEventListener('change', function () { if (ler().modo === 'auto') aplicar(); });
  }
  // Outra aba mudou o tema: acompanha
  window.addEventListener('storage', function (e) { if (e.key === CHAVE) aplicar(); });

  aplicar();
  window.AparenciaPW = { ler: ler, salvar: salvar, aplicar: aplicar, PADRAO: PADRAO };
})();

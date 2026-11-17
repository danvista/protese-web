// Calendário em português para campos de data.
// Uso: <input type="text" id="prazo" name="prazo" data-calendario required>
//      ligarCalendario(input, { atalhos: [...], minimo: 'hoje', relativo: true })
// O valor do campo continua no formato AAAA-MM-DD (o resto do código não muda).

const MESES = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
const SEMANA = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
const SEMANA_LONGA = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
const DESCRITOR_VALOR = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');

export const ATALHOS_PRAZO = [
  { rotulo: 'Hoje', dias: 0 },
  { rotulo: 'Amanhã', dias: 1 },
  { rotulo: '3 dias', dias: 3 },
  { rotulo: '5 dias', dias: 5 },
  { rotulo: '1 semana', dias: 7 },
  { rotulo: '15 dias', dias: 15 },
];
export const ATALHOS_PASSADO = [
  { rotulo: 'Hoje', dias: 0 },
  { rotulo: 'Ontem', dias: -1 },
  { rotulo: 'Anteontem', dias: -2 },
];

/** Date -> "AAAA-MM-DD" (horário local) */
export function paraIso(data) {
  return `${data.getFullYear()}-${String(data.getMonth() + 1).padStart(2, '0')}-${String(data.getDate()).padStart(2, '0')}`;
}

/** "AAAA-MM-DD" -> Date local (meia-noite) ou null */
export function deIso(texto) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(texto ?? '');
  return m ? new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3])) : null;
}

export function hoje() {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

export function somarDias(data, dias) {
  const d = new Date(data);
  d.setDate(d.getDate() + dias);
  return d;
}

const diasEntre = (a, b) => Math.round((b - a) / 86400000);

/** "Hoje", "Amanhã", "em 5 dias", "há 2 dias"... */
export function textoRelativo(data) {
  const n = diasEntre(hoje(), data);
  if (n === 0) return 'Hoje';
  if (n === 1) return 'Amanhã';
  if (n === -1) return 'Ontem';
  return n > 0 ? `em ${n} dias` : `há ${-n} dias`;
}

function textoData(data) {
  return `${SEMANA_LONGA[data.getDay()]}, ${data.getDate()} de ${MESES[data.getMonth()]} de ${data.getFullYear()}`;
}

/**
 * opcoes:
 *  - atalhos: [{ rotulo, dias }] (dias a partir de hoje)
 *  - minimo / maximo: 'hoje' | Date (dias fora do intervalo ficam desabilitados)
 *  - relativo: mostra "em 5 dias" ao lado da data
 *  - tomRelativo: true colore o selo (vermelho se passou, amarelo se é hoje)
 *  - placeholder: texto quando vazio
 */
export function ligarCalendario(input, opcoes = {}) {
  if (input.dataset.calendarioLigado) return input._calendario;
  input.dataset.calendarioLigado = '1';
  const { atalhos = [], relativo = true, tomRelativo = false, placeholder = 'Escolher data' } = opcoes;
  const limite = (v) => (v === 'hoje' ? hoje() : v ?? null);

  // Estrutura: [botão que parece campo] + [menu com o calendário]; o input original fica escondido
  const caixa = document.createElement('div');
  caixa.className = 'campo-data dropdown';
  input.parentNode.insertBefore(caixa, input);

  const botao = document.createElement('button');
  botao.type = 'button';
  botao.className = 'form-control botao-data';
  botao.id = `${input.id}-botao`;
  botao.setAttribute('data-bs-toggle', 'dropdown');
  botao.setAttribute('data-bs-auto-close', 'outside');
  botao.setAttribute('aria-expanded', 'false');
  botao.innerHTML = '<i class="bi bi-calendar3 data-icone" aria-hidden="true"></i><span class="data-texto"></span><span class="data-selo"></span><i class="bi bi-chevron-down data-seta" aria-hidden="true"></i>';

  const menu = document.createElement('div');
  menu.className = 'dropdown-menu calendario';

  caixa.append(botao, menu, input);
  input.classList.add('visually-hidden');
  input.tabIndex = -1;
  input.setAttribute('aria-hidden', 'true');
  input.autocomplete = 'off';
  document.querySelector(`label[for="${input.id}"]`)?.setAttribute('for', botao.id);

  let mesVisto = null; // primeiro dia do mês exibido

  const dropdown = () =>
    window.bootstrap.Dropdown.getOrCreateInstance(botao, {
      popperConfig: (padrao) => ({ ...padrao, strategy: 'fixed' }),
    });

  function selecionado() {
    return deIso(DESCRITOR_VALOR.get.call(input));
  }

  function foraDoLimite(data) {
    const min = limite(opcoes.minimo);
    const max = limite(opcoes.maximo);
    return (min && data < min) || (max && data > max);
  }

  function desenharBotao() {
    const data = selecionado();
    const texto = botao.querySelector('.data-texto');
    const selo = botao.querySelector('.data-selo');
    texto.textContent = data ? textoData(data) : placeholder;
    botao.classList.toggle('vazio', !data);
    selo.hidden = !(data && relativo);
    if (data && relativo) {
      selo.textContent = textoRelativo(data);
      const n = diasEntre(hoje(), data);
      selo.className = `data-selo ${tomRelativo ? (n < 0 ? 'selo-passou' : n === 0 ? 'selo-hoje' : n <= 2 ? 'selo-breve' : 'selo-ok') : 'selo-ok'}`;
    }
  }

  function desenharMenu() {
    const sel = selecionado();
    const base = mesVisto ?? new Date((sel ?? hoje()).getFullYear(), (sel ?? hoje()).getMonth(), 1);
    mesVisto = base;
    const inicio = somarDias(base, -base.getDay()); // domingo antes do dia 1
    const hj = hoje();

    let dias = '';
    for (let i = 0; i < 42; i++) {
      const d = somarDias(inicio, i);
      const classes = ['cal-dia'];
      if (d.getMonth() !== base.getMonth()) classes.push('fora');
      if (d.getDay() === 0 || d.getDay() === 6) classes.push('fds');
      if (+d === +hj) classes.push('hoje');
      if (sel && +d === +sel) classes.push('selecionado');
      const bloqueado = foraDoLimite(d);
      dias += `<button type="button" class="${classes.join(' ')}" data-dia="${paraIso(d)}" ${bloqueado ? 'disabled' : ''}
        aria-label="${textoData(d)}" ${sel && +d === +sel ? 'aria-pressed="true"' : ''}>${d.getDate()}</button>`;
    }

    menu.innerHTML = `
      <div class="cal-topo">
        <button type="button" class="cal-nav" data-mes="-1" aria-label="Mês anterior"><i class="bi bi-chevron-left"></i></button>
        <strong class="cal-titulo">${MESES[base.getMonth()]} <span>${base.getFullYear()}</span></strong>
        <button type="button" class="cal-nav" data-mes="1" aria-label="Próximo mês"><i class="bi bi-chevron-right"></i></button>
      </div>
      <div class="cal-semana">${SEMANA.map((s) => `<span>${s}</span>`).join('')}</div>
      <div class="cal-grade">${dias}</div>
      ${atalhos.length ? `<div class="cal-atalhos">${atalhos
        .map((a) => {
          const d = somarDias(hj, a.dias);
          return `<button type="button" class="cal-atalho" data-dia="${paraIso(d)}" ${foraDoLimite(d) ? 'disabled' : ''}>${a.rotulo}</button>`;
        })
        .join('')}</div>` : ''}`;
  }

  function escolher(iso) {
    input.value = iso; // passa pelo setter abaixo e redesenha
    input.dispatchEvent(new Event('input', { bubbles: true }));
    input.dispatchEvent(new Event('change', { bubbles: true }));
    dropdown().hide();
    botao.focus();
  }

  menu.addEventListener('click', (e) => {
    const nav = e.target.closest('[data-mes]');
    if (nav) {
      mesVisto = new Date(mesVisto.getFullYear(), mesVisto.getMonth() + Number(nav.dataset.mes), 1);
      desenharMenu();
      return;
    }
    const dia = e.target.closest('[data-dia]');
    if (dia && !dia.disabled) escolher(dia.dataset.dia);
  });

  // Setas do teclado andam pelos dias; Enter escolhe; Esc fecha sem fechar o modal
  menu.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      e.stopPropagation();
      dropdown().hide();
      botao.focus();
      return;
    }
    const passo = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }[e.key];
    const atual = e.target.closest('.cal-dia');
    if (!passo || !atual) return;
    e.preventDefault();
    const alvo = somarDias(deIso(atual.dataset.dia), passo);
    if (alvo.getMonth() !== mesVisto.getMonth()) {
      mesVisto = new Date(alvo.getFullYear(), alvo.getMonth(), 1);
      desenharMenu();
    }
    menu.querySelector(`[data-dia="${paraIso(alvo)}"].cal-dia`)?.focus();
  });

  botao.addEventListener('show.bs.dropdown', () => {
    mesVisto = null;
    desenharMenu();
  });
  botao.addEventListener('shown.bs.dropdown', () => {
    (menu.querySelector('.cal-dia.selecionado') ?? menu.querySelector('.cal-dia.hoje'))?.focus();
  });

  // Quando o código muda o valor (input.value = ...), o botão acompanha
  Object.defineProperty(input, 'value', {
    configurable: true,
    get() { return DESCRITOR_VALOR.get.call(this); },
    set(v) { DESCRITOR_VALOR.set.call(this, v); desenharBotao(); },
  });
  input.form?.addEventListener('reset', () => setTimeout(desenharBotao, 0));

  // Mantém o botão habilitado/desabilitado junto com o campo
  const sincronizar = (de, para) => () => { if (para.disabled !== de.disabled) para.disabled = de.disabled; };
  new MutationObserver(sincronizar(input, botao)).observe(input, { attributes: true, attributeFilter: ['disabled'] });
  new MutationObserver(sincronizar(botao, input)).observe(botao, { attributes: true, attributeFilter: ['disabled'] });

  desenharBotao();
  dropdown();
  input._calendario = { atualizar: desenharBotao, opcoes };
  return input._calendario;
}

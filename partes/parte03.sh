cat >> "js/paginas/ordens.js" <<'FIM_ARQUIVO_PW'
    '<option value="">Ninguém definido</option>' + usuarios.map((u) => `<option value="${u.id}">${esc(u.nome)}</option>`).join('');
}

function opcoesServico(select, selecionado) {
  const ativos = servicos.filter((s) => s.ativo || s.id === selecionado);
  select.innerHTML = '<option value="">Selecione...</option>' + ativos.map((s) => `<option value="${s.id}">${esc(s.nome)}</option>`).join('');
  if (selecionado) select.value = selecionado;
}

function adicionarItem(item = null) {
  const linha = modeloItem.content.firstElementChild.cloneNode(true);
  opcoesServico(linha.querySelector('[data-campo="servico_id"]'), item?.servico_id);
  linha.querySelector('[data-campo="dentes"]').value = item?.dentes ?? '';
  linha.querySelector('[data-campo="quantidade"]').value = item?.quantidade ?? 1;
  // Item já salvo mantém o preço com que foi lançado
  if (item?.valor_unitario != null) {
    linha.dataset.valorOriginal = item.valor_unitario;
    linha.dataset.servicoOriginal = item.servico_id;
  }
  linha.classList.add('item-novo');
  corpoItens.append(linha);
  atualizarTotais();
  return linha;
}

function precoDoServico(servicoId) {
  if (precosDentista.has(servicoId)) return precosDentista.get(servicoId);
  return Number(servicos.find((s) => s.id === servicoId)?.preco_padrao ?? 0);
}

function valorUnitarioDaLinha(linha) {
  const servicoId = linha.querySelector('[data-campo="servico_id"]').value;
  if (!servicoId) return null;
  if (linha.dataset.valorOriginal && linha.dataset.servicoOriginal === servicoId) return Number(linha.dataset.valorOriginal);
  return precoDoServico(servicoId);
}

function atualizarTotais() {
  let soma = 0;
  corpoItens.querySelectorAll('.linha-item').forEach((linha) => {
    const unit = valorUnitarioDaLinha(linha);
    const qtd = Number(linha.querySelector('[data-campo="quantidade"]').value) || 0;
    const total = unit == null ? null : unit * qtd;
    linha.querySelector('[data-campo="valor"]').textContent = total == null ? '—' : formatarMoeda(total);
    soma += total ?? 0;
  });
  const desconto = lerMoeda(form.elements.desconto.value) || 0;
  el('total-os').textContent = formatarMoeda(Math.max(soma - desconto, 0));
  sugerirPrazo();
}

/** Prazo sugerido: maior prazo padrão entre os serviços (até a pessoa mexer no campo). */
function sugerirPrazo() {
  if (prazoTocado || ordemAtual) return;
  const dias = Math.max(
    0,
    ...[...corpoItens.querySelectorAll('[data-campo="servico_id"]')].map(
      (s) => servicos.find((sv) => sv.id === s.value)?.prazo_padrao_dias ?? 0,
    ),
  );
  if (!dias) return;
  const data = new Date();
  data.setDate(data.getDate() + dias);
  form.elements.prazo.value = paraCampoData(data);
}

function paraCampoData(data) {
  const d = new Date(data);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

corpoItens.addEventListener('input', atualizarTotais);
corpoItens.addEventListener('change', atualizarTotais);
corpoItens.addEventListener('click', (e) => {
  const remover = e.target.closest('[data-remover]');
  if (!remover) return;
  const linha = remover.closest('tr');
  linha.classList.add('item-saindo');
  linha.addEventListener('animationend', () => { linha.remove(); atualizarTotais(); }, { once: true });
});
el('btn-add-item').addEventListener('click', () => adicionarItem().querySelector('select').focus());
form.elements.prazo.addEventListener('input', () => (prazoTocado = true));
form.elements.desconto.addEventListener('input', atualizarTotais);

form.elements.dentista_id.addEventListener('change', async () => {
  precosDentista = new Map();
  const id = form.elements.dentista_id.value;
  // Técnico não lê a tabela de preços (RLS); o banco aplica o preço certo ao salvar.
  if (id && gestor) {
    try { precosDentista = await listarPrecosDentista(id); } catch { /* usa preço padrão */ }
  }
  atualizarTotais();
});

async function abrirOrdem(id = null) {
  limparFormulario(form, alerta);
  corpoItens.innerHTML = '';
  ordemAtual = null;
  prazoTocado = false;
  precosDentista = new Map();
  modal(elModal).show();

  try {
    await carregarCadastros();
    opcoesTecnico();

    if (!id) {
      el('titulo-os').textContent = 'Nova ordem de serviço';
      el('status-atual').innerHTML = '';
      el('painel-etapa').hidden = true;
      opcoesDentista();
      adicionarItem();
      definirEdicao(true);
      return;
    }

    ordemAtual = await obterOrdem(id);
    el('titulo-os').textContent = `OS #${ordemAtual.numero}`;
    el('status-atual').innerHTML = badgeStatus(ordemAtual.status);
    opcoesDentista(ordemAtual.dentista_id);
    form.elements.dentista_id.value = ordemAtual.dentista_id;
    form.elements.paciente.value = ordemAtual.paciente;
    form.elements.cor.value = ordemAtual.cor ?? '';
    form.elements.prazo.value = paraCampoData(ordemAtual.prazo_entrega);
    form.elements.tecnico_responsavel_id.value = ordemAtual.tecnico_responsavel_id ?? '';
    form.elements.observacoes.value = ordemAtual.observacoes ?? '';
    form.elements.desconto.value = Number(ordemAtual.desconto) ? moedaParaCampo(ordemAtual.desconto) : '';
    if (gestor) {
      try { precosDentista = await listarPrecosDentista(ordemAtual.dentista_id); } catch { /* ignora */ }
    }
    ordemAtual.itens.forEach((item) => adicionarItem(item));
    atualizarTotais();

    // Entregue/cancelada: só consulta (muda pela etapa, se precisar)
    definirEdicao(podeEditar && ABERTAS.includes(ordemAtual.status));
    await desenharEtapa();
  } catch (erro) {
    mostrarAlerta(alerta, 'danger', erro.message);
  }
}

function definirEdicao(habilitado) {
  form.querySelectorAll('.col-lg-8 input, .col-lg-8 select, .col-lg-8 textarea, .col-lg-8 button').forEach((c) => (c.disabled = !habilitado));
  el('btn-salvar').hidden = !habilitado;
}

async function desenharEtapa() {
  el('painel-etapa').hidden = false;
  const status = el('status');
  status.innerHTML = Object.entries(STATUS).map(([k, s]) => `<option value="${k}">${s.rotulo}</option>`).join('');
  status.value = ordemAtual.status;
  status.disabled = !podeEditar;

  const proxima = PROXIMA_ETAPA[ordemAtual.status];
  const avancar = el('btn-avancar');
  avancar.hidden = !proxima || !podeEditar;
  if (proxima) avancar.innerHTML = `<i class="bi ${STATUS[proxima].icone}"></i> Marcar como ${STATUS[proxima].rotulo.toLowerCase()}`;

  const historico = await listarHistorico(ordemAtual.id);
  el('historico').innerHTML = historico
    .map(
      (h) => `
      <li>
        <span class="ponto bg-${STATUS[h.status_novo].cor}"></span>
        <div><strong>${STATUS[h.status_novo].rotulo}</strong></div>
        <div class="text-secondary small">${dataHora.format(new Date(h.criado_em))}${h.usuario?.nome ? ` · ${esc(h.usuario.nome)}` : ''}</div>
      </li>`,
    )
    .join('');
}

async function mudarEtapa(novo) {
  if (!ordemAtual || novo === ordemAtual.status) return;
FIM_ARQUIVO_PW

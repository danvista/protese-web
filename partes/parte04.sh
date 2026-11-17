cat >> "js/paginas/ordens.js" <<'FIM_ARQUIVO_PW'
  if (novo === 'CANCELADO' && !confirm(`Cancelar a OS #${ordemAtual.numero}?`)) {
    el('status').value = ordemAtual.status;
    return;
  }
  esconderAlerta(alerta);
  try {
    await alterarStatusOrdem(ordemAtual.id, novo);
    mostrarToast(`OS #${ordemAtual.numero}: ${STATUS[novo].rotulo}.`);
    await carregar();
    await abrirOrdem(ordemAtual.id);
  } catch (erro) {
    el('status').value = ordemAtual.status;
    mostrarAlerta(alerta, 'danger', erro.message);
  }
}

el('status').addEventListener('change', (e) => mudarEtapa(e.target.value));
el('btn-avancar').addEventListener('click', () => mudarEtapa(PROXIMA_ETAPA[ordemAtual.status]));

ligarFormulario(form, {
  alerta,
  validacaoExtra: (f) => {
    const desconto = lerMoeda(f.elements.desconto.value);
    f.elements.desconto.setCustomValidity(desconto !== null && (Number.isNaN(desconto) || desconto < 0) ? 'inválido' : '');
  },
  aoEnviar: async (dados) => {
    const itens = [...corpoItens.querySelectorAll('.linha-item')]
      .map((linha) => {
        const servicoId = linha.querySelector('[data-campo="servico_id"]').value;
        const item = {
          servico_id: servicoId,
          dentes: linha.querySelector('[data-campo="dentes"]').value.trim(),
          quantidade: Number(linha.querySelector('[data-campo="quantidade"]').value) || 1,
        };
        // Mantém o preço original de itens já lançados; os novos usam a tabela de preços do banco
        if (linha.dataset.valorOriginal && linha.dataset.servicoOriginal === servicoId) {
          item.valor_unitario = Number(linha.dataset.valorOriginal);
        }
        return item;
      })
      .filter((i) => i.servico_id);

    // Prazo às 18h do dia escolhido (horário local)
    const [ano, mes, dia] = dados.prazo.split('-').map(Number);
    const registro = {
      dentista_id: dados.dentista_id,
      paciente: dados.paciente.trim(),
      cor: dados.cor.trim() || null,
      observacoes: dados.observacoes.trim() || null,
      prazo_entrega: new Date(ano, mes - 1, dia, 18).toISOString(),
      tecnico_responsavel_id: dados.tecnico_responsavel_id || null,
    };
    if (gestor) registro.desconto = lerMoeda(dados.desconto) || 0;

    const eraNova = !ordemAtual;
    const id = await salvarOrdem(registro, itens, ordemAtual?.id);
    modal(elModal).hide();
    await carregar();
    const salva = ordens.find((o) => o.id === id);
    mostrarToast(eraNova ? `OS #${salva?.numero ?? ''} lançada.` : 'Ordem atualizada.');
  },
});

if (podeEditar) {
  el('btn-nova').hidden = false;
  el('btn-nova').addEventListener('click', () => abrirOrdem());
}

await carregar();
FIM_ARQUIVO_PW
mkdir -p "js"
cat > "js/status.js" <<'FIM_ARQUIVO_PW'
// Etapas da ordem de serviço: rótulo, cor e ícone usados em todas as telas.

export const STATUS = {
  RECEBIDO: { rotulo: 'Recebido', cor: 'secondary', icone: 'bi-inbox' },
  EM_PRODUCAO: { rotulo: 'Em produção', cor: 'primary', icone: 'bi-gear' },
  EM_PROVA: { rotulo: 'Em prova', cor: 'info', icone: 'bi-person-check' },
  RETORNO: { rotulo: 'Retorno', cor: 'warning', icone: 'bi-arrow-return-left' },
  FINALIZADO: { rotulo: 'Finalizado', cor: 'success', icone: 'bi-check2-circle' },
  ENTREGUE: { rotulo: 'Entregue', cor: 'dark', icone: 'bi-truck' },
  CANCELADO: { rotulo: 'Cancelado', cor: 'danger', icone: 'bi-x-circle' },
};

/** Etapa seguinte no fluxo normal (botão "avançar"). */
export const PROXIMA_ETAPA = {
  RECEBIDO: 'EM_PRODUCAO',
  EM_PRODUCAO: 'EM_PROVA',
  EM_PROVA: 'FINALIZADO',
  RETORNO: 'EM_PRODUCAO',
  FINALIZADO: 'ENTREGUE',
};

export const ABERTAS = ['RECEBIDO', 'EM_PRODUCAO', 'EM_PROVA', 'RETORNO', 'FINALIZADO'];

export function badgeStatus(status) {
  const s = STATUS[status];
  return `<span class="badge rounded-pill status-badge text-bg-${s.cor}"><i class="bi ${s.icone}"></i> ${s.rotulo}</span>`;
}

/** Atrasada: ainda não entregue/cancelada e prazo já passou. */
export function estaAtrasada(ordem) {
  return ABERTAS.includes(ordem.status) && new Date(ordem.prazo_entrega) < new Date();
}
FIM_ARQUIVO_PW

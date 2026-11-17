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

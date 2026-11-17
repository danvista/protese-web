// Fatura mensal do dentista para imprimir ou salvar em PDF.
import { exigirLogin, carregarPerfil, ehGestor } from '../auth.js';
import { obterLaboratorio, obterFatura, FORMAS_PAGAMENTO, SITUACAO_FATURA } from '../dados.js';
import { esc, formatarMoeda } from '../formatos.js';
import { deIso } from '../calendario.js';

const sessao = await exigirLogin();
const { perfil } = await carregarPerfil(sessao.user.id);
if (!ehGestor(perfil)) {
  location.replace('inicio.html');
  await new Promise(() => {});
}
document.body.classList.remove('carregando');

const MESES = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
const caixa = document.getElementById('fatura');
const id = new URLSearchParams(location.search).get('id');
const dataCurta = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });
const dataHora = new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
const fmtTs = (ts) => (ts ? dataCurta.format(new Date(ts)) : '—');
const fmtDia = (iso) => (iso ? dataCurta.format(deIso(iso)) : '—');
const linha = (rotulo, valor) => (valor ? `<div><span>${rotulo}</span> ${esc(valor)}</div>` : '');

try {
  if (!id) throw new Error('Fatura não informada.');
  const [lab, f] = await Promise.all([obterLaboratorio(), obterFatura(id)]);
  const comp = deIso(f.competencia);
  const nomeMes = `${MESES[comp.getMonth()]} de ${comp.getFullYear()}`;
  const numero = `${comp.getFullYear()}${String(comp.getMonth() + 1).padStart(2, '0')}`;
  const saldo = Math.max(Number(f.valor_total) - Number(f.valor_pago), 0);
  const sit = SITUACAO_FATURA[f.status];
  document.title = `Fatura ${nomeMes} - ${f.dentista.nome} | ${lab.nome}`;
  document.getElementById('btn-voltar').href = `financeiro.html?mes=${f.competencia.slice(0, 7)}`;

  const linhasOs = f.ordens
    .map(
      (o) => `
      <tr>
        <td class="text-nowrap"><strong>#${o.numero}</strong></td>
        <td class="text-nowrap">${fmtTs(o.data_entrega)}</td>
        <td>${esc(o.paciente)}
          <ul class="fatura-servicos detalhe">
            ${(o.itens ?? [])
              .map((it) => `<li>${it.quantidade > 1 ? `${it.quantidade}× ` : ''}${esc(it.servico?.nome)}${it.dentes ? ` <span>(${esc(it.dentes)})</span>` : ''}</li>`)
              .join('')}
            ${Number(o.desconto) ? `<li><span>Desconto: - ${formatarMoeda(o.desconto)}</span></li>` : ''}
          </ul>
        </td>
        <td class="text-end text-nowrap">${formatarMoeda(o.valor_total)}</td>
      </tr>`,
    )
    .join('');

  caixa.innerHTML = `
    <header class="nota-cabecalho">
      <div class="nota-lab">
        ${lab.logo_url ? `<img src="${esc(lab.logo_url)}" alt="" class="nota-logo">` : ''}
        <div>
          <h1>${esc(lab.nome)}</h1>
          <div class="nota-lab-dados">
            ${linha('', lab.documento ? `CNPJ/CPF: ${lab.documento}` : '')}
            ${linha('', [lab.endereco, lab.cidade].filter(Boolean).join(' · '))}
            ${linha('', [lab.telefone, lab.email].filter(Boolean).join(' · '))}
          </div>
        </div>
      </div>
      <div class="nota-numero">
        <span>Fatura</span>
        <strong>${MESES[comp.getMonth()].replace(/^./, (c) => c.toUpperCase())}/${comp.getFullYear()}</strong>
        <small>Nº ${numero}-${String(f.id).slice(0, 4).toUpperCase()}</small>
      </div>
    </header>

    <section class="nota-blocos fatura-blocos">
      <div class="nota-bloco">
        <h2>Cliente</h2>
        <strong>${esc(f.dentista.nome)}</strong>
        ${linha('CRO:', f.dentista.cro)}
        ${linha('Clínica:', f.dentista.clinica)}
        ${linha('Telefone:', f.dentista.telefone)}
        ${linha('E-mail:', f.dentista.email)}
        ${linha('Endereço:', f.dentista.endereco)}
      </div>
      <div class="nota-bloco">
        <h2>Referência</h2>
        <strong>Trabalhos entregues em ${nomeMes}</strong>
        <div><span>Ordens:</span> ${f.ordens.length}</div>
        <div><span>Emissão:</span> ${dataCurta.format(new Date())}</div>
      </div>
      <div class="nota-bloco bloco-vencimento">
        <h2>Vencimento</h2>
        <strong class="fs-5">${fmtDia(f.vencimento)}</strong>
        <div class="situacao situacao-${f.status.toLowerCase()}">${sit.rotulo}</div>
      </div>
    </section>

    <table class="nota-tabela">
      <thead>
        <tr>
          <th style="width:4.5rem">OS</th>
          <th style="width:6.5rem">Entrega</th>
          <th>Paciente <span class="detalhe">/ serviços</span></th>
          <th class="text-end" style="width:8rem">Valor</th>
        </tr>
      </thead>
      <tbody>${linhasOs || '<tr><td colspan="4" class="text-center text-secondary py-3">Nenhuma OS nesta fatura.</td></tr>'}</tbody>
    </table>

    <section class="nota-totais">
      <div><span>Total dos trabalhos</span><span>${formatarMoeda(f.valor_total)}</span></div>
      ${Number(f.valor_pago) ? `<div><span>Já pago</span><span>- ${formatarMoeda(f.valor_pago)}</span></div>` : ''}
      <div class="nota-total"><span>${saldo ? 'Total a pagar' : 'Fatura quitada'}</span><span>${formatarMoeda(saldo)}</span></div>
    </section>

    ${f.pagamentos.length ? `
    <section class="nota-obs">
      <h2>Pagamentos recebidos</h2>
      ${f.pagamentos.map((p) => `<div>${fmtDia(p.data)} · ${FORMAS_PAGAMENTO[p.forma] ?? p.forma} · <strong>${formatarMoeda(p.valor)}</strong>${p.observacao ? ` · ${esc(p.observacao)}` : ''}</div>`).join('')}
    </section>` : ''}

    ${lab.dados_pagamento && saldo ? `
    <section class="nota-obs fatura-pagamento">
      <h2>Como pagar</h2>
      <p>${esc(lab.dados_pagamento)}</p>
    </section>` : ''}

    <footer class="nota-rodape">Emitida em ${dataHora.format(new Date())} · ${esc(lab.nome)}</footer>`;
} catch (erro) {
  caixa.innerHTML = `<div class="alert alert-danger m-4">${esc(erro.message)}</div>`;
}

const chave = document.getElementById('mostrar-servicos');
const aplicar = () => caixa.classList.toggle('sem-detalhe', !chave.checked);
chave.addEventListener('change', aplicar);
aplicar();

document.getElementById('btn-imprimir').addEventListener('click', () => window.print());

cat >> "css/estilo.css" <<'FIM_ARQUIVO_PW'
  background: #fff;
  border: 1px solid rgba(16, 24, 40, 0.06);
  border-left: 4px solid var(--borda, #d0d5dd);
  border-radius: var(--raio);
  padding: 0.9rem 1rem;
  box-shadow: var(--sombra-1);
  animation: surgirEscala 0.4s var(--ease) both;
  transition: transform 0.25s var(--ease), box-shadow 0.25s var(--ease);
}

.cartao-os:hover {
  transform: translateY(-3px);
  box-shadow: var(--sombra-2);
}

.cartao-os:focus-visible {
  outline: 3px solid rgba(79, 70, 229, 0.4);
  outline-offset: 2px;
}

.borda-secondary { --borda: #98a2b3; }
.borda-primary { --borda: var(--cor-primaria); }
.borda-info { --borda: #0ea5e9; }
.borda-warning { --borda: #f59e0b; }
.borda-success { --borda: #16a34a; }
.borda-dark { --borda: #344054; }
.borda-danger { --borda: #dc2626; }

.cartao-os.atrasada {
  background: linear-gradient(0deg, #fff, #fff6f6);
}

.numero-os {
  font-weight: 700;
  color: #667085;
  font-variant-numeric: tabular-nums;
}

.cartao-os .paciente {
  font-weight: 600;
  font-size: 1.05rem;
  margin-top: 0.25rem;
}

.servicos-os {
  color: #475467;
}

.cor-dente {
  position: absolute;
  right: 1rem;
  bottom: 2.6rem;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.1rem 0.45rem;
  border-radius: 0.4rem;
  background: #fdf6e3;
  color: #8a6d1d;
  border: 1px solid #f1e3b5;
}

.status-badge {
  font-weight: 500;
  font-size: 0.75rem;
}

.cartao-os.esqueleto {
  border-left-color: #e4e7ec;
  background: linear-gradient(90deg, #f2f4f7 0px, #fafbfc 120px, #f2f4f7 240px) 0 0 / 800px 100%;
  animation: brilho 1.2s linear infinite;
}

.tabela-itens .item-novo {
  animation: surgir 0.3s var(--ease) both;
}

.tabela-itens .item-saindo {
  animation: sair 0.25s ease-in forwards;
}

.modo-tecnico .so-gestor {
  display: none !important;
}

/* Linha do tempo do histórico */
.linha-tempo {
  list-style: none;
  padding: 0;
  margin: 0;
  position: relative;
}

.linha-tempo li {
  position: relative;
  padding: 0 0 0.9rem 1.4rem;
  animation: surgir 0.35s var(--ease) both;
}

.linha-tempo li::before {
  content: '';
  position: absolute;
  left: 0.32rem;
  top: 0.9rem;
  bottom: 0;
  width: 2px;
  background: #e4e7ec;
}

.linha-tempo li:last-child::before {
  display: none;
}

.linha-tempo .ponto {
  position: absolute;
  left: 0;
  top: 0.35rem;
  width: 0.75rem;
  height: 0.75rem;
  border-radius: 50%;
  box-shadow: 0 0 0 3px #fff;
}
FIM_ARQUIVO_PW

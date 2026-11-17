cat > "LEIA-ME.md" <<'FIM_ARQUIVO_PW'
# Protese Web — HTML + CSS + JavaScript + Supabase

Sem build e sem instalar nada: Bootstrap 5, Bootstrap Icons e supabase-js vêm por CDN.

## 1. Configurar o Supabase

1. Crie o projeto no Supabase e rode a migration `supabase/migrations/20261116000000_estrutura_inicial.sql`
   (pelo **SQL Editor** do painel, colando o arquivo, ou com `supabase db push`).
2. Em **Project Settings > API**, copie a URL e a chave pública (anon/publishable) para `js/config.js`.
3. Em **Authentication > URL Configuration**:
   - Site URL: o endereço onde o sistema vai rodar (ex.: `http://localhost:5500`)
   - Redirect URLs: `<endereço>/entrar.html` e `<endereço>/redefinir-senha.html`
4. Em **Authentication > Sign In / Providers > Email**, deixe "Confirm email" ligado.

## 2. Rodar no computador

Os scripts usam módulos (`type="module"`), então a página precisa ser aberta por um servidor local, não com duplo clique no arquivo:

- VS Code: extensão **Live Server** → botão "Go Live"; ou
- Terminal: `npx serve .` ou `python -m http.server 5500`

## 3. Publicar de graça

Qualquer hospedagem de site estático serve: Netlify, Cloudflare Pages, GitHub Pages ou Vercel. Basta enviar a pasta.
Depois, atualize a Site URL e as Redirect URLs no Supabase com o domínio final.

## Estrutura

```
index.html               redireciona para inicio.html
entrar.html              login
cadastro.html            cria o laboratório (teste de 30 dias)
recuperar-senha.html     envia link por e-mail
redefinir-senha.html     destino do link do e-mail
inicio.html              área logada (painel do dia virá aqui)
css/estilo.css
js/
  config.js              URL e chave do Supabase
  supabase.js            cliente Supabase
  auth.js                login, cadastro, sessão, perfil, exigirLogin / exigirVisitante
  ui.js                  alertas, botão carregando, validação de formulários
  layout.js              topo, menu e aviso de teste da área logada
  paginas/               um script por página
supabase/
  migrations/            estrutura do banco + RLS
  testes_rls.sql         testes de isolamento e permissões
```

## Padrão para novas páginas da área logada

1. Copie `inicio.html` (mantém `<body class="carregando">`, `#topo` e `#aviso-assinatura`).
2. Crie `js/paginas/<nome>.js` começando com:
   ```js
   import { iniciarAreaLogada } from '../layout.js';
   const { perfil, laboratorio } = await iniciarAreaLogada('<id-do-menu>');
   ```
3. Adicione o item no array `MENU` em `js/layout.js`.

Dados do usuário são sempre inseridos com `textContent`, nunca com `innerHTML`.
FIM_ARQUIVO_PW
cat > "cadastro.html" <<'FIM_ARQUIVO_PW'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Criar conta | Protese Web</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="css/estilo.css">
</head>
<body>
  <main class="auth-pagina">
    <div class="card shadow-sm auth-card">
      <div class="card-body p-4">
        <div class="auth-marca mb-1"><i class="bi bi-box-seam"></i> Protese Web</div>

        <!-- Mostrado depois do cadastro, quando falta confirmar o e-mail -->
        <div id="sucesso" hidden>
          <p class="text-secondary">Quase lá!</p>
          <div class="alert alert-success">
            Enviamos um link de confirmação para <strong id="email-enviado"></strong>.
            Abra seu e-mail e clique no link para ativar sua conta.
          </div>
          <p class="text-center small mb-0"><a href="entrar.html">Voltar para o login</a></p>
        </div>

        <div id="etapa-formulario">
          <p class="text-secondary mb-4">Crie a conta do seu laboratório. 30 dias grátis, sem cartão.</p>

          <div id="alerta" hidden role="alert"></div>

          <form id="form-cadastro" class="vstack gap-3" novalidate>
            <div>
              <label for="nome" class="form-label">Seu nome</label>
              <input type="text" class="form-control" id="nome" name="nome" autocomplete="name" maxlength="120" required>
              <div class="invalid-feedback">Informe seu nome.</div>
            </div>

            <div>
              <label for="nomeLaboratorio" class="form-label">Nome do laboratório</label>
              <input type="text" class="form-control" id="nomeLaboratorio" name="nomeLaboratorio" autocomplete="organization" maxlength="120" required>
              <div class="invalid-feedback">Informe o nome do laboratório.</div>
            </div>

            <div>
              <label for="email" class="form-label">E-mail</label>
              <input type="email" class="form-control" id="email" name="email" autocomplete="email" required>
              <div class="invalid-feedback">Informe um e-mail válido.</div>
            </div>

            <div>
              <label for="senha" class="form-label">Senha</label>
              <div class="input-group has-validation">
                <input type="password" class="form-control" id="senha" name="senha" autocomplete="new-password" minlength="8" required>
                <button class="btn btn-outline-secondary" type="button" data-alternar-senha="senha" aria-label="Mostrar senha">
                  <i class="bi bi-eye"></i>
                </button>
                <div class="invalid-feedback">A senha precisa ter pelo menos 8 caracteres.</div>
              </div>
            </div>

            <div>
              <label for="confirmacao" class="form-label">Confirme a senha</label>
              <input type="password" class="form-control" id="confirmacao" name="confirmacao" autocomplete="new-password" required>
              <div class="invalid-feedback">As senhas não conferem.</div>
            </div>

            <button type="submit" class="btn btn-primary w-100">Criar conta</button>
          </form>

          <p class="text-center text-secondary small mt-4 mb-0">
            Já tem conta? <a href="entrar.html">Entrar</a>
          </p>
        </div>
      </div>
    </div>
  </main>

  <script type="module" src="js/paginas/cadastro.js"></script>
</body>
</html>
FIM_ARQUIVO_PW
mkdir -p "css"
cat > "css/estilo.css" <<'FIM_ARQUIVO_PW'
:root {
  --cor-fundo: #f4f6f8;
}

body {
  background: var(--cor-fundo);
  min-height: 100vh;
}

/* Evita "piscar" a página logada antes de confirmar a sessão */
body.carregando {
  visibility: hidden;
}

/* ---------- Telas de autenticação ---------- */
.auth-pagina {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
}

.auth-card {
  width: 100%;
  max-width: 26rem;
}

.auth-marca {
  font-weight: 700;
  font-size: 1.25rem;
}

.auth-marca .bi {
  color: var(--bs-primary);
}

/* ---------- Área logada ---------- */
.conteudo {
  max-width: 80rem;
  margin: 0 auto;
  padding: 1.5rem;
}

/* ---------- Listas ---------- */
.busca {
  max-width: 22rem;
}

.col-acoes {
  width: 1%;
  white-space: nowrap;
}

.texto-curto {
  max-width: 18rem;
}

.preco-especial {
  max-width: 10rem;
  margin-left: auto;
}

.aviso-wrapper {
  max-width: 80rem;
  margin: 1rem auto 0;
  padding: 0 1.5rem;
}
FIM_ARQUIVO_PW

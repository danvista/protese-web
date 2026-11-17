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

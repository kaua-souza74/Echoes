# Validação V2.2 — Recovery & Completion

## Estado por categoria

| Categoria | Evidência / limite |
| --- | --- |
| Implementado | Auth Supabase, rotas protegidas, menus, missões, perfil, conquistas, ranking PostgreSQL, preferências, memórias e integração dos eventos Flame. |
| Testado localmente | Última suíte completa: 37 testes passaram. `flutter analyze --no-pub`: sem issues; após tornar a configuração padrão, `dart analyze` nos arquivos alterados também passou. `flutter run -d chrome` compilou e iniciou o app sem `--dart-define`. 19 verificações PostgreSQL com PGlite usando o SQL combinado. |
| Validado no Supabase remoto | O responsável aplicou o SQL. Auth respondeu HTTP 200; cadastro por e-mail está ligado e `mailer_autoconfirm=true`. REST retornou os dados seed de stages, collectibles, memory_entries, learning_checks e achievements. Leituras anônimas de tabelas privadas foram negadas como esperado. Cadastro/login e RPCs autenticadas ainda não foram testados com conta real. |
| Pendente de aprovação | Nenhuma solicitação de ferramenta pendente. |
| Pendente | Cadastro/login e RPCs autenticadas com contas reais; acesso administrativo do conector; build Windows exige suporte a links simbólicos no ambiente. |

## Comandos reproduzíveis

No diretório flutter_app:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub --no-wasm-dry-run
flutter build windows --no-pub
```

Na raiz:

```powershell
python supabase/tools/generate_memory_seed.py
cd supabase/qa
npm ci
node verify.mjs
```

PGlite executa PostgreSQL com auth.uid e duas identidades locais simuladas. Não valida Supabase Auth, PostgREST ou políticas efetivamente hospedadas. Relatório: supabase/qa/report.json.

## Cobertura

- Auth: cadastro com confirmação, login, restauração/expiração, logout e redirect protegido.
- Contas: limpeza de snapshot/fila, resposta tardia de A descartada ao entrar em B, preferências e aprendizagem independentes.
- Gameplay: IDs reais de coleta, início da tentativa, resultado único e speedrun invalidado ao pausar; regressões dos três capítulos preservadas.
- SQL: RLS cruzada, acesso anônimo, escrita indevida em pontos/conquistas, recompensas únicas, requisitos de conclusão, melhores tempos, empate, versões e ranking combinado.
- Produto: navegação, missão/perfil/logout, conteúdo bloqueado no arquivo, resposta educativa e telas estreitas com texto ampliado.
- Produção Web: /profile sem sessão redireciona a /login; validação de campos vazios em login/cadastro; capturas limpas em docs/screenshots/v22_*_web.jpg. Nenhuma conta enviada nesses testes. Nenhum erro/warning no console observado nessa inspeção.

## Builds

Web compilado com sucesso. Aviso não fatal preexistente de CupertinoIcons; ícones Material foram inspecionados. Preview em http://127.0.0.1:18768/ usa fallback para index.html e cache desabilitado, sem publicação externa.

Windows foi executado e bloqueado antes da compilação por “Building with plugins requires symlink support”. Habilitar Developer Mode depende do responsável pela máquina; não foi alterado. O executável V2.1 existente não representa esta atualização. Android não foi validado.

## Aceitação remota ainda obrigatória

Seguir SUPABASE_SETUP.md para conferir redirects de Auth e então validar o fluxo autenticado no projeto já instalado. Depois:

1. Criar e confirmar dois e-mails reais, A e B.
2. Entrar com A, iniciar/concluir o Despertar, coletar Ecos e salvar preferências.
3. Repetir conclusão/coleta: pontos e conquistas não podem duplicar.
4. Sair e entrar com B: progresso e preferências de A não aparecem.
5. Concluir uma fase com B; verificar ranking de ambos, sem e-mails.
6. Tentar leitura/escrita cruzada, pontos arbitrários e concessão direta de conquista: negar.
7. Sair e entrar novamente nas duas contas; verificar memórias, respostas educativas, progresso e preferências.
8. Verificar melhor tempo, pausa, tentativa incompleta, versões e combinado elegível apenas com três fases.
9. Testar confirmação, recuperação de senha, sessão expirada e interrupção de rede.
10. Executar advisors e conferir permissões/RLS no projeto hospedado.

A integração completa não está aprovada até essa sequência passar. Tempos continuam não verificados competitivamente; a fila offline é apenas em memória.

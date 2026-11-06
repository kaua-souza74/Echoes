# Supabase V2.2 — instalação e estado real

## Estado

URL e chave pública anon do projeto ficam como padrões do app em `lib/app/supabase_config.dart`; `--dart-define` pode sobrescrevê-los. Supabase Flutter 2.18.3 usa `publishableKey` e aceita a chave anon legacy. O validador rejeita chaves administrativas e divergência entre project ref e JWT anon.

Em 06/11/2026, Auth respondeu HTTP 200: `disable_signup=false`, `external.email=true` e `mailer_autoconfirm=true`. Leituras REST públicas retornaram dados de `stages` (`stage_01`), `collectibles` (`echo_01`), `memory_entries` (`memory_echo_01`), `learning_checks` (`check_stage_01`) e `achievements` (`first_awakening`). Tabelas de usuário recusaram acesso anônimo com `42501`, conforme grants/RLS esperados.

O responsável confirmou a execução do SQL completo. O conector Supabase continua sem permissões administrativas para projeto, tabelas, migrations, logs e advisors. O teste de sessão autenticada e das RPCs com uma conta real ainda está pendente.

## Aplicação remota confirmada

As leituras públicas confirmam o schema, o seed e as permissões de catálogo. A tentativa anônima nas tabelas privadas confirmou que elas não estão abertas ao papel `anon`. Como o conector administrativo não está autorizado, ainda não foi possível ler advisors nem executar o fluxo de cadastro/login e RPCs com uma sessão autenticada. Não reaplique o bundle em caso de dúvida sem antes inspecionar o projeto.

Para instalar em outro projeto, execute primeiro `supabase/qa/preflight_remote.sql`, compare objetos existentes e aplique [ECHOES_V2.2_FULL_SETUP.sql](../supabase/ECHOES_V2.2_FULL_SETUP.sql) somente após verificar compatibilidade. O arquivo combina migration e seed em uma transação e não apaga tabelas nem dados de jogadores.

A migration e o SQL combinado passaram por 19 verificações locais em PostgreSQL via PGlite. `supabase/tools/build_full_setup_sql.py` reproduz o arquivo combinado; `supabase/qa/verify.mjs` executa esse arquivo completo no banco local de teste. Em instalações futuras, rode o preflight e reconcilie qualquer tabela homônima antes de colar o bundle.

## API

Mantenha private **fora dos Exposed schemas**. O app chama wrappers públicos SECURITY INVOKER:

- echoes_bootstrap / echoes_player_state: perfil inicial e snapshot da própria conta.
- echoes_start_stage: UUID, fase, versão e modo, com verificação de acesso.
- echoes_collect_echo: tentativa própria e ID válido para a fase.
- echoes_record_stage_run: fatos da tentativa e coletáveis; pontos não são parâmetro.
- echoes_record_dialogues / echoes_answer_learning_check: progresso narrativo e resposta.
- echoes_leaderboard: categoria e fase; só devolve posição, UUID público, apelido e resultado.

Funções privilegiadas ficam em private, com auth.uid obrigatório, search_path vazio e EXECUTE retirado de PUBLIC/anon. Wrappers e funções necessárias são concedidos somente a authenticated. RLS protege dados por proprietário; pontos e conquistas não permitem escrita arbitrária do cliente. E-mails não aparecem nas consultas públicas.

Todos os tempos do cliente recebem verified=false. Limites, versão, início de servidor e idempotência são verificações básicas; não constituem proteção autoritativa contra trapaças.

## Confirmação e recuperação

Configure Site URL e Redirect URLs no Dashboard. O campo opcional de build SUPABASE_AUTH_REDIRECT_URL deve conter uma URL Web permitida. Sem ele, vale a configuração do projeto.

O SQL não altera as opções do serviço Supabase Auth. O endpoint público reportou `mailer_autoconfirm=true`; confira no Dashboard se esse comportamento é o desejado e teste o recebimento de e-mail antes de depender de confirmação ou recuperação.

O Web usa caminhos do GoRouter e exige fallback para index.html. tools/serve_web.py faz isso em 127.0.0.1. Retorno por esquema URI próprio no Windows não foi configurado: confirmação pode ocorrer no navegador, seguida do login nativo. Recuperação pode usar o host Web permitido.

O SDK persiste sessão; getUser a revalida ao abrir o app. Logout limpa snapshot/fila privados e encerra a sessão local. A fila atual não sobrevive ao fechamento.

## Executar

```powershell
cd flutter_app
flutter run
```

O app carrega a URL e a chave anon padrão sem flags. Se o Flutter listar vários dispositivos e pedir seleção, use `flutter run -d chrome` para abrir no navegador. No ambiente de validação estavam conectados Windows, Chrome e Edge.

Service role, secret key e senha do proprietário não são necessárias no cliente e não devem ser colocadas nele.

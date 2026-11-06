# ECHOES — expansão V2

## Auditoria de 26/10/2026

O projeto Flutter existente usa Flame 1.35.1 e Dart 3.10.8. Há movimento determinístico a 120 Hz, seis animações do Errante, câmera 640×360, quatro superfícies no slice legado, checkpoint, Eco, conclusão local e teclado/touch. Art Pass 2 já está integrado: seis layers do Despertar, O Ouvinte, duas mariposas e poeira. As áreas 2 e 3 têm apenas placas artísticas. Não havia autenticação, persistência, navegação de aplicativo, cronômetro competitivo ou banco de dados.

O teste de parallax ainda esperava quatro fatores antigos; foi atualizado para conferir os seis fatores reais. O GDD original e os assets existentes foram preservados.

## Marco B/C — fase expandida e narrativa

O aplicativo passa a carregar `assets/levels/stage_01.json`, schema 2, com 11.776×1.024 pixels, 34 superfícies na rota principal e 20 nas rotas opcionais. Cinco seções conectadas: Primeiro Suspiro, Ruínas Silenciosas, Ponte Esquecida, Coração Adormecido e A Passagem. Sete Ecos; o Coração é necessário para o farol final, os outros recompensam exploração. Cinco checkpoints monotônicos. As quatro primeiras superfícies do slice original permanecem no início.

O slice legado continua disponível por `EchoesGame(slice: true)` e tem teste de regressão próprio. A física e seus parâmetros foram mantidos. Tiles fora do viewport deixam de ser enviados ao canvas. As dimensões são conteúdo autorado em JSON, não centenas de posições na lógica de jogo.

Quatro sequências narrativas originais usam controlador de digitação, primeiro toque para revelar, avanço com debounce de 120 ms, pular e revisão pela pausa. O retrato transparente flutua fora da borda superior do painel. Durante diálogo, a física fica congelada e o backdrop continua animado. As entradas são limpas ao bloquear o jogador. Memórias vistas sobrevivem a reinícios da tentativa, mas somente durante a sessão atual.

## Limites deste marco

A meta de 4–6 minutos da fase 1 não foi medida em playtest humano. O mapa expandido requer avaliação de ritmo e de descobertas opcionais. A conclusão informa as Galerias, mas ainda não inicia uma segunda fase. O dash continua disponível como no slice; o desbloqueio narrativo na fase 2 depende dessa implementação.

Antes de bloquear o dash até a fase 2, será necessário retunar os vãos da fase 1 e executar novamente as travessias sem essa habilidade: o slice preservado e parte dos saltos atuais a utilizam. Desabilitá-la sem esse ajuste quebraria a progressão.

As etapas D–I do pedido V2 continuam abertas: fases 2/3 jogáveis, plataformas temporárias, espetáculo colossal, navegação/menus, autenticação Supabase, persistência por conta, speedrun, rankings, conquistas e configurações. Não há qualquer alegação de jogo V2 completo.

## Arquivos deste marco

| Grupo | Arquivos |
|---|---|
| Conteúdo | `flutter_app/assets/levels/stage_01.json`, `assets/narrative/dialogues.json`, `assets/images/narrative/memory_portrait.png` |
| Pipeline | `art_pipeline/scripts/build_stage01_expansion.py`, `art_pipeline/README.md` |
| Narrativa | `lib/dialogue/dialogue_controller.dart`, `dialogue_overlay.dart` |
| Integração | `lib/game/echoes_game.dart`, `art/game_assets.dart`, `levels/level_data.dart`, `levels/ruins_level.dart`, `systems/level_progress.dart`, `hud/hud_state.dart`, `screens/game_screen.dart`, `pubspec.yaml` |
| Testes novos | `dialogue_test.dart`, `expanded_stage_test.dart`, `stage_routes_test.dart` |
| Regressão adaptada | `vertical_slice_test.dart` carrega explicitamente o slice legado; `progression_input_camera_test.dart` confere as seis layers atuais |
| Documentação | READMEs, GAMEPLAY_HANDOFF, ART_HANDOFF, ASSET_MANIFEST, ARCHITECTURE, SUPABASE_SETUP, DEVELOPMENT_LOG e TEST_PLAN |

O formatador também normalizou o arquivo existente `camera/parallax_backdrop.dart`, sem mudança de comportamento.

## Verificação local

`flutter test --no-pub --reporter expanded`: **16 testes aprovados**. O teste montado percorreu o mapa do início ao farol final com zero mortes, recuperou o Coração e atravessou as quatro sequências narrativas. Os cinco desvios foram conferidos salto a salto pelo mesmo solver; os sete Ecos ficam em alcance das superfícies. A regressão do slice original continua passando.

`flutter analyze --no-pub`: sem problemas encontrados. O overlay foi verificado em 1280×720 e 480×800, com entrada real de teclado, botão de pular e retrato acima do painel. A duração humana e o conforto do mapa ainda exigem playtest; os testes não provam a meta de 4–6 minutos.

Build Web release concluído em `flutter_app/build/web` e Windows release em `flutter_app/build/windows/x64/runner/Release/echoes.exe`. O Web ainda emite o aviso não fatal anterior sobre a família CupertinoIcons; a tela renderizou corretamente. No navegador, foram conferidos avanço, digitação, pular, liberação dos controles, pausa e replay de memória, sem erros de console. Captura real: `docs/screenshots/v2_dialogue_web.jpg`. O Windows foi compilado, sem novo playtest manual nativo; copie a pasta Release inteira para distribuir.

O service worker do preview pode carregar primeiro a versão anterior; recarregue após a atualização do cache. O HUD do novo mapa mostra sete Ecos e o nome da seção O Primeiro Suspiro. A captura `expanded_dialogue_test.png` é do Flutter Test e usa sua fonte de teste; não a confunda com a captura Web.


## V2.1 — WORLD EXPANSION, 26/10/2026
Auditoria confirmou carregamento fixo da fase 1 e estudos de ambiente 02/03 disponíveis. Foram criados os mapas schema 3, catálogo, configuração de câmera/parallax XY, plataformas temporárias, atores/eventos ambientais, transições provisórias e modelo local de tentativas. Física, sprites do Errante e GDD original preservados; nenhuma configuração de Supabase ou credencial alterada.

Galerias: cinco seções, 30 sólidos permanentes, quatro temporárias, cinco checkpoints, sete Ecos e cinco sequências. Torre: cinco seções, 53 sólidos permanentes, quatro temporárias, cinco checkpoints, sete Ecos e cinco sequências. Dois atlas novos, duas overlays de névoa e três criaturas animadas autorais; os seis estudos de fundo foram integrados como layers reais.

Durante QA, uma varanda bloqueava o salto principal das Galerias e foi encurtada. O nicho da Torre foi reposicionado para viabilizar entrada e retorno. O piloto de teste passou a soltar pulo entre contatos de wall jump e a entrar no nicho por queda controlada. Nenhum ajuste na física foi necessário. O renderer recorta células parciais para não desenhar paredes além do colisor. Capturas do teste pausado exigiram repaint explícito; todas foram regeneradas e revisadas por região.

Verificações: 25 testes aprovados (16 anteriores + 9 novos), analyze sem problemas; builds Windows e Web concluídas. Travessias reais de ambas as fases terminaram com zero mortes, Ecos exigidos e cinco sequências vistas por fase. Testes de geometria/IDs/arquivos, ciclo das temporárias, relógio/registros imutáveis, rotas opcionais e transição/isolation também passaram. As capturas do harness usam fonte Ahem; não representam a tipografia Web.

Não foi medido tempo humano de primeira conclusão, nem desempenho em dispositivo móvel. Windows tem build confirmada, sem playtest nativo. Não há áudio novo ou persistência fora da sessão. Próximo marco: menus finais e repositórios/Supabase com autenticação, RLS e validação idempotente de progresso; definir política competitiva de tempo antes de ranking.


### Revisão Web V2.1
A build atual foi conferida no navegador em `http://127.0.0.1:18767/`: pausa, seletor com três capítulos, registros reais de tentativas interrompidas, carregamento de Galerias e Torre, seus fundos e diálogos próprios. Nenhum erro/warning de console foi observado nessa revisão. Capturas reais com tipografia de produção: `screenshots/v21_galleries_web.png` e `screenshots/v21_tower_web.png`. A travessia completa é evidência do harness de física, não foi repetida manualmente no navegador.

O endereço antigo 18766 apresentou a build anterior por cache. A primeira tentativa de servidor dentro do sandbox não ficou acessível; o preview atual usa servidor Python fora do sandbox, limitado a 127.0.0.1. Não houve publicação externa. O build Web mantém o aviso não fatal preexistente sobre CupertinoIcons; os controles Material e a tipografia foram conferidos visualmente.

## V2.2 — auditoria e base da atualização Legacy (30/10/2026)

### Auditoria

- Reutilizáveis: três mapas schema 3 com 21 IDs estáveis; seis animações do Errante; física, câmera, parallax, diálogos com retrato PNG RGBA, controles touch/teclado, `LevelProgress`, `AttemptClock`, `RunRecord` e `PlaySession`.
- Dependências confirmadas no projeto: Flutter 3.38.9/Dart 3.10.8 e Flame 1.35.1. Não havia GoRouter nem `supabase_flutter` no `pubspec.yaml`; `supabase_flutter` 2.17.2 existe no cache. GoRouter não está no cache.
- Lacunas: inicialização direta da fase; seleção provisória permite todas as fases; nenhum login, sessão, dados persistentes por usuário, menus de jogo, perfil, memórias ou settings; diálogo/progresso só vive na sessão; não há esquema de pontuação ou ranking.
- Risco externo: o conector Supabase devolveu falta de permissão para o projeto indicado. O schema remoto e Auth settings não foram inspecionados; nenhuma migration remota foi aplicada. A chave pública e a URL foram colocadas em arquivo ignorado, mas ainda aguardam teste de correspondência e autenticação.
- Ordem e critérios detalhados em `docs/ARCHITECTURE.md`, `docs/SUPABASE_SETUP.md` e `docs/TEST_PLAN.md`.

### Implementado neste marco

- Esquema local aditivo em `supabase/migrations/20261030120000_echoes_v22_legacy_update.sql`: catálogo das fases e 21 Ecos, memórias, conquistas, progresso por usuário, tentativas, recordes por versão, ledger de pontos idempotente, settings, RLS e RPCs autenticadas.
- Catálogo educacional original dos 21 Ecos e uma interação com feedback por capítulo em `flutter_app/assets/narrative/memory_catalog.json`; tela de arquivo com filtro por capítulo, detalhes, fragmentos bloqueados e feedback; descoberta e aprovação de interação ficam apenas na sessão. Cada fase aborda fontes/memória, patrimônio material/imaterial e preservação participativa. O catálogo ainda reutiliza a ilustração do Eco e não há persistência remota.
- Documentação criada/atualizada: desenho educacional e fontes IPHAN/UNESCO, regras de ranking, setup Supabase, plano de testes, auditoria arquitetural e README.
- Configuração local Supabase ignorada pelo Git. A aplicação no banco segue pendente até revisar o schema existente com o responsável do projeto.

### Validação e pendências

Não foram confirmados testes ou build novos naquele primeiro marco. Esse estado foi sucedido pela recuperação abaixo; os limites remotos continuam explícitos.

## V2.2 — Recovery & Completion, 30/10/2026 · validação final 06/11/2026

### Ambiente recuperado e regressões

Flutter 3.38.9/Dart 3.10.8 confirmados. Os comandos passaram pelo mecanismo normal de aprovação. A execução pelo cmd produziu saída; os processos sem saída no PowerShell foram abandonados. O baseline passou com 25 testes; dois avisos de RadioListTile foram corrigidos com RadioGroup. As dependências foram fixadas em Supabase Flutter 2.18.3, GoRouter 17.5.0, UUID 4.6.0 e Flame 1.35.1. O pub get final concluiu com exit code 0.

A integração final passou em **36 testes Flutter** e o analyze terminou com **No issues found**. O teste de gameplay inicia o carregamento do Flame dentro de runAsync, conforme o harness de teste. O dropdown de memórias usa isExpanded; o cabeçalho adapta a marca a telas estreitas e o novo teste de 360×740 com escala de texto 1.6 passa pelas rotas de produto sem overflow. Chaves de blocos foram ajustadas conforme os lints.

### Banco e segurança

A migration existente foi revisada integralmente. Corrigidos: dupla contabilização dos pontos de Ecos na recompensa de conclusão, versão do Despertar (2), validações de nulos/versões/tempos/Ecos essenciais, início prévio de tentativa, submissão final única e acesso anônimo. Um lock transacional por usuário serializa recompensas. Wrappers públicos invoker chamam funções privilegiadas no schema private não exposto, com search_path vazio e auth.uid obrigatório. A view antiga deixou de ser API pública.

Criados start-stage, coleta em tempo real, snapshot próprio e rankings PostgreSQL de pontos, Ecos, speedrun por fase e soma das três fases. Conquistas são derivadas no servidor. O seed educativo é gerado do catálogo original por supabase/tools/generate_memory_seed.py, que confirmou novamente os 21 IDs.

**19 verificações PostgreSQL locais aprovadas**, usando PGlite 0.5.13, incluindo duas identidades simuladas, RLS, proibição de escrita livre em pontos/conquistas, repetição idempotente, melhor tempo/empate, versões incompatíveis, ranking combinado, privacidade de e-mail, memórias e settings. Script e relatório: supabase/qa/verify.mjs e report.json. Isso não é uma execução no Supabase hospedado nem um teste de Supabase Auth.

Build Web final de produção concluído em `flutter_app/build/web` com config pública local; o Flutter emitiu o aviso não fatal de CupertinoIcons ausente no conjunto de fontes, enquanto MaterialIcons foi compilada. O `TEST_PLAN.md` registra os limites de build para Windows/Android e o roteiro remoto de duas contas.

### Autenticação, produto e persistência

lib/app/ contém contrato de backend, adaptador Supabase, modelos, controlador por conta, GoRouter, telas e widgets StageCard/ProgressCard/AchievementBadge/LeaderboardEntry/EchoButton. main.dart usa exclusivamente o backend real. Cadastro trata confirmação de e-mail; login valida credenciais; sessão é restaurada pelo SDK e revalidada; logout e expiração limpam dados privados. Recuperação depende do redirect permitido do projeto.

Menu, seleção, missão com objetivo/status/recompensa, perfil, conquistas, ranking, preferências e memórias possuem comportamento. Nenhum array estático substitui jogadores do ranking. As preferências funcionais têm rascunho e gravação explícita; áudio inexistente não foi exposto.

PlayRoute registra início, recebe os IDs de coleta do Flame e submete resultados com UUID. A fila é serial, em memória, com retry; snapshot só muda após confirmação. Geração de conta descarta respostas antigas, e cada tela de jogo captura seu proprietário para não enviar eventos de A na sessão B. A fila não é durável ao fechar o app ou sair. Continuar retoma capítulo, sem restaurar posição exata de sessão encerrada.

História preserva pausas e diálogos. Speedrun omite diálogos automáticos e invalida recordes ao pausar/perder foco. Tempos monotônicos e versões acompanham as tentativas; todos os tempos de cliente continuam não verificados. Não existe validação autoritativa de física.

Memórias do Reino preserva catálogo e interações originais; IDs desbloqueados e respostas passam pela conta/RPC. Retrato transparente e diálogo cinematográfico foram preservados. As memórias ainda compartilham o primeiro frame do asset existente; não foram produzidas ilustrações exclusivas.

### Estado remoto e limite de conclusão

A verificação pública de Auth respondeu: cadastro por e-mail habilitado e confirmação obrigatória. O conector recusou acesso administrativo; a introspecção REST também não foi disponibilizada à chave pública. O usuário confirmou estar sem acesso ao projeto remoto. **Nenhuma migration foi aplicada remotamente e nenhuma conta real foi criada/testada.**

SUPABASE_SETUP.md contém preflight de leitura, ordem de aplicação manual, seed, permissões e redirects. O fluxo remoto de duas contas, os advisors do projeto e as políticas efetivamente hospedadas continuam pendentes do responsável. Não há aprovação de ferramenta pendente; a limitação é acesso externo. Não houve publicação, push, exclusão remota nem modificação do GDD original.

### 06/11/2026 — diagnóstico de inicialização e SQL pronto para o Editor

O comando bare `flutter run` não passa as variáveis `SUPABASE_URL` e `SUPABASE_ANON_KEY` no build. O arquivo local ignorado existe e corresponde ao host do projeto. Com `flutter run -d web-server --web-port 18769 --dart-define-from-file=config/supabase.local.json`, a aplicação iniciou e mostrou a tela de login; captura em `docs/screenshots/v22_flutter_run_login.png`. O fallback para configuração ausente agora exibe o comando correto e tem teste automatizado.

Auth público respondeu HTTP 200 com cadastro não desabilitado, provider de e-mail habilitado e `mailer_autoconfirm=true`; nenhuma conta nem entrega de e-mail foi testada. Consulta REST de leitura a `public.stages` respondeu HTTP 404/PGRST205. O conector Supabase negou permissão administrativa para listar projeto, tabelas, histórico, logs e advisors; não houve mudança remota.

Gerado `supabase/ECHOES_V2.2_FULL_SETUP.sql`, transação única com migration e catálogo seed. `supabase/tools/build_full_setup_sql.py` reproduz o bundle. A suíte PGlite usa o bundle completo e repetiu **19 verificações aprovadas**; preflight remoto ainda é necessário para comparar tabelas homônimas. A configuração de Auth (Site URL, redirects e confirmação) é ajustada no Dashboard, não por este SQL.

### 06/11/2026 — `flutter run` sem argumentos de configuração

A URL e a chave pública anon agora são padrões em `lib/app/supabase_config.dart`; `--dart-define` continua podendo sobrescrevê-las. Removida a mensagem que obrigava a passar `--dart-define-from-file`. `dart analyze` nos arquivos alterados terminou sem issues. `flutter run` chegou ao CLI mas esta máquina tinha três alvos (Windows, Chrome e Edge), então o Flutter pediu que um dispositivo fosse escolhido; `flutter run -d chrome` iniciou o app sem configuração extra do Supabase. Os flags de build também deixaram de depender do arquivo local ignorado.

O dono confirmou a aplicação do SQL. Leituras públicas retornaram seed de `stages`, `collectibles`, `memory_entries`, `learning_checks` e `achievements`; acesso anônimo às tabelas privadas foi negado. Auth está com cadastro por e-mail ligado e confirmação automática. Ainda falta executar cadastro/login e RPCs autenticadas com uma conta real; o conector de administração permanece sem permissão.

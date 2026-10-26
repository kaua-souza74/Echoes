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

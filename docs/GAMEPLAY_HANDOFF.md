# ECHOES — Handoff de gameplay

## Expansão V2 — marco B/C

O jogo padrão agora carrega `assets/levels/stage_01.json`: 11.776×1.024 px, 34 superfícies principais, 20 opcionais, cinco checkpoints e sete Ecos. O Coração (`echo_heart`) é exigido na conclusão; os outros são opcionais. Cinco regiões: O Primeiro Suspiro, Ruínas Silenciosas, A Ponte Esquecida, O Coração Adormecido e A Passagem. O farol final está em `(11552,320)`.

O parser schema 2 carrega solids, props com IDs/labels/ordem, spawn, regiões, gatilhos e conjunto de Ecos exigidos. `EchoesGame(slice: true)` ainda carrega o trecho de quatro plataformas descrito nas seções históricas abaixo e é verificado pelo teste original. A física mantém os mesmos parâmetros.

Quatro sequências em `assets/narrative/dialogues.json` são disparadas em apoio seguro. A física pausa, as entradas são limpas e o backdrop continua atualizado. `DialogueController` mede digitação pelo delta do jogo, aplica debounce de 120 ms e transições de entrada/saída. O overlay Flutter usa retrato RGBA fora da borda do painel. Espaço/Enter/toque revelam e avançam; Esc/Pular encerra. Memórias vistas podem ser revistas na pausa e na conclusão. O estado visto é apenas da sessão.

Leia `DEVELOPMENT_LOG.md`, `ARCHITECTURE.md`, `TEST_PLAN.md` e `SUPABASE_SETUP.md` para o estado da expansão. Os detalhes de mapa e resultados de 13 testes abaixo descrevem a etapa antiga, não o mapa V2 padrão. Fases 2/3, backend, menus completos e competição ainda estão pendentes. A duração de primeira jogada não foi medida.

## Projeto e execução

O aplicativo está em `flutter_app/`. Ele usa Flutter 3.38.9 stable, Dart 3.10.8 e Flame **1.35.1 fixado**, com `pubspec.lock` versionável. Flame 1.38.2 exige Dart 3.11+, por isso o resolvedor selecionou a versão compatível com o SDK instalado. Não foi necessário atualizar o SDK global.

```powershell
cd flutter_app
flutter pub get
flutter run -d windows
# ou
flutter run -d chrome
```

Android tem o runner gerado e os mesmos controles touch, mas a configuração local precisa resolver as licenças Android pendentes e usar um JDK compatível com o Gradle 8.14 (Java 17–24; o ambiente auditado usa Java 25). Nenhum emulador ou dispositivo Android estava conectado na auditoria. Não foram aceitas licenças nem alterada a configuração global de Java nesta etapa.

## Auditoria e integração artística

Foram lidos o GDD v1.1, os três documentos artísticos, o JSON de layout, o atlas e os scripts de geração/inspeção. Todos os arquivos da etapa artística foram preservados. Os PNGs de comparação e prévia não entram no bundle: `pubspec.yaml` lista explicitamente os 18 PNGs de execução e os dois JSONs utilizados.

Referências técnicas consultadas: [Flame Camera & World](https://docs.flame-engine.org/latest/flame/camera.html), [Keyboard Input](https://docs.flame-engine.org/latest/flame/inputs/keyboard_input.html), [Images](https://docs.flame-engine.org/latest/flame/rendering/images.html), [GameWidget](https://docs.flame-engine.org/latest/flame/game_widget.html) e [pacote Flame](https://pub.dev/packages/flame). Os construtores e propriedades usados também foram conferidos no código instalado de `flame-1.35.1`, evitando assumir que a documentação da versão mais nova corresponderia ao SDK local.

## Organização

| Arquivo/pasta em `lib/game/` | Responsabilidade |
|---|---|
| `echoes_game.dart` | coordena passo fixo, componentes, interações, retomada e conclusão |
| `art/game_assets.dart` | pré-carrega assets, interpreta metadados e cria animações |
| `config/movement_config.dart` | parâmetros de movimento e duração das habilidades |
| `player/player_state.dart` | corpo físico e enum de animações |
| `player/movement_controller.dart` | movimento e resolução de colisão por eixo |
| `player/ability_controller.dart` | buffer, coyote, carga/duração de dash, trava do wall jump |
| `player/errante.dart` | animações, espelhamento e pivô visual |
| `input/game_input.dart` | combina teclado/touch e preserva eventos até o próximo tick |
| `levels/level_data.dart` | interpreta o layout artístico como dados de fase |
| `levels/ruins_level.dart` | desenha o atlas modular e colunas decorativas |
| `camera/` | acompanhamento limitado e parallax por deslocamento |
| `components/` | faróis/checkpoints e Eco |
| `effects/` | animações descartáveis de poeira, dash e coleta |
| `systems/level_progress.dart` | progresso local idempotente da tentativa |
| `hud/`, `screens/` | HUD, controles multitoque e painéis de pausa/conclusão |

## Contrato físico

Unidades: pixels lógicos e segundos. A simulação usa acumulador com passo de **1/120 s** e limita cada frame de renderização a 0,1 s para evitar uma recuperação ilimitada após travamentos/retorno da janela. A animação visual é independente da física. O corpo é um AABB de **14×32 px**, referenciado pelo centro dos pés; o sprite continua com 48×48 px e pivô `(24,44)`. A posição visual e a câmera são arredondadas para pixels lógicos. Todos os sprites usam `FilterQuality.none`.

Parâmetros centrais:

| Parâmetro | Valor |
|---|---:|
| velocidade lateral | 210 px/s |
| aceleração / desaceleração | 1600 / 2000 px/s² |
| gravidade / queda máxima | 1100 px/s² / 640 px/s |
| impulso de salto | 440 px/s |
| corte de salto ao soltar | velocidade vertical × 0,45 |
| coyote / jump buffer | 0,10 / 0,12 s |
| wall slide | máximo 65 px/s |
| wall jump | 250 px/s horizontal, 410 px/s vertical |
| trava direcional do wall jump | 0,15 s |
| dash horizontal | 560 px/s por 0,17 s |

Durante o dash, a gravidade fica suspensa; uma parede encerra o impulso. A carga é recuperada no chão, sem recarga por wall jump ou coleta. Para wall slide, pressione em direção à parede durante a queda. O wall jump projeta o jogador para longe da parede e preserva essa direção durante a trava curta. Colisão é por varredura em cada eixo, impedindo atravessar blocos em velocidades maiores. Não há física baseada na imagem nem pacote adicional de física.

## Fase e progresso

O JSON artístico permanece intacto em `assets/images/levels/`. Seus quatro retângulos viram superfícies sólidas explícitas:

| Plataforma | x, y | largura × altura |
|---|---|---|
| início | 0, 384 | 352×128 |
| galeria | 448, 320 | 192×64 |
| Eco | 704, 256 | 160×64 |
| farol final | 992, 192 | 288×96 |

O atlas é recortado em células de 32 px; sua segunda linha fornece as bordas superiores e as demais linhas oferecem variações de alvenaria. Colunas, raízes, correntes e arquitetura do parallax são decorativas e não têm colisores. Os vãos entre as quatro plataformas são os obstáculos do trecho.

- Spawn: `(64,384)`.
- Checkpoint inicial: `(120,384)`, nome Primeira Centelha.
- Checkpoint intermediário acrescentado para retomada: `(544,320)`, nome Galeria.
- Eco `echo_01`: centro `(848,240)`.
- Farol final: `(1112,192)`; só conclui após coletar o Eco.
- Cair abaixo de `altura do mundo + 64` devolve ao último checkpoint, incrementando quedas. O Eco já coletado permanece coletado durante a tentativa.
- Checkpoints não retrocedem quando se volta para um farol anterior. Coleta e conclusão são idempotentes. Reiniciar trecho limpa tudo; recarregar o aplicativo também limpa tudo. Não há persistência externa.

## Animação, câmera e efeitos

Idle 6/7 FPS, run 8/12 FPS, jump 2/10 FPS, fall 2/8 FPS, dash 4/16 FPS e wall slide 2/8 FPS. Trocas de pose reiniciam o ticker do estado. A duração física do dash (0,17 s) tem prioridade sobre o ciclo completo de quatro quadros de sua folha; o rastro usa sua própria animação descartável.

A resolução virtual é **640×360**, coincidente com as seis camadas do Art Pass 2, em vez do alvo provisório de 480×270 do GDD. O viewport mantém 16:9 e usa barras quando a janela tem outra proporção. A câmera segue com antevisão de 48 px, suavização exponencial e centro limitado ao mundo de 1280×512. Os fatores horizontais sky/far/mid/near/fog/shafts são 0,035 / 0,14 / 0,34 / 0,58 / 0,79 / 0,18; a posição deriva do deslocamento real da câmera, portanto volta corretamente ao andar para trás ou respawnar. A repetição espelhada cobre todo o viewport sem faixas transparentes. As camadas mantêm enquadramento vertical fixo. O Ouvinte e as duas mariposas são renderizados na câmera de fundo, sem interação ou colisores; poeira de baixa opacidade também deriva atrás do mundo.

Checkpoint, Eco e glow usam seus strips originais. Poeira é emitida em impulso, aterrissagem e corrida; dash gera rastros breves; coleta e ativação emitem o pulso de Eco. Efeitos one-shot são removidos ao terminar. Use alfa normal, sem shaders ou dependência de blend aditivo.

## Entrada e pausa

Teclado: A/D ou setas para mover; Espaço para pulo variável; Shift para dash; Esc/P para pausa; R para retornar ao checkpoint (ou repetir após concluir). Os botões visuais equivalentes aceitam vários dedos simultâneos e liberam a entrada em cancelamentos. Pause, retomada, respawn e reinício limpam entradas pendentes. Mudanças de ciclo de vida suspendem o jogo.

## Verificação

Comandos reexecutáveis:

```powershell
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub
flutter build windows --no-pub
```

Os testes incluem aceleração/desaceleração, salto variável, coyote, buffer, wall slide/jump, carga de dash, colisão lateral/chão/teto, coleta/conclusão idempotentes, união das entradas, limites da câmera e interpretação do JSON real. O teste `vertical_slice_test.dart` monta o jogo, carrega os PNGs do bundle e percorre as quatro plataformas usando a mesma simulação, sem teletransportar o jogador. Ele captura renderizações em `docs/screenshots/test_start.png` e `test_finish.png`; esses arquivos são renders do ambiente de teste, não capturas de dispositivo.

Verificação executada em 26/10/2026:

| Verificação | Resultado |
|---|---|
| `flutter analyze --no-pub` | sem problemas encontrados |
| `flutter test --no-pub --reporter expanded` | **13 testes aprovados** |
| travessia pelo simulador do jogo montado | quatro plataformas, checkpoint Galeria, Eco e farol final; zero mortes |
| retorno após queda | volta ao farol inicial ativado; posição de spawn conferida |
| teclado / touch | eventos reais do Flutter Test para D/P, botão de direção, cancelamento de toque e retomada |
| resolução de teste | 1280×720 e janela estreita 480×800; viewport virtual e ausência de erros de layout conferidos |
| Web release | compilação JavaScript concluída; dry run de Wasm também passou na primeira compilação, sem teste de execução em Wasm |
| Windows release | compilação concluída em `flutter_app/build/windows/x64/runner/Release/echoes.exe` |
| navegador | carregamento e renderização reais, pausa/retomada pelo HUD; nenhum erro de console observado |
| Android | runner preparado; build e execução **não realizados** pelas pendências de licenças e Java/Gradle |

Capturas reais de navegador: `docs/screenshots/web_start.jpg` e `web_pause.jpg`. Capturas do Flutter Test: `test_start.png`, `test_finish.png` e `test_narrow_window.png` na mesma pasta. As primeiras incluem as fontes reais do ambiente Web; os renders de teste usam as fontes de teste do Flutter. O Windows foi compilado, mas não recebeu playtest manual. A validação de travessia é automatizada, não um playtest de conforto em dispositivo físico.

Para distribuir o executável Windows, copie a **pasta Release inteira**, incluindo `data/` e as DLLs; `echoes.exe` isolado não contém o bundle. Durante recompilações Web no mesmo endereço, o service worker pode manter uma versão anterior até concluir a troca do cache; recarregue a aba após essa troca.

## Revisão artística e limites

A arte foi preservada. Revisar em sessão real a distância visual entre pés e topo das plataformas, a clareza do wall slide de dois quadros, a transição entre camadas espelhadas e o peso das colunas decorativas. A escala pode ser fracionária em janelas arbitrárias; nearest-neighbor evita blur, mas uma janela 1280×720 oferece ampliação exata de 2×. Não há áudio, animação de aterrissagem/interação, menus definitivos, backend, ranking, autenticação ou fases seguintes.


## V2.1 — execução dos três capítulos
As observações anteriores sobre ausência das fases seguintes descrevem o marco antigo. Agora a home é `WorldFlowScreen`; pause → Selecionar capítulo permite abrir qualquer um dos três. Concluir 01 permite continuar para 02; concluir 02 permite 03. A tela de conclusão da Torre encerra o primeiro arco. Reiniciar trecho registra a tentativa anterior e abre uma nova; R durante a fase retorna ao checkpoint, mantendo os Ecos daquela tentativa.

Movimento, seis animações, corpo 14×32, resolução 640×360 e controles anteriores permanecem. Dash está disponível em todos os mapas. A Câmara da Ruptura explica seu vínculo com a memória sem bloquear a habilidade. Plataformas temporárias têm rachaduras, pulso antes de sumir, 1,1 s de tolerância e 3 s de recuperação. A pausa e a narrativa suspendem a simulação.

Consulte `LEVEL_DESIGN.md` para rotas, `STAGE_REGISTRY.md` para IDs/condições e `ARCHITECTURE.md` para registros locais. `EchoesGame(slice:true)` preserva o cenário original dos testes.

Validação V2.1: 25 testes passaram, analyze sem problemas, builds Web e Windows concluídas. `world_traversal_test.dart` monta o jogo e atravessa os dois mapas por entradas de movimento reais, sem teletransportes, recolhendo os Ecos obrigatórios e fechando as cinco sequências de cada fase com zero mortes. `world_optional_routes_test.dart` verifica cada ligação de desvio com o solver real, a partir de estados de apoio; esse teste isolado não equivale a coletar todos os opcionais em uma única tentativa. O teste de transição verifica callbacks, seletor, descarte e sessão, sem pretender ser uma travessia humana.

Capturas `stage_02_*` e `stage_03_*` em `docs/screenshots` são renders do Flutter Test em 1280×720: start, middle, complex, narrative, exit_area e final. A fonte Ahem do harness representa letras como blocos; não é defeito dos PNGs nem da fonte da build. A captura exit_area mostra o cenário antes da tela de conclusão. As imagens foram refeitas após forçar repaint do engine pausado, evitando imagens antigas de outra região.

Limites: metas humanas de 6–9 / 8–12 minutos ainda não medidas; não há áudio novo, chefes, login, persistência em disco/remota ou ranking. Windows compilado, sem playtest manual nativo; Android não recompilado/testado. Controles touch são preservados, mas falta playtest físico móvel.


### Revisão Web V2.1
A build atual foi conferida no navegador em `http://127.0.0.1:18767/`: pausa, seletor com três capítulos, registros reais de tentativas interrompidas, carregamento de Galerias e Torre, seus fundos e diálogos próprios. Nenhum erro/warning de console foi observado nessa revisão. Capturas reais com tipografia de produção: `screenshots/v21_galleries_web.png` e `screenshots/v21_tower_web.png`. A travessia completa é evidência do harness de física, não foi repetida manualmente no navegador.

O endereço antigo 18766 apresentou a build anterior por cache. A primeira tentativa de servidor dentro do sandbox não ficou acessível; o preview atual usa servidor Python fora do sandbox, limitado a 127.0.0.1. Não houve publicação externa. O build Web mantém o aviso não fatal preexistente sobre CupertinoIcons; os controles Material e a tipografia foram conferidos visualmente.

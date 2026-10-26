# Arquitetura atual

`main.dart` inicia `GameScreen`. A tela hospeda `GameWidget`, HUD, touch, pausa/conclusão e o overlay narrativo. `EchoesGame` coordena componentes, física e eventos; `MovementController` continua independente de Flutter e dos dados persistidos.

## Dados de fase

`LevelData.fromStageJson` interpreta dimensões, spawn, retângulos sólidos, props com IDs estáveis, seções, layers, Ecos exigidos e gatilhos narrativos. O arquivo de fase atual é `assets/levels/stage_01.json`. O parser artístico legado continua disponível para o teste do slice.

Colisões usam apenas `solids`; sprites, colunas e animais do fundo não geram colisores. `RuinsLevel` prepara tiles uma vez e filtra sua renderização pelos limites da câmera. `GameAssets` pré-carrega as imagens utilizadas, mantendo os assets do Art Pass 2.

## Narrativa

`DialogueController` carrega as sequências de `assets/narrative/dialogues.json`. Seu estado contém sequência, linha, número de caracteres e IDs vistos na sessão. `DialogueOverlay`, `DialoguePanel`, `SpeakerPortrait` e `DialogueControls` desenham a interface responsiva sobre o Flame. O teclado é tratado antes da entrada de movimento; o overlay captura toque e os controles de movimento são ocultados durante a sequência.

O controlador rejeita sobrescrever um diálogo ativo. Fechar ou pular registra a sequência na sessão; `replay: true` permite rever uma memória na pausa. A futura camada de persistência deverá salvar os IDs vistos por usuário, sem acoplar chamadas de rede ao ticker de texto ou à física.

## Progresso e próximos módulos

`LevelProgress` ainda é local: checkpoint, mortes, conjunto idempotente de Ecos e conclusão. O método de conclusão recebe os IDs exigidos pela fase. Não há pontuação persistida nem operações de ranking. Auth/repositórios/GoRouter serão adicionados na etapa de navegação e backend; a simulação continuará independente deles.


## V2.1 — mundos integrados (estado atual)
`main.dart` inicia `WorldFlowScreen`, que possui `PlaySession` e troca `GameScreen` por uma chave nova a cada capítulo. `StageRegistry` é o catálogo autorizado: 01 → 02 → 03. Todos estão acessíveis no seletor provisório da pausa. O botão Próximo capítulo aparece após concluir 01/02; 03 encerra o primeiro arco.

`EchoesGame(stageId: ...)` passa o ID a `GameAssets`, que carrega o JSON e o atlas indicados pelo mapa. Cada instância recebe novos jogador, câmera, fragmentos, faróis, plataformas e backdrop. O descarte chama `shutdown`, interrompe entrada/engine e registra uma tentativa interrompida somente se ela começou; o resultado concluído não é duplicado. O teste de transição confere isolamento e preservação da sessão.

Schema 3 aceita sólidos com ID, plataformas temporárias, regiões em X/Y, fatores XY de parallax, câmera e eventos ambientais. O parser mantém compatibilidade com os retângulos em arrays do Despertar. O conteúdo `route`/`shafts` é metadado de autoria e QA, sem conduzir o jogador no aplicativo.

`TemporaryPlatforms` fornece a lista efetiva de colisores. Após apoio, a plataforma pulsa, rompe em 1,1 s e reaparece após 3 s; o retorno é adiado se o corpo ocupar seu volume. Diálogos/pausa congelam esse relógio. Reinício restaura todas. O renderer recorta a última célula de paredes de altura não múltipla de 32 para coincidir com o colisor.

`AttemptClock` usa Stopwatch monotônico, começa na primeira simulação e exclui loading, pausa e diálogos. `RunRecord` copia o conjunto de coletáveis e contém attemptId local, stageId, stageVersion, durationMs, deaths, collectibles, completed. `PlaySession` deduplica por attemptId e preserva memórias entre capítulos. Tudo vive em RAM; fechar/recarregar perde dados. Esse tempo de história não é prova competitiva de speedrun; a política futura deverá decidir tratamento de diálogos e validação no servidor.

As layers são repetidas com espelhamento XY; atores e eventos do backdrop não têm colisores. Texturas são carregadas pelo cache; tiles são preparados no onLoad e descartados fora do viewport. Poeira tem 26 pontos fixos, rastros/FX removem-se ao terminar. Não há rede nesta integração.

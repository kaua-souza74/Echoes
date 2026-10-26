# ECHOES — três mundos

Plataforma narrativa offline em Flutter + Flame com três capítulos jogáveis: O Despertar, Galerias Quebradas e Torre do Eco. São 15 seções, 21 Ecos, 15 checkpoints e 14 sequências narrativas. O aplicativo fica em `flutter_app/`. Pause e use **Selecionar capítulo**; ao concluir uma fase, **Próximo capítulo** continua o arco. Resultados e memórias são locais à sessão, sem backend ou ranking online.

```powershell
cd flutter_app
flutter pub get
flutter run -d windows
# ou: flutter run -d chrome
```

Mova com **A/D ou setas**, pule com **Espaço** (segure para subir mais) e use **Shift** para dash. Empurre uma parede para deslizar e pressione pulo para saltar para longe dela. Esc/P pausa; R retorna ao checkpoint. Há controles de toque equivalentes. Recupere o Coração do Lume e alcance o farol final; os demais Ecos ficam nas rotas de exploração. Quedas retornam ao checkpoint mais recente.

Nos diálogos, Espaço/Enter ou toque revelam a fala e depois avançam. Esc ou Pular encerram a sequência. A pausa permite rever memórias vistas na sessão. O slice legado permanece como cenário de regressão por `EchoesGame(slice: true)`.

O SDK auditado foi Flutter 3.38.9/Dart 3.10.8 com Flame 1.35.1. Os runners Windows, Web e Android foram gerados; o ambiente Android tem pendências de licenças e compatibilidade de Java. Veja [o handoff técnico](docs/GAMEPLAY_HANDOFF.md) para estrutura, parâmetros, testes, instruções de build e limitações.

O GDD original é `ECHOES_GDD_v1.1.md`. A direção de arte, manifesto e handoff artístico ficam em `docs/`. `References/` é material de estudo e não entra no bundle. Não há integração com Supabase nesta etapa.

Consulte [o registro da expansão](docs/DEVELOPMENT_LOG.md), [a arquitetura](docs/ARCHITECTURE.md), [o plano de testes](docs/TEST_PLAN.md) e [o estado do backend](docs/SUPABASE_SETUP.md). A meta de duração de primeira jogada ainda precisa de playtest humano.


Validação V2.1: 25 testes aprovados, análise estática limpa e builds Web/Windows concluídas. Veja [Level Design](docs/LEVEL_DESIGN.md) e [catálogo de fases](docs/STAGE_REGISTRY.md). As metas de duração ainda precisam de playtest humano.

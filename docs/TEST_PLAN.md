# Plano de verificação

## Regressão

`movement_test.dart`: aceleração, salto variável, coyote, buffer, dash, wall slide/jump e colisões. `progression_input_camera_test.dart`: idempotência, entrada combinada, limites de câmera e parser artístico com os seis layers atuais. `vertical_slice_test.dart`: carrega o slice legado e percorre suas quatro plataformas, testa morte/respawn, teclado, touch, pausa e enquadramento estreito.

## Expansão e narrativa

`dialogue_test.dart`: digitação, revelar, avanço, rejeição de eventos rápidos, pular, memória vista e replay. `expanded_stage_test.dart`: carrega os assets e o mapa expandido, bloqueio de movimento em diálogo, botão de pular e travessia com a física real. Captura `docs/screenshots/expanded_dialogue_test.png`; esta imagem usa a fonte de teste do Flutter.

`stage_routes_test.dart` simula separadamente cada salto dos cinco desvios e seus retornos, com o solver real e todos os sólidos ativos. Confere também que os sete Ecos estão em alcance de plataformas. É uma validação de conectividade dos saltos; a travessia contínua do mapa é feita pelo teste montado no Flutter. O overlay é conferido em 1280×720 e 480×800, incluindo o retrato acima do painel, entrada por Espaço/Enter e replay após conclusão.

## Execução

```powershell
cd flutter_app
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --no-wasm-dry-run
flutter build windows --no-pub
```

As metas de duração não substituem playtest humano. Android não está validado: permanecem as pendências de licença e JDK/Gradle documentadas no handoff anterior. Auth, RLS, ranking e persistência exigirão testes reais de banco quando esses módulos existirem; não são cobertos pelos testes locais atuais.

Resultado do marco B/C em 26/10/2026: 16 testes aprovados, análise estática sem problemas, builds Web e Windows concluídos. No Web, avanço/pular/replay e retorno dos controles foram exercitados na interface real sem erros de console. Evidência: `docs/screenshots/v2_dialogue_web.jpg`. O Windows foi compilado, não submetido a novo playtest manual.

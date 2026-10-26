# Pipeline de arte ECHOES

Gere o pacote da primeira fase com Python 3.10+ e Pillow instalado:

```powershell
python art_pipeline/scripts/generate_echoes_assets.py
python art_pipeline/scripts/inspect_echoes_assets.py
```

O gerador cria PNGs RGBA, atlas e layout em `flutter_app/assets/images/`. O inspetor valida dimensões e quadros não vazios/não duplicados e recompõe `asset_review_contact.png`. A origem é determinística e local: formas, clusters de pixels e ruído controlado; não acessa rede nem usa as referências como imagem de entrada. Edite os parâmetros e funções do gerador para refinar o estilo e rode novamente. Os scripts geram os quadros e backgrounds finais, mas não configuram o app, Flame, física ou colisão.

O manifesto do pacote, dimensões, animações, pontos de origem, FPS sugeridos e limitações estão em `docs/ASSET_MANIFEST.md`; as regras visuais estão em `docs/ART_DIRECTION.md` e instruções de consumo em `docs/ART_HANDOFF.md`.

O Art Pass 2 tem gerador independente para que cada pacote possa ser recriado sem apagar o outro:

```powershell
python art_pipeline/scripts/generate_art_pass2.py
```

Ele substitui as quatro layers do Despertar, atualiza a ordem/fatores do JSON, gera névoa e feixes, duas criaturas de background e estudos das Galerias Quebradas e da Torre do Eco. Não execute apenas o gerador da etapa 1 depois do Art Pass 2 sem executar este script novamente: a etapa 1 restaura os backgrounds e o layout anteriores.

A expansão V2 usa `python art_pipeline/scripts/build_stage01_expansion.py`. Ele grava o mapa autorado em `flutter_app/assets/levels/stage_01.json`, as quatro sequências em `assets/narrative/dialogues.json` e o retrato transparente em `assets/images/narrative/memory_portrait.png`. Os índices de `main_route` e `branches` apontam para retângulos de `solids`; os testes conferem travessia, desvios e alcance dos Ecos. Mudanças de layout devem ser feitas nesse gerador e conferidas novamente com a física real.


## Mundos V2.1
Execute `python art_pipeline/scripts/build_world_expansion.py` para regerar mapas 02/03, atlas, névoas, criaturas e dez diálogos (mesclados ao arquivo existente). Ele pressupõe as seis layers-base produzidas por `generate_art_pass2.py`. Não modifica o GDD nem utiliza as imagens de References como entrada. O relatório `world_asset_review.json` registra dimensões, alfa e poses dos strips inspecionados. Testes reais de rota estão no Flutter; a geração de JSON não prova jogabilidade.

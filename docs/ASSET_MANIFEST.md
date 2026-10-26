# ECHOES — Manifesto de assets artísticos

## Retrato narrativo V2

`flutter_app/assets/images/narrative/memory_portrait.png`: RGBA 128×160 px, imagem original de cristal facetado, bordas/cantos transparentes e halo de alfa baixo. Gerador: `art_pipeline/scripts/build_stage01_expansion.py`. A flutuação, pulso de fala e transições são animações do overlay Flutter, não frames de spritesheet. Uso exclusivo do retrato de memória; não gera colisão.

Todos os PNGs abaixo são gerados por `art_pipeline/scripts/generate_echoes_assets.py` com Pillow e desenhos determinísticos próprios. Spritesheets têm fundo RGBA transparente. Os arquivos `preview_*.png` e `*_preview.png` servem para inspeção visual, não para reprodução em gameplay.

## Errante

Diretório `flutter_app/assets/images/player/`. Célula comum de **48×48 px**, origem/pivô recomendado em **(24, 44)** (centro da base dos pés), leitura à direita por padrão. Nenhuma folha contém espaçamento entre células.

| Arquivo | Folha | Quadros | FPS sugerido | Uso |
|---|---:|---:|---:|---|
| `errante_idle.png` | 288×48 | 6 | 7 | respiração e pulso sutil |
| `errante_run.png` | 384×48 | 8 | 12 | corrida em loop |
| `errante_jump.png` | 96×48 | 2 | 10 | subida do salto |
| `errante_fall.png` | 96×48 | 2 | 8 | queda |
| `errante_dash.png` | 192×48 | 4 | 16 | impulso curto; silhueta estendida |
| `errante_wall_slide.png` | 96×48 | 2 | 8 | contato e descida na parede |

As seis folhas usam quadros desenhados individualmente. Não há estados `land` ou `interact` neste primeiro pacote. Versões `preview_*.png` ampliam cada folha 4× por nearest-neighbor para inspeção.

## Cenário — O Despertar

- `parallax/stage_01/01_sky_mist.png`, `02_far_architecture.png`, `03_mid_architecture.png`, `04_near_decor.png`: quatro layers substituídas no Art Pass 2, RGBA, 640×360 px cada. Mantêm nomes e funções-base para compatibilidade.
- `parallax/stage_01/05_breathing_fog.png`: névoa baixa em clusters transparentes, 640×360 px; layer opcional.
- `parallax/stage_01/06_lume_shafts.png`: feixes remotos de alfa baixo, 640×360 px; layer opcional.
- `parallax/stage_01/awakening_backdrop_preview.png`: composição de conferência das seis layers, 640×360 px.
- `parallax/stage_01/awakening_microlevel_preview.png`: placa panorâmica com o novo ambiente e as quatro superfícies do slice, 1280×512 px; referência, não mapa executável.
- `background_creatures/stage_01/the_listener.png`: O Ouvinte, folha horizontal 320×64 px, quatro quadros de 80×64, 2,5 FPS; RGBA.
- `background_creatures/stage_01/veil_moth.png`: Mariposa do Véu, 256×48 px, quatro quadros de 64×48, 4 FPS; RGBA.
- As criaturas animadas ficam somente no backdrop, fator de câmera 0,17 e 0,10, bob ±2 px e opacidade 0,68–0,80; não têm collider ou comportamento de gameplay.
- `tilesets/stage_01_ruins_tiles.png`: atlas RGBA 256×160 px, grade 8×5 de tiles 32×32 (40 células: blocos, bordas superiores, relevos rachados, pedra musgosa e ornamentos).
- `tilesets/stage_01_ruins_tiles.json`: dimensões, posições e classificação das células do atlas.
- `levels/stage_01_awakening_layout.json`: referência de composição 40×16 tiles, fatores de parallax e colocação conceitual dos props. Não é mapa de colisão pronto.
- `props/carved_column.png`: coluna decorativa RGBA 64×96 px.

## Props e efeitos

| Arquivo | Dimensão | Quadros e célula | FPS sugerido |
|---|---:|---:|---:|
| `props/checkpoint_lume.png` | 192×64 | 4 × 48×64 | 6 |
| `props/echo_fragment.png` | 128×32 | 4 × 32×32 | 8 |
| `effects/dash_trail.png` | 320×32 | 5 × 64×32 | 18 |
| `effects/dust_puff.png` | 128×24 | 4 × 32×24 | 12 |
| `effects/lume_glow.png` | 256×64 | 4 × 64×64 | 6 |
| `effects/echo_collect.png` | 320×64 | 5 × 64×64 | 18 |

## Inspeção e verificação

`art_pipeline/asset_review_contact.png` reúne as folhas e props para revisão. O gerador foi executado com sucesso e o inspetor validou 12 strips: dimensões corretas, quadros não vazios e quadros realmente distintos. Os limites do Errante ficam em torno do pivô comum; idle/run incluem oscilação intencional de até 2 px. O atlas tem canal alfa; o fundo das células vazias permanece transparente.

As referências fornecidas estão apenas em `References/`; não são copiadas para o bundle.

## Estudos das áreas futuras

Cada layer abaixo mede 640×360 px; os arquivos `*_visual_study.png` são composições para revisão e não entram no bundle atual.

| Área | Assets-base | Direção |
|---|---|---|
| Galerias Quebradas | `parallax/stage_02/01_petroil_void.png`, `02_suspended_galleries.png`, `03_chains_and_windbreaks.png`; `stage_02_visual_study.png` | abismo ventilado, pontes partidas, pilares altos, correntes e ferro apagado |
| Torre do Eco | `parallax/stage_03/01_indigo_aperture.png`, `02_echo_tower.png`, `03_shattered_lancets.png`; `stage_03_visual_study.png` | eixo vertical sagrado, lancetas, vidro quebrado lateral, ciano prateado e ouro escasso |

Esses seis PNGs de camadas ainda não são carregados pelo jogo. São bases originais para composição e podem ser registrados em um layout futuro.


## V2.1 — pacote de mundos integrado
Origem autoral procedural: `art_pipeline/scripts/build_world_expansion.py`; os seis fundos-base vêm do `generate_art_pass2.py`. Todos foram abertos e conferidos; dimensões/alfa completos em `art_pipeline/world_asset_review.json`.

| Arquivo em assets/images | Dimensão | Frames/célula/FPS |
|---|---:|---|
| tilesets/stage_02_ruins_tiles.png + .json | 256×160 | 40 tiles 32×32, atlas metálico |
| tilesets/stage_03_ruins_tiles.png + .json | 256×160 | 40 tiles 32×32, atlas de pedra |
| parallax/stage_02/01_petroil_void.png | 640×360 | base opaca |
| parallax/stage_02/02_suspended_galleries.png | 640×360 | arquitetura RGBA |
| parallax/stage_02/03_chains_and_windbreaks.png | 640×360 | correntes e sombras RGBA |
| parallax/stage_02/04_wind_haze.png | 640×360 | névoa, alfa máximo 16/255 |
| parallax/stage_03/01_indigo_aperture.png | 640×360 | base opaca |
| parallax/stage_03/02_echo_tower.png | 640×360 | torre/lancetas RGBA |
| parallax/stage_03/03_shattered_lancets.png | 640×360 | vidro e cristais RGBA |
| parallax/stage_03/04_silver_mist.png | 640×360 | névoa/feixes, alfa máximo 16/255 |
| background_creatures/worlds/crawler.png | 320×40 | 4 / 80×40 / 3 |
| background_creatures/worlds/spirit.png | 256×80 | 4 / 64×80 / 3 |
| background_creatures/worlds/colossus.png | 1280×144 | 4 / 320×144 / 2 |

Os dois atlas são opacos; todas as criaturas têm pixels transparentes e frames não vazios. Cada strip repete a pose neutra no terceiro quadro, com três poses distintas. Props, retrato, FX e protagonista existentes são compartilhados sem alterar escala/pivô. Os JSONs executáveis são `assets/levels/stage_02.json` e `stage_03.json`; há dez novas sequências no arquivo narrativo compartilhado, totalizando 14.


Capturas de produção V2.1: `screenshots/v21_galleries_web.png` e `screenshots/v21_tower_web.png`; ambas conferidas no navegador. As capturas regionais `stage_02_*`/`stage_03_*` são do harness de testes e usam fonte Ahem.

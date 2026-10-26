# ECHOES — Handoff artístico para integração Flame

## O que existe

Na expansão V2, o retrato `assets/images/narrative/memory_portrait.png` é um PNG RGBA de 128×160 px, com cantos transparentes e halo de alfa baixo. Seu desenho original é gerado por `art_pipeline/scripts/build_stage01_expansion.py`. O overlay Flutter pré-carrega a imagem, preserva nearest-neighbor e anima entrada/saída, flutuação, brilho e reação durante a digitação. Em telas largas, o retrato fica à esquerda do texto e acima da borda superior; em telas pequenas, o texto desce para não cruzar a imagem.

O mapa jogável ampliado está em `assets/levels/stage_01.json`; o JSON artístico de `assets/images/levels/` continua como referência e cenário de regressão. Os novos gatilhos e colecionáveis são dados de fase, não estão embutidos nas imagens.

O Art Pass 2 adiciona fundos, criaturas de background e vida atmosférica. O jogo usa Flame para desenhar as seis layers do Despertar, as duas folhas animadas e um campo sutil de poeira procedural no backdrop. A lógica de movimento, colisões e progressão permanece igual. Leia `ART_DIRECTION.md` para paleta, composição, fatores de parallax e prioridade de leitura; consulte `ASSET_MANIFEST.md` para dimensões e contagens.

## Carregar animações do Errante

Registre a pasta de imagens no `pubspec.yaml` do aplicativo que será criado. Cada folha do jogador é uma faixa horizontal sem margem, com células de 48×48 px. Crie a animação com `SpriteAnimationData.sequenced`, `textureSize: Vector2(48, 48)`, o número de quadros e o `stepTime` `1 / FPS` da tabela do manifesto. Use estes nomes de estado: `idle`, `run`, `jump`, `fall`, `dash` e `wall_slide`. Mantenha a posição do componente vinculada ao pivô (24,44); ao desenhar, compense a origem para que a base dos pés permaneça no ponto de mundo. Use flip horizontal para virar o Errante; as animações não têm duplicatas viradas.

Todas as células são pixels originais. Configure filtro nearest-neighbor/nearest sampling na renderização. Escalone por múltiplos inteiros quando possível. Não carregue `preview_*.png` no jogo.

## Montagem do cenário

Cada overlay parallax do Despertar mede 640×360 px. O JSON `levels/stage_01_awakening_layout.json` contém ordem e fatores iniciais. `01_sky_mist` é opaco; os cinco demais têm transparência alfa. Repita horizontalmente com espelhamento em nearest-neighbor como `ParallaxBackdrop`. `04_near_decor` limita raízes/rocha às margens; `05_breathing_fog` é leve e se concentra no rodapé; `06_lume_shafts` deve continuar sutil.

As criaturas ficam em `background_creatures/stage_01/`. Cada folha tem quatro quadros contíguos, sem margem. Recorte `the_listener.png` em 80×64 px e `veil_moth.png` em 64×48 px, filtro nearest, loop a 2,5/4 FPS. O código atual instancia um Ouvinte e duas mariposas em coordenadas de canvas, com fatores 0,17/0,10, opacidade moderada e bob de ±2 px. Mantenha-as na câmera de fundo antes do mundo jogável; não crie colisores, não as ligue a input/estados e não use as silhuetas como indicação de perigo.

Captura da build Web com as layers e criaturas ativas: [`screenshots/art_pass2_web.jpg`](screenshots/art_pass2_web.jpg). As placas `stage_02_visual_study.png` e `stage_03_visual_study.png` permitem revisar as duas direções futuras sem iniciar o jogo.

A poeira contínua é desenhada proceduralmente por `ParallaxBackdrop` em 26 pontos determinísticos, com dois deslocamentos lentos, atrás das plataformas. Não requer arquivo nem componente de gameplay. A névoa é uma layer estática de baixa opacidade; se receber movimento futuro, mantenha-o lento e sem contraste alto sobre as bordas superiores das plataformas.

O atlas tem 8 colunas de 32 px e 5 linhas. Use `stage_01_ruins_tiles.json` para relacionar IDs e posições `(coluna, linha)`; cada tile deve ser recortado em 32×32 px. As células são apenas arte de tiles e não definem colisão. O JSON de `levels/` descreve uma proposta de trecho e não deve ser tratado como mapa de colisão validado. A prévia visual é um guia de composição, não um substituto dos layers e tiles.

Checkpoint: spritesheet com quatro quadros, célula 48×64 px, ponto de apoio centrado em x=24 e base próxima a y=61. Fragmento de Eco: quatro quadros de 32×32 px, centro visual em (16,16). Faça a coleta disparar `echo_collect` como uma animação one-shot e o brilho do Lume pode repetir em loop.

## Efeitos

- `dash_trail`: células 64×32; reproduzir uma vez no sentido contrário ao movimento do Errante ou espelhar pelo vetor do dash.
- `dust_puff`: células 32×24; one-shot junto ao piso em corrida, aterrissagem ou impulso.
- `lume_glow`: células 64×64; loop lento, centralizado sobre checkpoint/fragmento. O PNG já inclui o halo; comece com alfa moderado.
- `echo_collect`: células 64×64; pulso one-shot no centro do Eco coletado.

Use transparência alfa normal como fallback. Efeitos visuais são decorativos e não devem encobrir hitboxes ou a borda superior das plataformas. A arte foi composta para permanecer legível sem shader e sem luz dinâmica por pixel.

## Regerar e revisar

Com Python 3.10+ e Pillow:

```powershell
& <python-com-Pillow> art_pipeline/scripts/generate_echoes_assets.py
```

O script sobrescreve os arquivos derivados em `flutter_app/assets/images/`; edite o gerador, não os PNGs gerados à mão. `art_pipeline/asset_review_contact.png` é a folha de inspeção gerada durante a revisão. As imagens-fonte de `References/` são material de estudo e ficam fora de `flutter_app/assets/`.

Para regerar somente o Art Pass 2 (camadas, criaturas e estudos), rode:

```powershell
python art_pipeline/scripts/generate_art_pass2.py
```

Esse script não modifica atlas, protagonista, props, tiles ou regras de fase. Os PNGs `stage_02_visual_study.png` e `stage_03_visual_study.png` são placas de revisão e não estão no bundle atual. As camadas futuras precisam de layout e ajuste de parallax quando suas fases forem produzidas.

## Limitações conhecidas

O slice ainda não tem estados `land`/interação, áudio, mapa completo ou inimigos ativos. Galerias Quebradas e Torre do Eco têm estudos de ambiente, sem fases jogáveis, tilesets ou layouts de gameplay. As animações de `jump` e `fall` do Errante continuam com dois quadros. A aparência depende da escala e da câmera do jogo.

## Verificação do Art Pass 2

- `flutter analyze --no-pub`: sem problemas.
- `flutter build web --no-pub --no-wasm-dry-run`: concluído; cena conferida no navegador, sem erros de console.
- `flutter build windows --no-pub`: concluído em `flutter_app/build/windows/x64/runner/Release/echoes.exe`.
- PNGs de cenário e spritesheets conferidos: dimensões e alpha esperados, folhas com quatro quadros; bases de céu opacas e overlays atmosféricos transparentes.
- `screenshots/art_pass2_web.jpg` é captura real do jogo após a integração.


## V2.1 — integração de Galerias e Torre
Os seis layers antes descritos como estudos agora são bases reais dos mapas 02/03. Cada mapa usa quatro layers próprias (640×360), incluindo a nova névoa. O JSON indica asset, parallax horizontal e `parallax_y`; o renderer faz espelhamento em ambos os eixos para cobrir a ascensão. As placas `*_visual_study.png` continuam somente para revisão, apesar de estarem na pasta registrada pelo bundle.

Os novos atlas `stage_02_ruins_tiles.png` e `stage_03_ruins_tiles.png` têm 8×5 células de 32 px. Galerias usa placas rebitadas, diagonais estruturais e desgaste âmbar; Torre usa pedra estratificada, inscrições em losango e prata/ouro gasto. Nenhuma imagem define colisor. Partes finais de paredes são recortadas no renderer para respeitar o retângulo autorado.

Recorte `crawler` em 4×80×40 a 3 FPS; `spirit` em 4×64×80 a 3 FPS; `colossus` em 4×320×144 a 2 FPS. Origem visual central no backdrop, transparência normal, sem colisão. O padrão 0/1/0/−1 repete intencionalmente a pose neutra nos quadros 0 e 2. Crawler e espírito têm bob ±2 px; a entidade gigante cruza a tela em 28 s somente após a zona do Abismo. A Torre ganha feixes durante a zona final por 30 s. Esses eventos são idempotentes por tentativa e resetam ao reiniciar.

Reprodução: execute `generate_echoes_assets.py`, `generate_art_pass2.py`, `build_stage01_expansion.py` e por último `build_world_expansion.py` quando quiser reconstruir o pacote completo. Para editar só os novos mundos, rode apenas o último. O gerador da fase 1 agora mescla seus diálogos para preservar os novos. GDD e References ficam intocados. `world_asset_review.json` registra dimensões/alfa e frames não vazios, com três poses distintas por strip de quatro quadros.


Capturas de produção V2.1: `screenshots/v21_galleries_web.png` e `screenshots/v21_tower_web.png`; ambas conferidas no navegador. As capturas regionais `stage_02_*`/`stage_03_*` são do harness de testes e usam fonte Ahem.

# ECHOES — Direção de arte do vertical slice

## Leitura do GDD e das referências

O documento-base é `ECHOES_GDD_v1.1.md`. A primeira fase, **O Despertar**, pede galerias subterrâneas de pedra molhada, pilares antigos, poeira e faróis apagados. O Errante é baixo, usa manto curto e máscara sem rosto humano detalhado; o Lume aparece em ciano restrito. Examinei as três imagens em `References/` apenas como referência de atmosfera e composição:

- `imagem.png`: ruína azul fria, arcos ao fundo, chão legível em primeiro plano e pequenos pontos de luz.
- `imagem (1).png`: leitura de grande portal arquitetônico central e contraste entre plano jogável e fundo.
- `imagem (2).png`: sensação de escala, profundidade de névoa e silhuetas grandes recortadas contra luz.

As imagens não foram incorporadas, traçadas nem usadas como textura. O pacote estabelece um vocabulário original de arcos partidos, lintéis segmentados, inscrições em losango e lanternas de pedra do Vale das Vozes.

## Direção visual

**Clima:** silêncio subterrâneo, pedra fria e um vestígio de calor vivo. O cenário permanece escuro, mas evita preto chapado: planos arquitetônicos são separados por valores azul-petróleo e ardósia. A cor mais clara fica nos olhos, no fragmento de Eco e no núcleo do farol.

**Paleta-base:** carvão azulado `#0B111C`, pedra fria `#1C2B3A`, ardósia `#34495D`, borda iluminada `#526B7C`, Lume `#84D9E8`, violeta sombrio `#514568`, musgo `#36554E` e ouro gasto `#B49A70` em inscrições pontuais. Os valores usados pelo gerador estão em `art_pipeline/palette.json`.

**Pixel e escala:** sprites do protagonista desenhados em células de 48×48 px, com clusters inteiros e sem antialiasing. O atlas do cenário usa tiles de 32×32 px. Amplie com nearest-neighbor em escala inteira; não aplique filtro bilinear nem redimensione os sprites para frações de pixel. O tamanho visual final depende da resolução virtual que o jogo vier a adotar.

**Protagonista:** silhueta curta e assimétrica, capuz pontudo, máscara de porcelana sem feições humanas, manto azul-carvão e duas fendas ciano. A pequena semente luminosa no peito repete a linguagem do fragmento. O rastro do dash prolonga a silhueta para comunicar direção e velocidade.

## Composição e profundidade

As quatro imagens de parallax originais foram substituídas no Art Pass 2 sem alterar o canvas de 640×360 px. Duas overlays atmosféricas foram acrescentadas:

| Camada | Conteúdo e leitura | Fator relativo sugerido |
|---|---|---:|
| `01_sky_mist` | vazio mineral e poeira distante | 0,035 |
| `02_far_architecture` | arco quebrado e paredões remotos | 0,14 |
| `03_mid_architecture` | pilares, nichos e galerias | 0,34 |
| `04_near_decor` | raízes, corrente e rocha nas margens | 0,58 |
| `05_breathing_fog` | névoa baixa | 0,79 |
| `06_lume_shafts` | fendas de luz remota | 0,18 |
| mundo jogável | atlas modular e elementos interativos | 1,00 |

Os fatores são proporções artísticas usados pelo jogo. Deixe o centro e as bordas superiores das plataformas livres de decoração frontal. A prévia `awakening_microlevel_preview.png` representa o trecho horizontal de 40×16 tiles (1280×512 px), com as quatro superfícies do vertical slice.

## Luz e leitura

O brilho é pré-composto em pequenos PNGs RGBA, com pulsos discretos em quadros separados. Use o núcleo e o halo com blend aditivo somente se o desempenho permitir; a leitura funciona também em composição alfa comum. Preserve contraste suficiente nas bordas de plataforma e não use ciano como único sinal de interação: o farol tem forma de obelisco e o Eco, forma cristalina.

## Parallax da trilogia

O Despertar estabelece o arco de pedra fria e luz ciano. Galerias Quebradas abre a composição em dunas, vãos de arenito e pontes antigas; Torre do Eco volta a subir, agora em torno de copas, raízes e janelas de pedra musgosa. As três regiões compartilham escala de pixel, silhuetas recortadas e contraste baixo no plano jogável, mas cada uma usa formas e cores próprias.

## Art Pass 2 — ambientes vivos

As três imagens de `References/` continuam servindo apenas como referência de atmosfera, profundidade e hierarquia; nenhuma foi copiada, traçada ou usada como entrada do gerador. O novo vocabulário visual do Vale das Vozes combina um anel de pedra interrompido, nichos estreitos, galerias laterais, raízes periféricas, um observador distante e mariposas do Lume. As criaturas são narrativas, sem colisores ou leitura de ameaça.

O Despertar agora usa seis imagens alinhadas em 640×360. Os quatro nomes originais foram mantidos como substitutos compatíveis; névoa respirante e feixes suaves são duas camadas adicionais. A névoa usa poucos valores alfa e ocupa o terço inferior. Os feixes têm alfa baixo e poucos pixels claros. Poeira animada e criaturas ficam no plano do backdrop, atrás do mundo jogável; nenhuma partícula marca perigo ou interatividade.

| Ordem | Layer | Fator inicial | Plano e leitura |
|---:|---|---:|---|
| 1 | `01_sky_mist` | 0,035 | vazio mineral, poeira distante e respiradouros do Lume |
| 2 | `02_far_architecture` | 0,14 | arco quebrado, paredões e observador suspenso |
| 3 | `03_mid_architecture` | 0,34 | nichos, pilares e galerias laterais |
| 4 | `04_near_decor` | 0,58 | raízes, ombros de rocha e corrente nas margens |
| 5 | `05_breathing_fog` | 0,79 | véus inferiores suaves |
| 6 | `06_lume_shafts` | 0,18 | fendas de luz muito translúcidas |
| 7 | mundo jogável | 1,0 | tiles, Errante, faróis e Eco |

As criaturas animadas usam fatores 0,17 (O Ouvinte) e 0,10 (mariposas), bob de ±2 px e opacidade entre 0,68 e 0,80. Os 26 pontos de poeira são determinísticos, oscilam lentamente e permanecem atrás das plataformas e do jogador. Os fatores iniciais evitam que o plano próximo corra mais rápido que a fase curta; ajustes devem ser avaliados durante uma travessia completa.

**Galerias Quebradas:** a travessia entra numa faixa de dunas que soterrou parte das galerias. Use carvão violeta no céu distante, areia ocre, arenito recortado pelo vento e âmbar desgastado. Preserve pontes interrompidas, pilastras verticais e correntes antigas para que a arquitetura siga contando a transmissão de saberes. O vazio permanece maior que a pedra; poeira e vida pequena ficam atrás da área de jogo.

**Torre do Eco:** a torre sobe entre copas e raízes de uma floresta verde profunda. Use sombras verde-musgo, pedra tomada por líquen, feixes suaves de luz e âmbar apenas no selo do Lume. Mantenha o eixo central ascendente e as janelas em lanceta; vinhas, folhas e sementes luminosas emolduram as bordas sem cobrir personagem ou plataformas. O centro claro continua reservado aos eventos narrativos.

As camadas atuais das Galerias e da Torre usam canvas 640×360 px, silhuetas por planos e detalhes em clusters de pixels. O script `art_pipeline/scripts/generate_biome_expansion.py` recompõe, de forma determinística, as camadas, os atlas e as criaturas dessas duas paletas.

## Interface de jogo no celular

O jogo ocupa a orientação horizontal em aparelhos nativos. O indicador de movimento fica sob o polegar esquerdo e se ancora onde o jogador toca; pulo e dash formam um par de botões no alcance do polegar direito. Os alvos são círculos grandes, com contorno e brilho ao pressionar. O botão de pausa fica no topo; a placa lateral usa a cor do capítulo e mantém a cena visível atrás dela.

Na entrada, uma grade de pixels na cor local cobre a fase e se desfaz para revelar o cenário. Ao voltar ao menu, a mesma grade recompõe a cor e fecha a cena. A mudança de capítulos percorre ciano frio, ocre de areia e verde de floresta sem depender apenas da cor: cada etapa também troca silhuetas, arquitetura e vegetação.


## V2.1 — primeira integração (histórico visual)
As Galerias e a Torre são mapas executáveis com quatro layers próprias e deslocamento XY. O arranjo de pontes quebradas e a torre vertical permanecem; a V2.2 substitui as paletas frias por arenito de deserto e floresta verde, com atlas, poeira e criaturas locais.

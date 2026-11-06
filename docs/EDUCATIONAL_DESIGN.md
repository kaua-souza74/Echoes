# ECHOES — desenho educacional V2.2

## Fronteira entre ficção e conceito

O Vale das Vozes, seus personagens, festas e técnicas são ficcionais. Eles ilustram ideias gerais, mas não representam uma tradição brasileira real. O texto do arquivo explica conceitos de memória e patrimônio com linguagem própria; nomes e histórias do Vale não devem ser apresentados como exemplos históricos documentados.

| Fase | Conceito | Objetivo de aprendizagem | Interação | Explicação apresentada | Verificação |
|---|---|---|---|---|---|
| O Despertar | Memória individual e coletiva, vestígios, fontes orais e lugares de referência | Relacionar pistas de um objeto e de um relato a uma história possível, reconhecendo que uma fonte isolada não conta tudo | Ao reunir Ecos, relacionar o pote azul com a marca e com o relato familiar | Objetos, lugares e relatos ajudam a reconstruir histórias quando contextualizados e comparados | `check_stage_01`: escolher quais pistas são relacionadas ao objeto preservado; feedback permite tentar novamente |
| Galerias Quebradas | Patrimônio material e imaterial, transmissão, recriação e diversidade cultural | Distinguir um bem físico de práticas e conhecimentos associados, entendendo a participação das pessoas | Relacionar a ponte de pedra ao saber transmitido de encaixar suas pedras | Patrimônio cultural pode envolver bens físicos, práticas, expressões e saberes vivos; dimensões podem coexistir | `check_stage_02`: relacionar estrutura física e conhecimento de construção; feedback explicativo, sem bloquear a fase |
| Torre do Eco | Pertencimento, perspectivas, preservação e responsabilidade compartilhada | Escolher uma forma de preservar memórias que escute participantes e reconheça diferenças entre relatos | Reunir versões de uma festa e decidir como o arquivo deve guardá-las | Fontes e memórias têm perspectivas; preservar requer contexto, participação e respeito às comunidades | `check_stage_03`: selecionar uma ação de arquivo participativo e reconhecer versões distintas |

Os 21 IDs estáveis dos Ecos estão em `flutter_app/assets/levels/stage_01.json`, `stage_02.json` e `stage_03.json`. O catálogo original foi preservado em `flutter_app/assets/narrative/memory_catalog.json`. A tela `flutter_app/lib/narrative/memories_screen.dart` permite nova tentativa sem punição. Na aplicação de produção, a resposta aguarda a RPC, e memórias/interações são desbloqueadas a partir da conta. Isso foi testado com dependência simulada no Flutter e PostgreSQL local; a instalação remota ainda depende do responsável. O catálogo reutiliza o primeiro frame do fragmento transparente existente; ilustrações exclusivas continuam pendentes. Diálogos vistos inclusive por skip são enviados por conta, mantendo o retrato cinematográfico.

## Fontes e formulação

- IPHAN, [Patrimônio Imaterial](https://www.gov.br/iphan/pt-br/patrimonio-cultural/patrimonio-imaterial): apresenta práticas, saberes, celebrações, formas de expressão e lugares coletivos; descreve transmissão e recriação em relação à história e ao ambiente, contribuindo para identidade, continuidade e diversidade.
- IPHAN, [Patrimônio Material](https://www.gov.br/iphan/pt-br/patrimonio-cultural/patrimonio-material/): descreve bens móveis e imóveis protegidos e os instrumentos de preservação no contexto brasileiro.
- UNESCO, [domínios do patrimônio imaterial](https://ich.unesco.org/en/intangible-heritage-domains-00052): lista tradições orais, artes performáticas, práticas sociais e celebrações, conhecimentos sobre natureza e artesanato tradicional; explica que uma manifestação pode envolver vários domínios.

O jogo simplifica esses conceitos para crianças e adolescentes e não pretende substituir definições legais, inventários nem a voz das comunidades. Os textos não atribuem ao IPHAN ou UNESCO reconhecimento de elementos fictícios.

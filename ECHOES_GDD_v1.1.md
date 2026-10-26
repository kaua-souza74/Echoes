# ECHOES — Fragments of the Forgotten
## Game Design Document (GDD) — v1.1
**Data:** 26/10/2026  
**Entrega escolar:** 09/11/2026  
**Formato:** jogo 2D mobile, plataforma narrativa  
**Stack:** Flutter + Flame + GoRouter + Supabase  
**Estado:** pré-produção / escopo MVP  

> **Visão:** uma jornada curta, memorável e visualmente marcante por um reino que perdeu suas memórias. Controles precisos, dash expressivo e níveis artesanais iluminados por fragmentos de Lume.

## 1. Pilares de design
1. **Precisão:** corrida, salto, wall slide, wall jump e dash devem ser responsivos.
2. **Atmosfera:** pixel art autoral, parallax multicamadas, luz pontual, névoa e partículas discretas.
3. **Narrativa ambiental:** história revelada por cenários e Ecos colecionáveis, sem diálogos extensos.
4. **Conclusão demonstrável:** três fases curtas e completas; progressão, conquistas e ranking persistidos.
5. **Mobile primeiro:** controles por toque legíveis, interface adaptada e taxa de quadros estável.

## 2. Visão geral
- **Gênero:** plataforma 2D de precisão com exploração leve e narrativa ambiental.
- **Público:** jogadores que gostam de exploração atmosférica e desafios curtos.
- **Plataforma alvo:** Android; Flutter Web como ambiente opcional de testes, sem prometer equivalência de desempenho.
- **Sessão ideal:** 3–7 minutos por fase no MVP (meta, sujeita a testes).
- **Câmera:** lateral, segue o personagem com suavização, limites de fase e antevisão na direção do movimento.
- **Orientação:** paisagem (landscape) no gameplay; menus adaptáveis.
- **Referências:** *Hollow Knight* (atmosfera e profundidade), *Inmost* (pixel art narrativa), *Celeste* (controle de plataforma). Não replicar personagens, mapas, arte ou trilhas.

## 3. Mundo e narrativa
### Premissa
No subterrâneo do **Vale das Vozes**, o **Lume** guardava lembranças em pequenos faróis de pedra. Após uma ruptura conhecida como **O Silêncio**, as lembranças se dispersaram e as passagens do reino se partiram.

Uma pequena figura envolta em um manto, chamada provisoriamente **O Errante**, desperta ao lado de um farol apagado. O Errante não lembra seu nome, mas reconhece lugares que nunca deveria ter visto. Fragmentos chamados **Ecos** reagem à sua presença.

### Revelação do primeiro arco
No último Eco do prólogo, descobre-se que o Errante foi um dos guardiões encarregados de proteger o Lume. Sua própria lembrança está incompleta; a origem exata da ruptura fica em aberto para uma continuação. A história explora memória, responsabilidade e esperança, sem explicações longas.

### Forma de contar
- Ambiente: inscrições, vitrais, faróis, arquitetura e mudanças de luz.
- Ecos: pequenas frases originais + breve efeito visual, vistos no **Arquivo de Ecos**.
- Eventos: abertura do portão, ignição de faróis, transformação de áreas antes escuras.
- Exemplos de textos originais: “A pedra guarda o que a voz esqueceu.”; “A luz conhece este caminho.”

## 4. Protagonista e identidade
- **Silhueta:** baixa, reconhecível, com manto curto e máscara simples sem rosto humano detalhado.
- **Cores:** corpo em azul-carvão, detalhes do manto em cinza-ardósia, brilho ciano restrito aos olhos e ao Lume.
- **Animações MVP:** idle, run, jump-up, fall, wall-slide, dash, land, interact.
- **Escala:** definir grade e dimensões de sprite após as referências; preservar pixel-perfect e consistência entre spritesheets.

## 5. Controles e sensação
### Entradas mobile
- Esquerda/direita: botões virtuais fixos na parte inferior esquerda.
- Pular e dash: botões separados na parte inferior direita.
- Interagir: botão contextual quando próximo de Eco/farol.
- Pausa: botão no topo, abrindo menu de retomar, reiniciar e voltar.

### Mecânicas MVP
| Mecânica | Comportamento | Critério de aceite |
|---|---|---|
| Corrida | aceleração e desaceleração calibradas | deslocamento previsível, sem deslize excessivo |
| Pulo | altura variável ao segurar o botão | salto curto e longo consistentes |
| Coyote time | breve tolerância após deixar uma borda | comandos próximos da borda são aceitos |
| Jump buffer | armazena brevemente um toque de pulo | salto dispara ao tocar o chão quando elegível |
| Wall slide | desacelera a queda junto de paredes válidas | personagem não atravessa colisores |
| Wall jump | impulso para cima e para fora da parede | permite superar corredores verticais |
| Dash | impulso curto no ar ou solo, com recarga ao tocar o chão | uma carga por período aéreo; feedback visual |
| Checkpoint | farol salva posição de reaparecimento na tentativa | retorno rápido ao checkpoint após falha |
| Coleta de Ecos | coleta fragmentos únicos por fase | fragmento permanece registrado após sincronização |
| Conclusão da fase | ativa portal/farol final após condições definidas | registra progresso uma vez e desbloqueia fase seguinte |

**Balanceamento inicial (parâmetros ajustáveis, não especificações finais):** dash de 0,14–0,20 s; coyote time 0,08–0,12 s; jump buffer 0,08–0,12 s. Refinar com playtest.

### Fora do MVP
Combate complexo, inventário, mundo aberto, árvore de habilidades, NPCs com diálogos ramificados e multiplayer em tempo real.

## 6. Estrutura do prólogo
### Fase 1 — O Despertar
**Tema:** galerias adormecidas. **Paleta:** azul-petróleo, ardósia, ciano suave.  
**Cenário:** pedras molhadas, pilares antigos, poeira, faróis apagados.  
**Ensina:** correr, pular, coletar um Eco, ativar checkpoint.  
**Clímax:** primeiro farol acende e revela uma passagem.  
**Recompensa proposta:** 100 pontos pela primeira conclusão.

### Fase 2 — Galerias Quebradas
**Tema:** passarelas suspensas sobre um vazio de névoa. **Paleta:** carvão, violeta-acinzentado, azul frio.  
**Cenário:** correntes, pontes rachadas, estruturas em camadas.  
**Ensina:** wall slide e wall jump, combinações de saltos.  
**Clímax:** altar desperta a habilidade dash para as fases seguintes.  
**Recompensa proposta:** 150 pontos pela primeira conclusão.

### Fase 3 — Torre do Eco
**Tema:** ascensão por uma torre vertical de vitrais. **Paleta:** índigo escuro, ciano, dourado envelhecido em poucos detalhes.  
**Cenário:** plataformas altas, janelas quebradas, feixes de Lume, parallax exterior.  
**Desafio:** combinar salto, parede e dash com checkpoints.  
**Clímax:** Eco principal revela que o Errante foi um guardião do Lume.  
**Recompensa proposta:** 200 pontos pela primeira conclusão.

### Regras de progressão
- Fase 1 disponível após login; fases 2 e 3 liberadas sequencialmente.
- Revisitar uma fase é permitido, mas **não concede novamente pontos de conclusão**.
- Ecos têm identificação única e não podem conceder recompensa duplicada.
- Pontos de bônus por tempo ou mortes ficam fora do MVP para reduzir fraude e escopo.

## 7. Direção de arte
**Estilo:** pixel art original de alta qualidade, formas legíveis e detalhes concentrados nas áreas de interesse.  
**Referências estéticas:** atmosfera de *Hollow Knight*, narrativa visual de *Inmost*.  
**Cores propostas:** `#0B111C` carvão azulado; `#1C2B3A` pedra fria; `#34495D` ardósia; `#84D9E8` Lume; `#514568` violeta sombrio; `#B49A70` ouro gasto.

### Composição em camadas
1. Fundo distante: gradientes escuros, silhuetas e arquitetura remota.
2. Fundo intermediário: pontes, torres e grandes formas.
3. Plano jogável: tiles, colisores e elementos interativos legíveis.
4. Frente: correntes, galhos, bordas e partículas controladas.

**Parallax:** movimento relativo sutil, diferente por camada; nenhum elemento frontal deve impedir a leitura dos obstáculos.

**Luz:** halo do Lume, pulsação discreta de faróis, pequenas partículas; evitar pós-processamento pesado em dispositivos modestos. Testar custo real no Flame/Flutter antes de adotar shaders.

**Padrões de leitura:** áreas perigosas com silhueta e contraste próprios; não depender exclusivamente de cor para indicar interatividade.

## 8. Áudio e feedback
- Música ambiente discreta, original ou licenciada.
- Sons curtos para pulo, dash, coleta, checkpoint e conclusão.
- Dash com rastro curto e leve distorção de partículas; coleta com pulso de iluminação.
- Configurações de volume e opção de reduzir efeitos visuais caso caibam no cronograma.

## 9. UX / telas exigidas
1. **Splash:** marca ECHOES e redirecionamento por sessão.
2. **Login e cadastro:** Supabase Auth, mensagens claras de erro, logout.
3. **Home / central de missões:** capítulos, pontos, concluídas, fase destacada e progresso.
4. **Detalhes da missão:** descrição, dificuldade, recompensa, status, instruções e botão jogar.
5. **Gameplay:** Flame embutido em tela Flutter, HUD, pausa e controles touch.
6. **Conquistas:** disponíveis, bloqueadas/desbloqueadas, condições.
7. **Ranking:** classificação real do banco, destaque top 3 e posição própria.
8. **Perfil:** apelido, e-mail, pontuação, missões concluídas, conquistas e logout.
9. **Arquivo de Ecos (extra):** fragmentos narrativos já descobertos.

**GoRouter:** todas as telas e redirecionamentos de autenticação pelo roteador; passagem de ID da fase à tela de detalhes e gameplay.

**Widgets personalizados mínimos:** `StageCard`, `ProgressCard`, `AchievementBadge`; extras `RankTile`, `EchoCollectionItem`.

## 10. Sistema de missões, conquistas e ranking
### Missões
As três fases são missões principais. Cada uma possui título, descrição, categoria, dificuldade, pontos, ordem, status e condição de desbloqueio.

### Conquistas MVP
- **Primeira Centelha:** completar fase 1.
- **Entre Paredes:** completar fase 2.
- **Voz da Torre:** completar fase 3.
- **Colecionador de Ecos:** coletar todos os Ecos do prólogo.

### Ranking
Ordenar jogadores pela **soma das recompensas únicas validadas pelo servidor**. Mostrar empate com critério estável (por exemplo, apelido ou data da primeira conquista de pontuação, conforme decisão de implementação). Não confiar no valor enviado pelo cliente.

## 11. Dados e segurança — Supabase externo
O projeto Supabase pertence a **outra conta** e o desenvolvedor será convidado a colaborar. Acesso ao painel depende do convite, do papel concedido e da política da organização. **O convite não concede automaticamente acesso ao Codex**.

### Entidades sugeridas
- `profiles`: `id` (FK auth.users), `nickname`, `created_at`.
- `missions`: `id`, `title`, `description`, `category`, `difficulty`, `reward_points`, `sort_order`, `is_active`.
- `user_missions`: `user_id`, `mission_id`, `status`, `completed_at`, `updated_at` com unicidade por usuário e missão.
- `echoes`: `id`, `mission_id`, `text`, `position_key`.
- `user_echoes`: `user_id`, `echo_id`, `collected_at` com unicidade.
- `achievements`: `id`, `name`, `description`, `condition_type`, `condition_value`, `icon_key`.
- `user_achievements`: `user_id`, `achievement_id`, `unlocked_at` com unicidade.
- `score_events`: registro imutável de pontos concedidos, com chave de idempotência única.

### Políticas
- RLS ligado nas tabelas de dados de jogadores.
- Cada jogador lê/escreve apenas os dados privados permitidos; o ranking público expõe somente apelido e pontuação agregada aprovada.
- **Não permitir UPDATE direto do score pelo cliente.** Conclusão/recompensa realizada por uma rotina de backend com checagem de autenticação, pré-requisitos e idempotência, em transação.
- Para o protótipo escolar, a conclusão de missão pode ser simulada. Como a execução da fase ocorre no cliente, não prometer antitrapaça absoluta: as checagens de servidor impedem duplicações e alterações arbitrárias de pontos, mas não provam que o jogador superou cada obstáculo.
- Não incluir `service_role` no Flutter. Configuração pública da URL e chave publicável/anon somente com RLS correto. Segredos em ambiente restrito.

### Trabalho sem acesso imediato ao backend
1. Implementar modelos, repositórios abstratos e mocks locais.
2. Preparar migrations SQL revisáveis em `supabase/migrations/` sem aplicar em produção automaticamente.
3. Após convite e autorização, configurar cliente Supabase e testar ambiente.
4. Validar RLS, autenticação, transações e ranking com pelo menos dois usuários de teste.

## 12. Arquitetura técnica
- **UI:** Flutter Material, design system próprio e componentes reutilizáveis.
- **Jogo:** Flame; componentes separados para personagem, plataformas, colisão, câmera, checkpoints e coletáveis.
- **Rotas:** GoRouter; proteção de telas internas por sessão.
- **Dados:** `supabase_flutter`, repositórios e modelos tipados.
- **Assets:** spritesheets e backgrounds por fase; áudio comprimido e licenciado.
- **Estados:** loading, error, empty, success em todas as consultas.
- **Resolução:** definir resolução virtual fixa do jogo com escala adaptada e áreas seguras mobile.

### Estrutura de pastas oficial (proposta a ser criada pelo Codex)

```text
ECHOES/
├── AGENTS.md                         # instruções permanentes do Codex
├── README.md                         # instalação, execução, créditos e demonstração
├── .gitignore
├── docs/
│   ├── GDD_ECHOES.md                 # este documento
│   ├── ART_BIBLE.md                  # regras de pixel art e iluminação
│   ├── ASSET_MANIFEST.md             # arquivo, dimensões, frames, estado e origem
│   ├── GAMEPLAY_SPEC.md              # constantes, regras e estados do jogador
│   ├── DATABASE_PLAN.md              # esquema e políticas propostas
│   ├── REFERENCES.md                 # links, licenças e usos das referências
│   └── QA_CHECKLIST.md               # roteiro de validação e apresentação
├── references/                       # imagens fornecidas pelo usuário, NÃO publicadas
│   ├── characters/
│   ├── environments/
│   │   ├── stage_01/
│   │   ├── stage_02/
│   │   └── stage_03/
│   ├── lighting/
│   ├── animations/
│   └── ui/
├── art_pipeline/                     # ferramentas escritas pelo Codex
│   ├── README.md
│   ├── palette.json
│   ├── sprite_specs/
│   ├── scripts/                       # Python/Pillow ou Dart para gerar PNGs
│   └── tests/                         # valida spritesheets e transparência
├── flutter_app/
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── app.dart
│   │   │   ├── router/app_router.dart
│   │   │   └── theme/{colors,typography,game_theme}.dart
│   │   ├── core/
│   │   │   ├── config/                 # config pública, versões e flags
│   │   │   ├── errors/
│   │   │   └── utils/
│   │   ├── features/
│   │   │   ├── splash/
│   │   │   ├── auth/{data,presentation}/
│   │   │   ├── home/{data,presentation}/
│   │   │   ├── missions/{data,domain,presentation}/
│   │   │   ├── achievements/{data,presentation}/
│   │   │   ├── ranking/{data,presentation}/
│   │   │   ├── profile/{data,presentation}/
│   │   │   └── echo_archive/{data,presentation}/
│   │   ├── game/
│   │   │   ├── echoes_game.dart
│   │   │   ├── world/                 # mundo, câmera, limites, layers
│   │   │   ├── player/                # Player, estados, habilidades, input
│   │   │   ├── components/            # plataformas, perigos, Ecos, portais
│   │   │   ├── systems/               # física, colisão, checkpoints, som
│   │   │   ├── levels/                # leitura e montagem de fases
│   │   │   ├── input/                 # touch e teclado para testes
│   │   │   ├── effects/               # dash trail, partículas, glow leve
│   │   │   ├── hud/
│   │   │   └── screens/game_screen.dart
│   │   └── shared/
│   │       ├── models/
│   │       ├── repositories/          # contratos + mock + Supabase
│   │       ├── widgets/               # StageCard, ProgressCard, etc.
│   │       └── services/
│   ├── assets/
│   │   ├── images/
│   │   │   ├── player/                 # PNG spritesheets
│   │   │   ├── tilesets/
│   │   │   ├── parallax/{stage_01,stage_02,stage_03}/
│   │   │   ├── props/
│   │   │   ├── particles/
│   │   │   └── ui/
│   │   ├── levels/                    # JSON autoral ou TMX, se aprovado
│   │   ├── audio/{sfx,music}/
│   │   └── fonts/
│   ├── test/                          # widgets, rotas, repositórios e regras
│   └── integration_test/              # fluxo de ponta a ponta
├── supabase/
│   ├── migrations/                    # scripts SQL versionados e revisados
│   ├── seed.sql                       # dados de fases e conquistas
│   └── tests/                          # RLS, idempotência e permissões
└── scripts/
    ├── verify_project.py             # checagem de arquivos e assets
    └── package_school_submission.py  # ZIP exatamente lib + pubspec.yaml
```

**Regras estruturais:** `flutter_app/assets` é o destino dos arquivos finais gerados. `references/` contém exclusivamente material de estudo; manter fora do bundle e registrar origem. Nunca colocar credenciais privadas, `service_role` ou tokens em repositório. `supabase/` separado para operar sem acesso ao projeto externo. Não criar diretórios vazios à força; criá-los à medida que forem necessários. O Codex deve executar `flutter analyze` e testes a cada marco.

**Entrega escolar:** o ZIP exigido tem **somente `lib/` e `pubspec.yaml`**, conforme o PDF, mas isso é potencialmente incompatível com um jogo que depende de PNGs, mapas e áudio em `assets/`. Não omitir silenciosamente os recursos: manter **repositório completo e executável**, registrar o conflito e pedir ao professor confirmação de como disponibilizar os assets (por exemplo, via repositório) antes da entrega.

## 13. Critérios de aceite do MVP
- [ ] Cadastro, login, sessão persistente e logout funcionando.
- [ ] Splash redireciona corretamente conforme autenticação.
- [ ] Três fases iniciáveis pela Home e pelos detalhes da missão.
- [ ] Movimentação com pulo, wall slide, wall jump e dash responsivos.
- [ ] Colisões, checkpoints, coleta de Ecos e fim de fase funcionando.
- [ ] Recompensa única por fase, sem duplicação após replay.
- [ ] Ranking calculado de dados persistidos e identificação do jogador.
- [ ] Conquistas desbloqueadas e bloqueadas corretamente.
- [ ] Perfil atualizado após conclusão e relogin.
- [ ] Pelo menos três widgets reutilizáveis e navegação GoRouter.
- [ ] RLS testado com dois usuários e sem manipulação livre de pontos.
- [ ] README e demonstração de ponta a ponta.

## 14. Plano de produção até 09/11/2026
| Período | Entrega prioritária |
|---|---|
| 26–28/10 | projeto-base, navegação, mocks, controle e colisões Flame, referências visuais |
| 29/10–01/11 | fase 1 completa, sistema de checkpoints/Ecos e protótipo artístico |
| 02–05/11 | fases 2 e 3, dash, UI e integração Supabase autorizada |
| 06–07/11 | conquistas, ranking, segurança e testes de dois usuários |
| 08/11 | polimento, correções, README, ZIP e ensaio da apresentação |
| 09/11 | entrega e demonstração |

**Regra de corte:** se houver risco de prazo, priorizar uma fase excelente, duas fases menores jogáveis e todos os fluxos obrigatórios; reduzir efeitos e extras antes de comprometer login, persistência e ranking.

## 15. Referências e direitos de uso
Usar imagens anexadas pelo criador em `references/` exclusivamente como guia de clima, cor, composição, animação e iluminação. Não reutilizar arte protegida de terceiros como assets finais sem licença. Registrar origem/licença de sprites, fontes, sons e músicas de terceiros.

## 16. Riscos e decisões em aberto
- **Risco:** qualidade de pixel art exigir mais tempo que código. **Mitigação:** uma linguagem visual consistente, spritesheets pequenos e backgrounds em camadas reutilizáveis.
- **Risco:** acesso tardio ao Supabase. **Mitigação:** mocks, interface de repositório, migrations separadas e integração no fim.
- **Risco:** lag em celulares modestos. **Mitigação:** limitar partículas, medir FPS, pré-carregar assets.
- **Risco:** controle touch desconfortável. **Mitigação:** playtests reais em dispositivo físico.
- **Decisões a confirmar:** resolução virtual, arte final do Errante, nomenclatura de capítulos, total de Ecos por fase, licenças de áudio e dispositivos mínimos suportados.

---
**Documento vivo.** Alterações no escopo devem preservar a entrega escolar: Flutter, GoRouter, Supabase, autenticação, missões, pontuação, conquistas, ranking, perfil, widgets e demonstração prática.


## 17. Pesquisa técnica e repositórios (verificada em 26/10/2026)

### Fontes principais, por prioridade

| Fonte | Link | O que estudar / reutilizar como técnica | Prioridade |
|---|---|---|---|
| **Ember Quest (tutorial oficial Flame)** | https://docs.flame-engine.org/latest/tutorials/platformer/platformer.html | Mundo, personagem, colisões, entrada, HUD, menus; criar implementação própria adaptada ao ECHOES | P0 |
| **Flame — engine e exemplos oficiais** | https://github.com/flame-engine/flame/tree/main/examples | Padrões de componentes, câmera, animações, inputs e testes; conferir exemplos compatíveis com versão instalada | P0 |
| **Flame — documentação parallax** | https://docs.flame-engine.org/latest/flame/components/parallax_component.html | Camadas transparentes e velocidades relativas, `ParallaxComponent` | P0 |
| **Flame — câmera e mundo** | https://docs.flame-engine.org/latest/flame/camera.html | `CameraComponent`, viewport fixo, follow, backdrop e HUD | P0 |
| **Simple Platformer** | https://github.com/ufrshubham/flame_simple_platformer | Referência comunitária de movimentação/plataforma; verificar manutenção e APIs antes de adaptar | P1 |
| **Dino Run** | https://github.com/ufrshubham/dino_run | Referência de movimentação lateral e controles; não copiar sprites/arte | P1 |
| **Flutter Casual Games Toolkit** | https://docs.flutter.dev/resources/games-toolkit | Template de endless runner, SuperDash, efeitos e parallax, telas e ciclo do jogo | P1 |
| **Awesome Flame** | https://github.com/flame-engine/awesome-flame | Catálogo de bibliotecas, jogos e exemplos; olhar seção Platformer e ferramenta `leap` sem assumir compatibilidade | P2 |
| **Flame Tiled** | https://docs.flame-engine.org/latest/bridge_packages/flame_tiled/flame_tiled.html | Carregar TMX e separar arte, colisores e objetos caso JSON próprio fique limitante | P2 |
| **Supabase para Flutter** | https://supabase.com/docs/guides/getting-started/quickstarts/flutter | Auth, projeto, RLS, chaves publicáveis e configuração do cliente | P0 |
| **Supabase Flutter repo** | https://github.com/supabase/supabase-flutter | Consultar README e guia de migração da versão instalada antes de gerar código de API | P0 |

**Sobre licenças:** Flame declara licença MIT para o motor; a documentação do tutorial informa textos CC BY 4.0 e exemplos de código MIT. Projetos comunitários e seus assets precisam de verificação de licença **individual** antes de reutilizar qualquer arquivo. O objetivo aqui é estudar abordagens, não clonar jogos inteiros. Os links pesquisados são referências reais; não são auditoria de cada arquivo nem garantia de compatibilidade com o Flutter atual.

### Leitura orientada para o Codex

1. **Ember Quest:** analisar a sequência de criação de mundo, colisão, controle, HUD e menu; estabelecer um vertical slice sem assets de terceiros.
2. **Exemplos Flame:** selecionar exemplos de `SpriteAnimationComponent`, `CollisionCallbacks`, `CameraComponent`, `ParallaxComponent`, `GameWidget` e overlays; adequar métodos à versão fixada do pacote.
3. **Controle fino (código próprio):** implementar aceleração, gravidade, salto variável, coyote time, jump buffer, wall jump e dash por máquina de estados em arquivos separados. Não supor que o Flame ofereça uma classe pronta de controlador Celeste-like.
4. **Níveis:** começar com nível declarativo em JSON (plataformas, colisores, spawns, checkpoints, Ecos e destino); opcionalmente migrar a TMX se houver vantagem mensurável.
5. **Parallax:** usar camadas autorais transparentes com proporções distintas e teste de deslocamento; evitar usar câmera como simples translação de tudo.
6. **Dados:** desenvolver primeiro `MockGameRepository` e contratos. Só habilitar implementação Supabase depois de autorização, esquema revisado e políticas RLS testadas.

## 18. Pipeline de assets e animações 100% produzidos pelo Codex

**Decisão:** o Codex será responsável por **programar a criação e o processamento** de sprites, cenários, tiles, partículas e animações. Não baixar assets prontos para a versão final. As referências fornecidas pelo usuário servem para análise artística. **Limitação realista:** um agente de código pode gerar pixel art por scripts (`Pillow`, `Canvas`, SVG rasterizado, padrões e camadas), mas o resultado visual de nível comercial não é automático; requer iterações e revisão de screenshots. O Codex não equivale a um modelo especializado em pintura. Preferir um estilo próprio consistente a tentar replicar o acabamento exato dos jogos-referência.

### Contratos de arte (alvos iniciais; testar e ajustar)
- Resolução lógica de protótipo: **480 × 270** (16:9); ajustar viewport mobile e escala de pixels sem blur.
- Tiles: **16×16 ou 32×32** pixels, decisão global e não misturar escalas arbitrárias.
- Protagonista: começar com uma tela de silhouette study 32×48 px por frame, com pivô dos pés fixo e bounding box independente do desenho.
- Spritesheets: `idle` 4–6 quadros; `run` 6–8; `jump` 1–2; `fall` 1–2; `dash` 3–5; `wall_slide` 2–3; `land` 2–3. São orçamentos, não arquivos já existentes.
- FPS de animação: `idle` 4–8; `run` 10–14; `dash` alinhado à duração da habilidade. Física separada de FPS dos sprites.
- Paleta: manter `palette.json`, contagem limitada de cores, contraste forte entre colisor e fundo.
- Export: PNG RGBA sem interpolação (nearest neighbor), nome previsível, metadados em JSON (`frameWidth`, `frameHeight`, `frames`, `fps`, `pivot`).

### Pipeline reproducível
1. Codex lê o GDD, `ART_BIBLE.md`, referências e `ASSET_MANIFEST.md`.
2. Escreve mini especificação de cada asset (silhueta, paleta, dimensões, estados, profundidade e uso).
3. Cria scripts em `art_pipeline/scripts/` para desenhar composições originais e exportar PNGs/spritesheets; pode usar formas geométricas, dither controlado, pixel clusters, curvas simples, ruído determinístico e padrões de arquitetura.
4. Exporta **folha de comparação**/contact sheet com frames e tamanhos aumentados por nearest-neighbor para revisão, além do PNG de execução.
5. Gera animações a partir de **quadros realmente distintos**; não tratar repetição ou deslocamento artificial da mesma imagem como animação concluída.
6. Valida programaticamente dimensões, alpha, ausência de frames vazios, posicionamento de pivôs, cor transparente, tamanho de atlas, nomes declarados no `pubspec.yaml`.
7. Codex implementa a referência aos assets no Flame e captura screenshots/testes de execução.
8. Refinar em ciclos: **silhueta → gameplay legível → cenário → luz → partículas → polimento**. Cada revisão deve preservar colisores e legibilidade.

### Ambiente com profundidade (por fase)
- `sky`: gradiente pixelizado/névoa distante, movimento ~0–0.1x da câmera.
- `far`: arquitetura distante, movimento ~0.15–0.25x.
- `mid`: pilares, pontes e vitrais, movimento ~0.35–0.55x.
- `near`: detalhes de fundo, movimento ~0.65–0.8x.
- `world`: tiles de colisão e interativos, movimento 1.0x.
- `foreground`: silhuetas próximas, movimento >1.0x com limites e prioridade de leitura.

Esses fatores são **diretrizes artísticas relativas**, não configurações diretas prontas do `ParallaxComponent`; mapear a implementação conforme o comportamento da câmera e API atual.

### Iluminação viável
- MVP: pequenos halos RGBA pré-renderizados, partículas, vinhetas suaves e pulsação em componentes; custo e transparência medidos em dispositivo.
- Avançado: experimentar fragment shaders ou canvas blend modes **apenas se o protótipo rodar sem travar**; evitar compromisso inicial de iluminação dinâmica real por pixel.
- O Lume deve iluminar visualmente sem apagar bordas das plataformas ou botões touch.

### Cenários com identidade própria
- **Fase 1:** pedras úmidas, arcos enormes no fundo, lâmpadas esquecidas; silhueta escura contra ciano suave.
- **Fase 2:** galerias suspensas, correntes, vazio e névoa violeta; eixo horizontal quebrado por paredes de escalada.
- **Fase 3:** vitrais assimétricos, torres ao longe e feixes de luz dourado-ciano; ascensão vertical e clímax.

## 19. Protocolo de trabalho com IA / Codex

### Arquivo `AGENTS.md` (orientação para gerar)
- Tratar este GDD como fonte de escopo; ler antes de propor alterações estruturais.
- Consultar documentação oficial e confirmar versões instaladas, **não inventar APIs** de Flame ou Supabase.
- Não executar SQL remoto, alterar ambiente externo, enviar commits ou habilitar sincronização sem permissão explícita.
- Priorizar assets originais gerados por scripts locais; nunca copiar gráficos das referências nem incluir mídias de terceiros sem verificação de licença.
- Entregar cada fase em mudanças pequenas com arquivos nomeados, evidência de `flutter analyze`/`flutter test` e screenshots quando disponíveis.
- Manter jogo executável offline com repositórios mock; interface de persistência isolada.
- Nunca simular resultado de comando ou teste. Reportar falhas e limitações.
- Não adicionar funcionalidade fora do MVP sem avaliação do prazo escolar.

### Ordem de implementação por prompts curtos
**Prompt 01 — auditoria e skeleton:** criar pastas essenciais, Flutter app, arquitetura, navegação, telas temporárias e mocks; não implementar Supabase remoto; mostrar versões e testes.

**Prompt 02 — vertical slice jogável:** tela Flame com player temporário gerado em script, física, colisão e câmera; controles teclado/touch; primeiro microtrecho.

**Prompt 03 — habilidades:** implementar coyote time, jump buffer, wall slide, wall jump e dash, cada um com critérios de teste e parâmetros ajustáveis.

**Prompt 04 — pipeline artístico:** gerar assets originais, folha de inspeção, parallax da fase 1 e animações por estado; registrar tudo no manifest.

**Prompt 05 — Fase 1:** layout, coletáveis, checkpoints, portal, transição e história curta; validar do início ao fim.

**Prompt 06 — Fases 2 e 3:** reuso das ferramentas do motor, novos layouts e mudanças artísticas sem duplicar implementação.

**Prompt 07 — backend:** revisar migrations, RLS, função idempotente de conclusão, autenticação e ranking; permitir mock enquanto acesso não concedido.

**Prompt 08 — testes e entrega:** dois usuários, reinício, logout, pontuação sem duplicação, inspeção FPS, README, checklist e pacote escolar.

### Critérios de revisão automática
- Lint e testes Flutter passam (ou falha é documentada).
- Toda fase carrega sem asset ausente; animações declaradas têm frames válidos.
- Dash não permite impulsos ilimitados no ar; checkpoint não gera pontos.
- Jogadores não leem dados privados de outros; ranking mostra só dados públicos.
- Reexecutar conclusão ou coleta não duplica recompensa.
- Menu permite navegar sem usar exclusivamente o botão voltar.
- Nenhuma imagem de referência vai para o bundle final.

## 20. Checklist de verificação antes de integrar Supabase externo
1. Confirmar convite aceito, organização/projeto correto e papel de acesso.
2. Solicitar ao proprietário apenas **Project URL e chave publicável** para Flutter; não pedir senha ou `service_role`.
3. Identificar versão de `supabase_flutter` (o README atual do repositório descreve v3 e alerta sobre snippets v2 incompatíveis); fixar versão e seguir docs da versão adotada.
4. Revisar e aplicar migrations **com aprovação** no projeto correto; guardar SQL no repositório.
5. Auditar policies por tabela e grants/RPC, e testar como dois usuários.
6. Habilitar `SupabaseGameRepository`, mantendo `MockGameRepository` para testes.
7. Registrar README com instruções de configuração local que não exponham segredos.

## 21. Próximas decisões técnicas
- Começar **sem motor de física adicional**: Flame + colisores simples e física de personagem controlada por código. Reavaliar somente se a física realmente exigir.
- Definir pelo Codex uma câmera que respeite limites e mantenha personagem legível nos saltos verticais.
- Criar primeiro **um trecho de 20–30 segundos com arte quase final**, antes de distribuir qualidade por três fases.
- Aceitar crítica estética iterativa: assets feitos com código não garantem de primeira a estética proposta; validar screenshots com as referências.
- O GDD v1.1 é um documento de planejamento, não declaração de que o jogo, assets ou Supabase já foram implementados.

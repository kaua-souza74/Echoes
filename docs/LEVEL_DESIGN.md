# ECHOES — Level Design V2.1

## Contagens finais

| Fase | Seções | Sólidos permanentes | Temporárias | Checkpoints | Ecos | Sequências |
|---|---:|---:|---:|---:|---:|---:|
| O Despertar | 5 | 54 | 0 | 5 | 7 | 4 |
| Galerias Quebradas | 5 | 30 | 4 | 5 | 7 | 5 |
| Torre do Eco | 5 | 53 | 4 | 5 | 7 | 5 |

Sólidos incluem paredes dos poços. Galerias: 25 apoios principais (21 permanentes + 4 temporários), 7 apoios opcionais e 2 paredes. Torre: 48 apoios principais (44 + 4 temporários), 3 varandas/nicho e 6 paredes. Faróis finais não entram na contagem de checkpoints.

## Galerias Quebradas

1. Entrada: revela escala, pontes e vãos de 96 px com subidas de 64 px.
2. Passagens Suspensas: ponte frágil e desvio superior (gb0→gb3), com o Eco das Asas. A varanda de saída deixa livre o teto do salto principal.
3. Abismo das Correntes: poço de 640 px, paredes internas a 128 px; entrada por abertura de 48 px sob a parede esquerda. Wall jumps alternados chegam à saída direita. O Eco das Correntes flutua no percurso. A entidade ambiental cruza o fundo por 28 s após entrar na zona; sem colisão.
4. Câmara da Ruptura: sequência de dash/subidas e fragmento obrigatório. A conversa revela que o impulso atravessa lacunas de memória.
5. Última Travessia: duas pontes temporárias, apoios estreitos e desvio gb4→gb6 com Eco escondido. Farol em (8160,960), conversa final e botão para a Torre.

Ecos: galleries_gate, galleries_wings, galleries_chain, galleries_rupture (obrigatório), galleries_secret, galleries_bridge, galleries_last. Diálogos: g_entry, g_wings, g_depth, g_rupture, g_exit.

## Torre do Eco

1. Base: subida à direita até o primeiro poço. As paredes ganham pedra prateada e motivos do Lume.
2. Salão dos Fragmentos: saída à esquerda, varandas externas opcionais, plataforma temporária e escada que muda de direção.
3. Escadaria Partida: segundo poço de 640 px, plataformas de 64 px nas curvas e nicho opcional sob a escada. A entrada do nicho usa queda controlada, sem pular para a plataforma de cima; há retorno para t25.
4. Câmara das Memórias: Eco obrigatório em t31 e conversa sobre o guardião e as lembranças alteradas. Checkpoint junto à memória.
5. Último Eco: terceiro poço de 512 px, alternância entre paredes e dash, ascensão final e segundo Eco obrigatório. Zona de reação luminosa antes do farol (1632,768); t_final encerra o arco.

Ecos: tower_threshold, tower_glass (varanda direita do primeiro poço), tower_guardian, tower_shadow (varanda direita do segundo), tower_alcove (nicho), tower_memory e tower_last (ambos obrigatórios). Sequências: t_base, t_fragments, t_guardians, t_memory, t_final.

## Justiça e verificação

A física original foi preservada. Respawn mantém Ecos, limpa entradas e restaura carga de dash; reinício limpa tentativa e plataformas. Galerias retorna ao checkpoint se cair mais de 768 px abaixo dele; Torre, 640 px. O mapa também verifica o limite inferior global. R permite retorno manual.

Os metadados route/shafts permitem repetir a travessia pelos mesmos controles do aplicativo; nenhum bot existe na build. As duas rotas principais passaram com zero mortes. Desvios foram conferidos ligação a ligação, incluindo retorno das varandas da Torre. Os testes não medem descoberta humana, conforto touch nem tempo de primeira conclusão. Metas 6–9 e 8–12 minutos permanecem hipóteses; não foram acrescentados corredores vazios para tentar garanti-las.

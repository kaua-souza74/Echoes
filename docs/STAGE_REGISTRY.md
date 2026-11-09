# ECHOES — catálogo V2.2

| ID | Título | Versão | Mundo px | Spawn (pés) | Próximo | Conclusão |
|---|---|---:|---|---|---|---|
| stage_01 | O Despertar | 3 | 11776×1024 | 64,384 | stage_02 | echo_heart + farol |
| stage_02 | Galerias Quebradas | 2 | 8448×2304 | 96,1792 | stage_03 | galleries_rupture + g_exit + farol |
| stage_03 | Torre do Eco | 2 | 2560×5632 | 384,5376 | encerramento | tower_memory + tower_last + t_final + farol |

As paletas acompanham o arco: O Despertar usa pedra fria e luz ciano; Galerias atravessa ruínas soterradas por dunas, em arenito e ocre; Torre sobe entre raízes e copas de floresta, em verde musgo com o Lume âmbar.

As novas estruturas destrutíveis acompanham os materiais de cada região: selos de pedra da memória, blocos de arenito e raízes de âmbar. F (teclado) ou o botão BATER remove os selos após os golpes indicados; o combate contra inimigos continua fora desta etapa.

`lib/game/levels/stage_registry.dart` determina a ordem. Cada JSON declara o conteúdo variável e seus IDs estáveis. Uma alteração que afete a rota/tempo após publicar deverá incrementar `version` e separar futuros rankings por versão. As versões 1 das novas fases incluem os ajustes realizados durante esta autoria, ainda não publicados.

Checkpoints: `stage_02_cp_0` a `_4`, `stage_03_cp_0` a `_4`; metas `stage_02_goal` e `stage_03_goal`. Progresso de checkpoint é monotônico por ordem. IDs de Eco são únicos no prólogo; opcionais não bloqueiam a conclusão. Memórias vistas são compartilhadas na sessão; repetir uma tentativa não obriga rever conversas.

Tentativas locais contêm stageId/stageVersion/durationMs/deaths/collectibles/completed. Sem pontuação fictícia, upload, login ou ranking. `attemptId` é sequencial somente em RAM, não uma chave global para backend.

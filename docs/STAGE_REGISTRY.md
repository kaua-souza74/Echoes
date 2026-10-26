# ECHOES — catálogo V2.1

| ID | Título | Versão | Mundo px | Spawn (pés) | Próximo | Conclusão |
|---|---|---:|---|---|---|---|
| stage_01 | O Despertar | 2 | 11776×1024 | 64,384 | stage_02 | echo_heart + farol |
| stage_02 | Galerias Quebradas | 1 | 8448×2304 | 96,1792 | stage_03 | galleries_rupture + g_exit + farol |
| stage_03 | Torre do Eco | 1 | 2560×5632 | 384,5376 | encerramento | tower_memory + tower_last + t_final + farol |

`lib/game/levels/stage_registry.dart` determina a ordem. Cada JSON declara o conteúdo variável e seus IDs estáveis. Uma alteração que afete a rota/tempo após publicar deverá incrementar `version` e separar futuros rankings por versão. As versões 1 das novas fases incluem os ajustes realizados durante esta autoria, ainda não publicados.

Checkpoints: `stage_02_cp_0` a `_4`, `stage_03_cp_0` a `_4`; metas `stage_02_goal` e `stage_03_goal`. Progresso de checkpoint é monotônico por ordem. IDs de Eco são únicos no prólogo; opcionais não bloqueiam a conclusão. Memórias vistas são compartilhadas na sessão; repetir uma tentativa não obriga rever conversas.

Tentativas locais contêm stageId/stageVersion/durationMs/deaths/collectibles/completed. Sem pontuação fictícia, upload, login ou ranking. `attemptId` é sequencial somente em RAM, não uma chave global para backend.

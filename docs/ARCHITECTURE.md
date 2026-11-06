# Arquitetura ECHOES V2.2

## Aplicativo

main.dart valida configuração pública de build, inicializa Supabase e cria AppController. EchoesApplication mantém GoRouter com splash, login, cadastro, recuperação de senha, menu, fases, missão, gameplay, speedrun, conquistas, ranking, memórias, perfil e configurações. Rotas privadas exigem identidade autenticada; IDs inválidos e caminhos desconhecidos têm retorno seguro.

A sessão persistida pelo SDK é revalidada por getUser ao restaurar. EchoesBackend é o contrato; SupabaseBackend é a única implementação usada em produção. O fake está restrito a test/support/.

## Conta e sincronização

AppController guarda um snapshot do servidor e uma geração de conta. Trocar identidade limpa snapshot e fila; respostas de gerações antigas são ignoradas. PlayRoute captura também o proprietário da tentativa, impedindo envio de uma fase antiga na sessão seguinte.

Escritas são serializadas e identificadas por IDs estáveis. Erros deixam operações pendentes para repetir na mesma sessão. Pontos e desbloqueios permanentes só aparecem no snapshot depois da confirmação do servidor. O HUD representa a tentativa local. Não há fila offline durável: fechar o app ou sair descarta operações ainda pendentes.

Preferências têm rascunho e botão Salvar. Escala de texto é aplicada ao app; velocidade dos diálogos, cronômetro e redução de efeitos chegam ao jogo. Não existem controles de áudio para sistemas inexistentes.

## Flame

PlayRoute registra o início autenticado antes de criar EchoesGame. UUID identifica a tentativa no banco; PlaySession continua deduplicando registros locais. Coleta emite o ID original do Eco. Concluir, reiniciar ou abandonar produz no máximo um resultado por tentativa. O jogo não importa Supabase; callbacks são adaptados pela tela Flutter.

Física, mapas, câmera, temporárias, animações e assets anteriores foram mantidos. História congela física/relógio durante conversas e persiste IDs vistos inclusive ao pular. Speedrun omite conversas automáticas. AttemptClock usa Stopwatch monotônico; pausa/perda de foco invalida recorde, reinício cria outra tentativa.

Continuar retoma o capítulo disponível, sem restaurar a posição exata de uma sessão encerrada. Checkpoints continuam funcionando dentro da tentativa.

## Banco

Versões atuais: stage_01=2, stage_02=1, stage_03=1. Os 21 IDs originais não mudaram. StageRegistry carrega os mapas; StagePresentation descreve objetivos, dificuldade, categoria e recompensa.

score_ledger tem unicidade por usuário/origem/ID. Locks transacionais por usuário serializam recompensas. Primeira conclusão: 100 pontos; Eco único: 10. O cliente não envia pontuação total.

Wrappers públicos SECURITY INVOKER chamam funções SECURITY DEFINER no schema não exposto private. As funções usam search_path vazio, validam auth.uid, entrada, início, desbloqueio e versão. Grants de tabela são revogados antes das permissões mínimas; atualização direta é limitada a preferências e apelido próprios. RLS protege os demais dados.

Rankings são agregados PostgreSQL. Retornam Top 100 e a posição do próprio usuário, projetando somente UUID público, apelido, posição e resultado. E-mails ficam no Auth. Recordes são separados por versão e marcados não verificados: não existe simulação autoritativa do cliente.

## Narrativa

assets/narrative/memory_catalog.json continua a fonte dos 21 textos e três interações. supabase/tools/generate_memory_seed.py confere os mapas e gera o seed SQL. A tela lê conteúdo local, desbloqueando somente os IDs da conta; respostas aguardam confirmação por RPC.

DialogueController/Overlay/Panel/SpeakerPortrait foram preservados. O retrato PNG RGBA continua sobrepondo a borda. As memórias usam o primeiro frame do fragmento existente; ilustrações exclusivas são melhoria artística pendente.

## Verificação

Há regressões de física/travessia e testes de produto com backend simulado. PGlite executa PostgreSQL local para testar a migration, RLS, pontos, recordes, rankings e duas identidades locais. Isso não substitui Supabase Auth nem o fluxo remoto com duas contas confirmadas. Resultados exatos em TEST_PLAN.md.

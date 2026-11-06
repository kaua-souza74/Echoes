# Pontuação e classificação V2.2

Primeira conclusão de cada fase vale 100 pontos; cada um dos 21 Ecos únicos vale 10. Total possível do arco: 510. Repetir fase ou reenviar evento não duplica recompensa. Unicidade no ledger e locks transacionais por usuário fazem a deduplicação no servidor.

Ecos são registrados durante a tentativa, inclusive se ela for abandonada. Memórias e conquistas derivam de eventos aceitos. Concluir capítulo desbloqueia o seguinte. Contra o Tempo exige speedrun elegível em até 180 segundos.

## Tempo

Stopwatch monotônico começa ao ganhar controle e termina no objetivo. Duração é inteiro em milissegundos e a UI usa MM:SS.cc. Loading é excluído.

História pausa física/relógio durante conversas e pausas. Speedrun omite diálogos automáticos; pausa/perda de foco invalida a tentativa para recordes. Reiniciar cria UUID e início de servidor novos. Tentativas inválidas/interrompidas são incompletas e não entram em personal_bests.

O servidor exige início autenticado, fase desbloqueada, versão atual, duração positiva até 24 horas, mortes de 0 a 10000 e Ecos essenciais. Conclusões abaixo de 15/20/25 segundos nas fases 1/2/3 são recusadas, assim como duração acima do tempo de servidor desde o início, com 5 segundos de margem.

## Rankings

- Pontos: soma do ledger, maior primeiro.
- Ecos: quantidade de IDs únicos, maior primeiro.
- Speedrun por fase: menor melhor tempo da versão atual.
- Combinado: soma dos melhores tempos das três versões atuais; exige as três fases.

Empate usa a data de conquista mais antiga e depois UUID, com ordem determinística. A RPC retorna Top 100 e o próprio jogador mesmo fora dele. Top 3 tem destaque visual. Apenas UUID público, apelido, posição e resultado são projetados; nunca e-mail.

Recordes antigos permanecem no histórico pessoal, mas não participam da versão atual.

## Integridade

Todo tempo recebido do app tem verified=false e rótulo de não verificado. Um cliente alterado pode falsificar duração, coletas e conclusão; não existe validação autoritativa da física.

RLS, agregados e recompensas passaram por testes PostgreSQL locais. Aplicação no Supabase externo e demonstração com duas contas reais permanecem pendentes.

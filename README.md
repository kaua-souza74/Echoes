# ECHOES · O Vale das Vozes

Plataforma narrativa original em Flutter + Flame com três capítulos, 21 Ecos, 15 checkpoints e 14 conversas. A implementação V2.2 adiciona Supabase Auth, GoRouter, missões, menus, perfil, preferências por conta, memórias educativas, conquistas, speedrun e consultas PostgreSQL de classificação.

**O setup SQL do Supabase foi aplicado e o catálogo público foi confirmado pela API.** Falta validar cadastro/login e progresso com contas reais. A aplicação usa exclusivamente Supabase; o backend simulado existe somente nos testes. Não há jogadores ou pontuações fictícios na classificação de produção.

## Executar

Flutter 3.38.9 / Dart 3.10.8. Dependências fixadas: Flame 1.35.1, Supabase Flutter 2.18.3, GoRouter 17.5.0 e UUID 4.6.0.

```powershell
cd flutter_app
flutter run
```

A URL e a chave pública anon do Supabase do projeto estão incluídas como padrões do cliente, então não é necessário passar argumentos adicionais. `--dart-define` ainda pode sobrescrever esses valores. A chave é pública por projeto; os grants e as políticas RLS limitam o acesso às tabelas privadas. O SQL foi aplicado e a API pública já respondeu com os dados de catálogo do seed. O Auth permite cadastro por e-mail e está configurado com confirmação automática; o fluxo completo de cadastro/login ainda precisa ser exercitado no app.

## Jogar

A/D ou setas: mover. Espaço: salto variável. Shift: dash. R: checkpoint. Empurre uma parede para deslizar e pule para sair. Há controles de toque. Espaço/Enter/toque revelam e avançam diálogos; Esc/Pular encerra a conversa. O retrato transparente foi preservado.

História exclui loading, pausas e diálogos do tempo ativo. Speedrun omite diálogos automáticos; pausa/perda de foco invalida a tentativa para recordes. Tempos do cliente são explicitamente **não verificados**. Veja [RANKING_RULES](docs/RANKING_RULES.md).

Continuar abre o capítulo disponível; não restaura a posição exata de uma sessão fechada. Ecos, memórias, conversas vistas, conclusões, conquistas, preferências e recordes pertencem à conta. Operações sem confirmação aparecem como pendentes; a fila atual fica em memória e é descartada ao fechar o app ou sair da conta.

## Verificar e distribuir

```powershell
cd flutter_app
flutter analyze
flutter test
flutter build web
flutter build windows
```

Resultados exatos: [TEST_PLAN](docs/TEST_PLAN.md) e [DEVELOPMENT_LOG](docs/DEVELOPMENT_LOG.md). Android não está validado.

Preview Web com fallback das URLs do GoRouter: `python tools/serve_web.py --port 18768`, a partir da raiz. O servidor só escuta em 127.0.0.1. Hosting Web deve reescrever rotas como /login para index.html. Distribua a pasta Windows Release inteira.

O ZIP escolar limitado a lib/ e pubspec.yaml não executa sozinho: Flame depende também de assets/, dependências resolvidas e arquivos de plataforma. Mantenha o projeto completo com a arte; exclua configuração local e caches do pacote público. Não foi feito push nem publicação.

O GDD original, mapas e arte anteriores foram preservados. Consulte [ARCHITECTURE](docs/ARCHITECTURE.md), [EDUCATIONAL_DESIGN](docs/EDUCATIONAL_DESIGN.md), [LEVEL_DESIGN](docs/LEVEL_DESIGN.md) e os handoffs em docs/.

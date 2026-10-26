# Supabase — estado da integração

A integração de contas e banco ainda não foi implementada neste marco B/C. Não há migrations aplicadas, schema V2 validado, sessões de usuário ou resultados remotos. Os dados de fase e narrativa são assets locais; progresso e memórias vistas são mantidos na sessão.

O briefing V2 trouxe placeholders no bloco final. A conversa anterior contém uma URL de projeto e uma chave pública anon que podem ser usadas na etapa F. Nenhuma chave administrativa é necessária no Flutter. A configuração será carregada com `--dart-define-from-file`; arquivos locais de configuração deverão ficar fora do controle de versão.

Antes de declarar a integração pronta: consultar a documentação atual; preparar migrations versionadas, constraints, RLS e RPCs de conclusão; obter acesso administrativo autorizado ou entregar SQL para o responsável aplicar; testar autenticação e isolamento com duas contas; verificar pontos idempotentes, melhores tempos e rankings no PostgreSQL real. A aplicação remota de SQL não foi tentada nesta etapa.

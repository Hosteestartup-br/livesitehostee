/*
  # Remover Empresas de Demonstração

  Este script remove todas as empresas cadastradas manualmente e dados de demonstração
  do banco de dados, mantendo apenas a estrutura.

  ## O que será removido:
    1. Todas as notificações
    2. Todas as avaliações
    3. Todos os agendamentos
    4. Todos os serviços
    5. Todas as empresas (cadastradas na tabela empresas)
    6. Todos os usuários demo (cliente@demo.com e empresa@demo.com)

  ## O que será mantido:
    - Estrutura de todas as tabelas
    - Todas as políticas RLS
    - Todos os índices
    - Todas as funções e triggers

  ## Como usar:
    1. Acesse o SQL Editor do Supabase
    2. Cole este script completo
    3. Execute o script
    4. Verifique os resultados

  IMPORTANTE: Esta ação NÃO pode ser desfeita! Certifique-se de que deseja remover
  todos os dados de demonstração antes de executar.
*/

-- Desabilitar triggers temporariamente para facilitar a remoção
SET session_replication_role = replica;

-- Remover notificações
DELETE FROM notificacoes;

-- Remover avaliações
DELETE FROM avaliacoes;

-- Remover agendamentos
DELETE FROM agendamentos;

-- Remover serviços
DELETE FROM servicos;

-- Remover empresas (tabela de listagem pública)
DELETE FROM empresas;

-- Remover usuários demo
DELETE FROM usuarios WHERE email IN ('cliente@demo.com', 'empresa@demo.com');

-- Reabilitar triggers
SET session_replication_role = DEFAULT;

-- Verificações finais
SELECT
  'DADOS REMOVIDOS COM SUCESSO!' as status,
  '' as tabela,
  '' as total
UNION ALL
SELECT '', 'notificacoes', COUNT(*)::text FROM notificacoes
UNION ALL
SELECT '', 'avaliacoes', COUNT(*)::text FROM avaliacoes
UNION ALL
SELECT '', 'agendamentos', COUNT(*)::text FROM agendamentos
UNION ALL
SELECT '', 'servicos', COUNT(*)::text FROM servicos
UNION ALL
SELECT '', 'empresas', COUNT(*)::text FROM empresas
UNION ALL
SELECT '', 'usuarios', COUNT(*)::text FROM usuarios;

-- Mensagem final
SELECT '✅ Todas as empresas de demonstração foram removidas!' as resultado;
SELECT '✅ O banco está limpo e pronto para dados reais!' as status;
SELECT '⚠️  Você pode criar novos usuários através da página de cadastro' as proximos_passos;

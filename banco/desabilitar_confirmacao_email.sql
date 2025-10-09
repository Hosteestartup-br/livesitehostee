/*
  # Desabilitar Confirmação de Email no Supabase

  ## Problema
  - Após cadastro, usuários não conseguem fazer login
  - Mensagem: "Email ou senha incorretos"
  - Causa: Confirmação de email está habilitada

  ## Solução
  Este script não pode desabilitar a confirmação de email via SQL.
  Você precisa fazer isso manualmente no Dashboard do Supabase.

  ## INSTRUÇÕES MANUAIS (IMPORTANTE!)

  ### Passo 1: Acessar as Configurações de Autenticação
  1. Abra o Supabase Dashboard: https://app.supabase.com
  2. Selecione seu projeto
  3. No menu lateral, clique em **Authentication**
  4. Clique na aba **Settings** (ou **Configurações**)

  ### Passo 2: Desabilitar Confirmação de Email
  1. Procure a seção **Email Auth** ou **Auth Settings**
  2. Encontre a opção: **"Enable email confirmations"** ou **"Confirm email"**
  3. **DESABILITE** esta opção (toggle OFF)
  4. Clique em **Save** para salvar as alterações

  ### Passo 3: Verificar Configuração
  Após desabilitar, verifique se:
  - ✅ "Enable email confirmations" está OFF
  - ✅ Novos usuários podem fazer login imediatamente após cadastro
  - ✅ Não é necessário confirmar email

  ## Alternativa: Confirmar Usuários Existentes via SQL

  Se preferir manter a confirmação de email habilitada mas confirmar
  os usuários existentes manualmente, execute este SQL:
*/

-- ATENÇÃO: Este SQL confirma TODOS os usuários não confirmados
-- Use com cuidado em produção!

UPDATE auth.users
SET email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

/*
  ## Verificação

  Para verificar se há usuários não confirmados:
*/

SELECT
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

/*
  ## Recomendação

  Para ambientes de desenvolvimento/teste:
  ✅ DESABILITE a confirmação de email no Dashboard

  Para ambientes de produção:
  ⚠️ Mantenha a confirmação habilitada para segurança
  ⚠️ Configure um servidor SMTP válido
  ⚠️ Personalize os templates de email

  ## Notas Importantes

  1. Desabilitar confirmação de email significa:
     - Usuários podem fazer login imediatamente
     - Não há verificação se o email é válido
     - Qualquer pessoa pode criar conta com qualquer email

  2. Se estiver em produção, considere:
     - Configurar SMTP para envio de emails
     - Manter confirmação habilitada
     - Usar o SQL acima apenas para casos específicos

  3. Após desabilitar:
     - Novos cadastros funcionarão imediatamente
     - Não é necessário confirmar email
     - Login funcionará após cadastro
*/

-- Mensagem final
SELECT '⚠️ LEIA AS INSTRUÇÕES ACIMA!' as importante;
SELECT 'Você precisa desabilitar confirmação de email no Dashboard do Supabase' as acao;
SELECT 'Authentication → Settings → Enable email confirmations → OFF' as caminho;

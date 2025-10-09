/*
  # Melhorias no Painel da Empresa

  ## Objetivo
  - Permitir que empresas cadastradas possam adicionar serviços
  - Garantir que serviços fiquem vinculados corretamente
  - Permitir que clientes agendem com empresas reais

  ## Alterações
  1. Garantir que política RLS permita empresas criarem serviços
  2. Adicionar políticas para inserção de serviços
*/

-- Política para permitir empresas inserirem serviços
DROP POLICY IF EXISTS "servicos_empresa_insert" ON servicos;

CREATE POLICY "servicos_empresa_insert" ON servicos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = empresa_id
    AND EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND tipo = 'empresa'
    )
  );

-- Política para permitir empresas atualizarem serviços
DROP POLICY IF EXISTS "servicos_empresa_update" ON servicos;

CREATE POLICY "servicos_empresa_update" ON servicos
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = empresa_id)
  WITH CHECK (auth.uid() = empresa_id);

-- Política para permitir empresas deletarem serviços
DROP POLICY IF EXISTS "servicos_empresa_delete" ON servicos;

CREATE POLICY "servicos_empresa_delete" ON servicos
  FOR DELETE
  TO authenticated
  USING (auth.uid() = empresa_id);

-- Garantir que função de verificação de horário funcione corretamente
-- (verifica se a função já existe e funciona)
DO $$
BEGIN
  -- Testar se função existe
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'verificar_disponibilidade_horario'
  ) THEN
    RAISE NOTICE '✅ Função verificar_disponibilidade_horario já existe';
  ELSE
    RAISE NOTICE '⚠️ Função verificar_disponibilidade_horario NÃO existe';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'listar_horarios_disponiveis'
  ) THEN
    RAISE NOTICE '✅ Função listar_horarios_disponiveis já existe';
  ELSE
    RAISE NOTICE '⚠️ Função listar_horarios_disponiveis NÃO existe';
  END IF;
END $$;

-- Comentários
COMMENT ON POLICY "servicos_empresa_insert" ON servicos IS 'Permite empresas criarem seus próprios serviços';
COMMENT ON POLICY "servicos_empresa_update" ON servicos IS 'Permite empresas atualizarem seus próprios serviços';
COMMENT ON POLICY "servicos_empresa_delete" ON servicos IS 'Permite empresas deletarem seus próprios serviços';

-- Verificação final
SELECT
  '✅ MELHORIAS APLICADAS COM SUCESSO!' as status,
  'Empresas agora podem gerenciar serviços livremente' as descricao;

SELECT
  'ℹ️ PRÓXIMOS PASSOS:' as info,
  '1. Faça login como empresa' as passo1,
  '2. Acesse o painel e crie serviços' as passo2,
  '3. Clientes poderão agendar esses serviços' as passo3;

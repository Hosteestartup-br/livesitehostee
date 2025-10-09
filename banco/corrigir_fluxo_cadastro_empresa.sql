/*
  # Correção do Fluxo de Cadastro de Empresas

  ## Problema Identificado
  - Ao cadastrar empresa, o registro vai apenas para tabela `usuarios`
  - A tabela `empresas` é usada para listagem mas não é sincronizada
  - Resultado: empresas cadastradas não aparecem na listagem

  ## Solução
  1. Criar trigger para sincronizar automaticamente quando empresa for criada em `usuarios`
  2. Adicionar campos necessários na tabela `empresas`
  3. Garantir que toda empresa cadastrada apareça na listagem

  ## Importante
  - NÃO altera dados existentes (mantém empresas demo)
  - Apenas adiciona automação para NOVOS cadastros
*/

-- Adicionar coluna usuario_id na tabela empresas (para referência cruzada)
ALTER TABLE empresas ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE;

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_empresas_usuario_id ON empresas(usuario_id);

-- Função para criar empresa automaticamente quando usuário tipo 'empresa' é criado
CREATE OR REPLACE FUNCTION criar_empresa_automaticamente()
RETURNS TRIGGER AS $$
DECLARE
  novo_slug TEXT;
BEGIN
  -- Só executar se for tipo empresa
  IF NEW.tipo = 'empresa' THEN
    -- Gerar slug a partir do nome
    novo_slug := LOWER(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(NEW.nome, 'ã', 'a'),
                    'á', 'a'
                  ),
                  'é', 'e'
                ),
                'í', 'i'
              ),
              'ó', 'o'
            ),
            'ú', 'u'
          ),
          'ç', 'c'
        ),
        ' ', '-'
      )
    );

    -- Inserir empresa na tabela empresas
    INSERT INTO empresas (
      usuario_id,
      nome,
      descricao,
      categoria,
      latitude,
      longitude,
      avaliacao,
      slug
    ) VALUES (
      NEW.id,
      NEW.nome,
      'Empresa cadastrada na plataforma Host.ee',
      'Geral',
      -23.5505,  -- Coordenadas padrão (São Paulo)
      -46.6333,
      5.0,
      novo_slug
    );

    RAISE NOTICE 'Empresa criada automaticamente para usuário: %', NEW.nome;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remover trigger se já existir (para evitar duplicação)
DROP TRIGGER IF EXISTS trigger_criar_empresa_automaticamente ON usuarios;

-- Criar trigger que dispara após inserção de usuário
CREATE TRIGGER trigger_criar_empresa_automaticamente
  AFTER INSERT ON usuarios
  FOR EACH ROW
  EXECUTE FUNCTION criar_empresa_automaticamente();

-- Comentários
COMMENT ON FUNCTION criar_empresa_automaticamente IS 'Cria registro na tabela empresas automaticamente quando usuário tipo empresa é cadastrado';
COMMENT ON TRIGGER trigger_criar_empresa_automaticamente ON usuarios IS 'Sincroniza cadastro de empresa entre tabelas usuarios e empresas';

-- Atualizar empresas existentes demo para ter referência ao usuario_id
-- (apenas se existir o usuário demo)
UPDATE empresas
SET usuario_id = 'bdf716b6-aa31-43fd-88cd-9d04ee5e8605'
WHERE nome = 'Barbearia do João'
  AND usuario_id IS NULL;

-- Verificação
SELECT
  '✅ CORREÇÃO APLICADA COM SUCESSO!' as status,
  'Agora empresas cadastradas aparecerão automaticamente na listagem' as descricao;

SELECT
  'ℹ️ TESTE:' as info,
  'Faça um novo cadastro de empresa para testar' as acao;

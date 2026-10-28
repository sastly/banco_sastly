-- Script de referência para os módulos de exemplo (Login e Gestão de Desvios).
-- Ajuste/estenda conforme os demais módulos (Empresa, Obras, Colaboradores, Ocorrências) forem implementados.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS empresas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  razao_social VARCHAR(255) NOT NULL,
  cnpj VARCHAR(18) NOT NULL UNIQUE,
  logotipo_url TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  senha_hash TEXT NOT NULL,
  perfil VARCHAR(20) NOT NULL CHECK (perfil IN ('Admin', 'TST', 'Gestor', 'Colaborador')),
  empresa_id UUID NOT NULL REFERENCES empresas(id),
  ativo BOOLEAN NOT NULL DEFAULT true,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tokens_recuperacao_senha (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expira_em TIMESTAMPTZ NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS obras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(255) NOT NULL,
  endereco TEXT NOT NULL,
  status VARCHAR(20) NOT NULL CHECK (status IN ('Ativa', 'Concluida', 'Pausada')),
  empresa_id UUID NOT NULL REFERENCES empresas(id),
  responsavel_tecnico_id UUID REFERENCES usuarios(id),
  responsavel_sst_id UUID REFERENCES usuarios(id),
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Empresas Contratadas vinculadas a uma Obra (N:N)
CREATE TABLE IF NOT EXISTS obra_empresas_contratadas (
  obra_id UUID NOT NULL REFERENCES obras(id) ON DELETE CASCADE,
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  vinculada_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (obra_id, empresa_id)
);

CREATE TABLE IF NOT EXISTS colaboradores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(255) NOT NULL,
  matricula VARCHAR(50) NOT NULL,
  funcao VARCHAR(100) NOT NULL,
  empresa_id UUID NOT NULL REFERENCES empresas(id),
  status VARCHAR(20) NOT NULL DEFAULT 'Ativo' CHECK (status IN ('Ativo', 'Inativo')),
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Obras associadas a um Colaborador (N:N)
CREATE TABLE IF NOT EXISTS colaborador_obras (
  colaborador_id UUID NOT NULL REFERENCES colaboradores(id) ON DELETE CASCADE,
  obra_id UUID NOT NULL REFERENCES obras(id) ON DELETE CASCADE,
  associado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (colaborador_id, obra_id)
);

CREATE TABLE IF NOT EXISTS desvios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  obra_id UUID NOT NULL REFERENCES obras(id),
  local_setor VARCHAR(255) NOT NULL,
  data_hora_ocorrencia TIMESTAMPTZ NOT NULL,
  colaborador_envolvido_id UUID NOT NULL REFERENCES colaboradores(id),
  categoria VARCHAR(30) NOT NULL,
  classificacao_risco VARCHAR(20) NOT NULL CHECK (classificacao_risco IN ('Baixo', 'Medio', 'Alto', 'Critico')),
  descricao_resumida TEXT NOT NULL,
  orientacao TEXT,
  status VARCHAR(30) NOT NULL DEFAULT 'Aguardando_Ciencia',
  ciencia JSONB,
  validacao JSONB,
  registrado_por_usuario_id UUID NOT NULL REFERENCES usuarios(id),
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_desvios_status ON desvios(status);
CREATE INDEX IF NOT EXISTS idx_desvios_categoria ON desvios(categoria);
CREATE INDEX IF NOT EXISTS idx_desvios_risco ON desvios(classificacao_risco);

-- Registro de Ocorrências e Acidentes
CREATE TABLE IF NOT EXISTS ocorrencias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  obra_id UUID NOT NULL REFERENCES obras(id),
  tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Incidente', 'Acidente')),
  data_hora_evento TIMESTAMPTZ NOT NULL,
  local_evento VARCHAR(255) NOT NULL,
  descricao_evento TEXT NOT NULL,
  lesoes JSONB NOT NULL DEFAULT '[]'::jsonb,
  testemunhas JSONB NOT NULL DEFAULT '[]'::jsonb,
  atendimento_medico JSONB,
  emissao_cat JSONB,
  arvore_de_causas JSONB NOT NULL DEFAULT '[]'::jsonb,
  acoes_corretivas JSONB NOT NULL DEFAULT '[]'::jsonb,
  registrado_por_usuario_id UUID NOT NULL REFERENCES usuarios(id),
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ocorrencias_tipo ON ocorrencias(tipo);
CREATE INDEX IF NOT EXISTS idx_ocorrencias_obra ON ocorrencias(obra_id);
CREATE INDEX IF NOT EXISTS idx_ocorrencias_lesoes ON ocorrencias USING gin (lesoes);

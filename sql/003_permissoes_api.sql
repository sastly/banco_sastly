-- Executar com a conta administrativa apos 001_schema_base.sql, conectado a sastly.
-- Privilegios de operacao exigidos pela API atual; nenhum privilegio de DDL.
-- DELETE permanece onde a API o utiliza. Preservacao de historico ainda
-- exige substituir os fluxos de exclusao: este script nao resolve isso.

BEGIN;

DO $$
BEGIN
  IF current_database() <> 'sastly' THEN
    RAISE EXCEPTION 'Conecte ao banco sastly antes de aplicar as permissoes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sastly_app') THEN
    RAISE EXCEPTION 'A conta sastly_app precisa existir antes desta migracao';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_roles
    WHERE rolname = 'sastly_app' AND (rolsuper OR rolbypassrls)
  ) THEN
    RAISE EXCEPTION 'sastly_app nao deve ser superusuario nem possuir BYPASSRLS';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_roles r ON r.oid = c.relowner
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE r.rolname = 'sastly_app' AND n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
  ) THEN
    RAISE EXCEPTION 'As tabelas devem pertencer a conta administrativa, nao a sastly_app';
  END IF;
END;
$$;

GRANT CONNECT ON DATABASE sastly TO sastly_app;
GRANT USAGE ON SCHEMA public TO sastly_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.empresas, public.usuarios, public.obras,
  public.colaboradores, public.desvios, public.ocorrencias
TO sastly_app;

GRANT SELECT, INSERT, DELETE ON TABLE
  public.tokens_recuperacao_senha,
  public.obra_empresas_contratadas,
  public.colaborador_obras
TO sastly_app;

COMMIT;

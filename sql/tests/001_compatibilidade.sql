-- Contratos SQL usados pela API, com dados ficticios e rollback ao final.
-- Executar com conta administrativa; os testes operam como sastly_app.
BEGIN;
SET LOCAL ROLE sastly_app;

DO $$
<<verificacao>>
DECLARE
  principal_id UUID := gen_random_uuid();
  contratada_id UUID := gen_random_uuid();
  usuario_id UUID := gen_random_uuid();
  obra_a UUID := gen_random_uuid();
  obra_b UUID := gen_random_uuid();
  obra_pausada UUID := gen_random_uuid();
  colaborador_id UUID := gen_random_uuid();
  proprio_id UUID := gen_random_uuid();
  inativo_id UUID := gen_random_uuid();
  desvio_id UUID := gen_random_uuid();
  ocorrencia_id UUID := gen_random_uuid();
  senha_teste TEXT := crypt('senha-ficticia-apenas-teste', gen_salt('bf', 10));
  token_teste TEXT := gen_random_uuid()::text;
  total_vinculos INTEGER;
BEGIN
  IF current_user <> 'sastly_app' THEN
    RAISE EXCEPTION 'Teste deve executar como sastly_app';
  END IF;
  IF has_schema_privilege(current_user, 'public', 'CREATE') THEN
    RAISE EXCEPTION 'sastly_app nao deve poder criar objetos no esquema public';
  END IF;
  IF has_database_privilege(current_user, current_database(), 'CREATE') THEN
    RAISE EXCEPTION 'sastly_app nao deve poder criar esquemas';
  END IF;
  IF has_table_privilege(current_user, 'public.ocorrencias', 'TRUNCATE') THEN
    RAISE EXCEPTION 'sastly_app nao deve possuir TRUNCATE';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ocorrencias' AND column_name = 'status'
  ) THEN
    RAISE EXCEPTION 'A estrutura inicial nao possui status de ocorrencia';
  END IF;
  IF to_regclass('public.vw_colaboradores_resumo_obras') IS NOT NULL THEN
    RAISE EXCEPTION 'A view adicional nao pertence a estrutura inicial';
  END IF;

  INSERT INTO public.empresas (id, razao_social, cnpj)
  -- Identificadores sinteticos exclusivos do teste, sem validade fiscal.
  VALUES (principal_id, 'EMPRESA FICTICIA DE TESTE', left(principal_id::text, 18)),
         (contratada_id, 'CONTRATADA FICTICIA DE TESTE', left(contratada_id::text, 18));

  INSERT INTO public.usuarios (id, nome, email, senha_hash, perfil, empresa_id)
  VALUES (usuario_id, 'Usuario ficticio', usuario_id::text || '@example.invalid',
          senha_teste, 'TST', principal_id);
  IF NOT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = usuario_id AND ativo
      AND senha_hash = crypt('senha-ficticia-apenas-teste', senha_hash)
  ) THEN
    RAISE EXCEPTION 'Falha na persistencia de usuario/hash';
  END IF;

  INSERT INTO public.tokens_recuperacao_senha (usuario_id, token, expira_em)
  VALUES (usuario_id, token_teste, now() + interval '30 minutes');
  IF NOT EXISTS (SELECT 1 FROM public.tokens_recuperacao_senha
                 WHERE token = token_teste AND expira_em > now()) THEN
    RAISE EXCEPTION 'Falha na persistencia do token';
  END IF;
  DELETE FROM public.tokens_recuperacao_senha WHERE token = token_teste;

  INSERT INTO public.obras (id, nome, endereco, status, empresa_id, responsavel_sst_id)
  VALUES (obra_a, 'Obra ficticia A', 'Endereco de teste', 'Ativa', principal_id, usuario_id),
         (obra_b, 'Obra ficticia B', 'Endereco de teste', 'Ativa', principal_id, usuario_id),
         (obra_pausada, 'Obra ficticia pausada', 'Endereco de teste', 'Pausada', principal_id, usuario_id);

  INSERT INTO public.obra_empresas_contratadas (obra_id, empresa_id)
  VALUES (obra_a, contratada_id), (obra_b, contratada_id), (obra_pausada, contratada_id);

  INSERT INTO public.colaboradores (id, nome, matricula, funcao, empresa_id, status)
  VALUES (colaborador_id, 'Colaborador ficticio contratado', 'TESTE-1', 'Teste', contratada_id, 'Ativo'),
         (proprio_id, 'Colaborador ficticio proprio', 'TESTE-2', 'Teste', principal_id, 'Ativo'),
         (inativo_id, 'Colaborador ficticio inativo', 'TESTE-3', 'Teste', principal_id, 'Inativo');

  INSERT INTO public.colaborador_obras (colaborador_id, obra_id)
  VALUES (colaborador_id, obra_a), (colaborador_id, obra_b), (colaborador_id, obra_pausada),
         (proprio_id, obra_a), (proprio_id, obra_b);

  SELECT count(*) INTO total_vinculos FROM public.colaborador_obras co
  WHERE co.colaborador_id = verificacao.colaborador_id;
  IF total_vinculos <> 3 THEN
    RAISE EXCEPTION 'Colaborador contratado deve poder atuar em varias obras';
  END IF;
  SELECT count(*) INTO total_vinculos FROM public.colaborador_obras co
  WHERE co.colaborador_id = proprio_id;
  IF total_vinculos <> 2 THEN
    RAISE EXCEPTION 'Colaborador proprio deve poder atuar em varias obras';
  END IF;

  BEGIN
    INSERT INTO public.colaborador_obras (colaborador_id, obra_id) VALUES (colaborador_id, obra_a);
    RAISE EXCEPTION 'Vinculo duplicado deveria ser rejeitado';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  INSERT INTO public.desvios (
    id, obra_id, local_setor, data_hora_ocorrencia, colaborador_envolvido_id,
    categoria, classificacao_risco, descricao_resumida, orientacao,
    status, registrado_por_usuario_id
  ) VALUES (
    desvio_id, obra_a, 'Setor ficticio', now(), colaborador_id,
    'EPI', 'Medio', 'Descricao ficticia', 'Orientacao ficticia',
    'Aguardando_Ciencia', usuario_id
  );
  UPDATE public.desvios SET ciencia = '{"aceito":true}'::jsonb,
    status = 'Aguardando_Validacao_TST', atualizado_em = now() WHERE id = desvio_id;
  UPDATE public.desvios SET validacao = jsonb_build_object('aprovado', true, 'validadoPorUsuarioId', usuario_id),
    status = 'Validado', atualizado_em = now() WHERE id = desvio_id;
  BEGIN
    INSERT INTO public.desvios (
      obra_id, local_setor, data_hora_ocorrencia, colaborador_envolvido_id,
      categoria, classificacao_risco, descricao_resumida, registrado_por_usuario_id
    ) VALUES (obra_a, 'Setor ficticio', now(), NULL, 'EPI', 'Medio', 'Teste', usuario_id);
    RAISE EXCEPTION 'Desvio sem colaborador deveria ser rejeitado';
  EXCEPTION WHEN not_null_violation THEN NULL;
  END;
  BEGIN
    UPDATE public.desvios SET colaborador_envolvido_id = gen_random_uuid() WHERE id = desvio_id;
    RAISE EXCEPTION 'Desvio com colaborador inexistente deveria ser rejeitado';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  -- INSERT com os campos existentes na API e no esquema inicial.
  INSERT INTO public.ocorrencias (
    id, obra_id, tipo, data_hora_evento, local_evento, descricao_evento,
    lesoes, testemunhas, atendimento_medico, emissao_cat, arvore_de_causas,
    acoes_corretivas, registrado_por_usuario_id
  ) VALUES (
    ocorrencia_id, obra_a, 'Acidente', now(), 'Local ficticio', 'Evento ficticio',
    jsonb_build_array(jsonb_build_object('colaboradorId', colaborador_id)),
    '[]'::jsonb, 'null'::jsonb, 'null'::jsonb, '[]'::jsonb, '[]'::jsonb, usuario_id
  );
  IF NOT EXISTS (SELECT 1 FROM public.ocorrencias WHERE id = ocorrencia_id
    AND lesoes @> jsonb_build_array(jsonb_build_object('colaboradorId', colaborador_id))) THEN
    RAISE EXCEPTION 'Consulta de historico em JSON deve continuar funcionando';
  END IF;
  UPDATE public.ocorrencias SET descricao_evento = 'Atualizacao como a API', atualizado_em = now()
  WHERE id = ocorrencia_id;
  IF NOT EXISTS (SELECT 1 FROM public.ocorrencias WHERE id = ocorrencia_id
    AND descricao_evento = 'Atualizacao como a API') THEN
    RAISE EXCEPTION 'Atualizacao de ocorrencia deve persistir a descricao';
  END IF;

  RAISE NOTICE 'OK: esquema inicial, contratos SQL, permissoes, multiplas obras e colaborador obrigatorio.';
END;
$$;

ROLLBACK;

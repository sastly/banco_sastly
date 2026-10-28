param(
    [switch]$Aplicar,
    [string]$Psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Psql)) {
    throw 'Cliente psql nao encontrado.'
}

# A senha e lida pelo psql no pgpass.conf local; nao ler nem imprimir a senha.
$env:PGCONNECT_TIMEOUT = '5'
$env:PGAPPNAME = 'sastly-instalacao-local'
$env:PGOPTIONS = '-c default_transaction_read_only=off'

$sstMigrationNames = @(
    '001_schema_base.sql',
    '003_permissoes_api.sql'
)
$sstParts = foreach ($sstName in $sstMigrationNames) {
    $sstText = Get-Content -LiteralPath (Join-Path $PSScriptRoot $sstName) -Raw
    # O executor controla uma transacao unica para toda a instalacao.
    $sstText -replace '(?m)^(BEGIN|COMMIT);\r?$', ''
}
$sstTest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'tests\001_compatibilidade.sql') -Raw
$sstTest = $sstTest -replace '(?m)^(BEGIN|ROLLBACK);\r?$', ''

$sstPreflight = @'
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SELECT pg_advisory_xact_lock(187452019, 1);
DO $$
BEGIN
  IF current_database() <> 'sastly' OR current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Este instalador inicial exige postgres no banco sastly';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = ANY (ARRAY[
      'empresas', 'usuarios', 'tokens_recuperacao_senha', 'obras',
      'obra_empresas_contratadas', 'colaboradores', 'colaborador_obras',
      'desvios', 'ocorrencias', 'vw_colaboradores_resumo_obras'
    ])
  ) THEN
    RAISE EXCEPTION 'Estrutura ja existente: interrompido para evitar alteracao de instalacao anterior';
  END IF;
END;
$$;
'@

$sstEnding = if ($Aplicar) { 'COMMIT;' } else { 'ROLLBACK;' }
$sstBatch = $sstPreflight + "`n" + ($sstParts -join "`n") +
    "`nSAVEPOINT dados_de_teste;`n" + $sstTest +
    "`nROLLBACK TO SAVEPOINT dados_de_teste;`n" + $sstEnding

$sstBatch | & $Psql -X -w -h localhost -p 5432 -U postgres -d sastly -v ON_ERROR_STOP=1 -P pager=off -f -
if ($LASTEXITCODE -ne 0) {
    throw 'Instalacao/validacao falhou. A conexao foi encerrada e a transacao nao foi confirmada.'
}
if ($Aplicar) {
    Write-Output 'Estrutura aplicada; testes aprovados; dados ficticios descartados.'
} else {
    Write-Output 'Validacao aprovada; transacao desfeita; nenhuma estrutura ou dado de teste persistido.'
}

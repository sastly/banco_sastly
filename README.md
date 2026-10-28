# Banco Sastly

Pacote independente do banco PostgreSQL do prototipo Sastly. Preparado em
2026-10-27 a partir dos arquivos locais de `api_sastly/sql`, para futura
publicacao em um repositorio da organizacao.

Contem codigo SQL, executor PowerShell, teste SQL e documentacao. Nao contem
credenciais, dados de clientes, dumps, dependencias Node.js, API ou frontend.
Nenhum repositorio Git foi inicializado nem publicado nesta preparacao.

## Estrutura

```text
banco_sastly/
  README.md
  .gitignore
  .gitattributes
  sql/
    001_schema_base.sql
    003_permissoes_api.sql
    Aplicar-Banco.ps1
    tests/001_compatibilidade.sql
  docs/
    INSTALACAO.md
    ESTADO_E_LIMITACOES.md
  historico/
    README.md
    adiados/002_status_ocorrencias_e_vinculos.sql.txt
    reversoes/002_retorno_schema_inicial.sql.txt
```

## O que executar

Somente o executor `sql/Aplicar-Banco.ps1` para uma instalacao inicial em banco
vazio, depois de atender aos [pre-requisitos](docs/INSTALACAO.md).
Ele aplica explicitamente 001 e 003, nessa ordem. Sem `-Aplicar`, valida e
desfaz a transacao; com `-Aplicar`, confirma a estrutura, sem dados de teste.

**Nao executar a instalacao no banco local atual:** ele ja esta instalado.
O executor recusa as tabelas existentes; nao e um sistema de migracoes para
atualizar bancos que ja tenham dados.

A numeracao 002 esta reservada ao trabalho adiado. Nao renumerar 003 nem
executar todos os arquivos encontrados por uma busca recursiva.

## Publicacao futura

Esta pasta pode ser a raiz do futuro repositorio do banco. Antes de publicar:

1. Confirmar organizacao, nome do repositorio e visibilidade.
2. Revisar os arquivos selecionados e conferir que nao ha segredos nem dumps.
3. Inicializar o Git nesta pasta, adicionar somente estes arquivos e revisar
   o diff antes do primeiro commit.
4. Associar o remoto aprovado e publicar.

A pasta `.git` dos projetos API/web nao foi copiada. As alteracoes existentes
nesses projetos continuam separadas e nao precisam entrar no commit do banco.
Nao incluir `.env`, `pgpass.conf`, `.local/` ou arquivos de acesso demonstrativo.
O `.gitignore` e uma protecao auxiliar, nao substitui a revisao de segredos.

## Origem e manutencao

Os quatro arquivos ativos foram copiados sem mudancas de conteudo (exceto
normalizacao de fim de linha), preservando os contratos da API atual.
Os originais em `api_sastly/sql` foram mantidos. As duas pastas nao se
sincronizam automaticamente: ao adotar o repositorio separado, definir uma
unica fonte oficial e atualizar o procedimento de entrega da API.

O teste HTTP continua em `api_sastly/sql/tests/002_api_http.cjs`, pois depende
da API compilada e do ambiente local; nao foi incluido neste pacote SQL.
Veja [estado, testes e limitacoes](docs/ESTADO_E_LIMITACOES.md).

# Instalacao e verificacao

## Pre-requisitos (provisionamento separado)

O executor foi preparado para o ambiente local atual, nao para qualquer servidor:

- PostgreSQL 18, com suporte a extensao pgcrypto.
- Cliente psql; caminho padrao no Windows:
  `C:\Program Files\PostgreSQL\18\bin\psql.exe`.
- PowerShell.
- Servidor em localhost:5432; banco `sastly` existente e vazio para instalacao.
- Conta administrativa `postgres`, proprietaria das tabelas criadas.
- Conta de login `sastly_app` ja provisionada, sem superusuario, BYPASSRLS,
  propriedade das tabelas ou privilegios CREATE no banco/esquema public.
- Credencial administrativa configurada no arquivo privado do cliente psql:
  `%APPDATA%\postgresql\pgpass.conf` no Windows. Nao versionar esse arquivo.

O pacote nao cria servidor, banco, conta de login nem senha. A concessao de
permissoes em 003 adiciona DML; nao revoga privilegios elevados concedidos
anteriormente. O teste rejeita CREATE no banco/esquema e TRUNCATE nas ocorrencias.
O executor usa `-w`: nao solicita senha interativamente, falhando se faltar
uma credencial utilizavel.

## Validar em banco vazio sem persistir a estrutura

Na raiz deste pacote:

```powershell
.\sql\Aplicar-Banco.ps1
```

O executor verifica o destino, recusa tabelas da aplicacao existentes, cria
a estrutura em transacao e testa usando SET LOCAL ROLE sastly_app. Ao final
faz ROLLBACK. Uma falha encerra a conexao sem confirmar a instalacao.

## Aplicar em banco vazio

Somente depois de conferir o destino e aprovar a validacao:

```powershell
.\sql\Aplicar-Banco.ps1 -Aplicar
```

A instalacao confirma schema e permissoes em uma unica transacao. Os dados
ficticios de teste sao desfeitos antes do COMMIT. Nao e criado administrador
da aplicacao ou empresa demonstrativa.

Se o cliente estiver em outro caminho, passar `-Psql 'CAMINHO_DO_PSQL.exe'`.
Host, porta, banco e usuario estao fixos no executor atual; nao o usar para
outro destino sem revisar o codigo e suas verificacoes de seguranca.

## Verificar banco ja instalado

Nao reaplicar a instalacao. O teste abaixo executa operacoes temporarias e
faz rollback, sem apagar os cadastros existentes:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -w `
  -h localhost -p 5432 -U postgres -d sastly -v ON_ERROR_STOP=1 `
  -f .\sql\tests\001_compatibilidade.sql
```

O teste usa identificadores sinteticos sem validade fiscal. Ele nao valida
CNPJ nem substitui testes HTTP ou testes de interface.

## Cuidados

- Nao executar todos os SQLs recursivamente.
- 001 nao possui transacao propria: usar o executor para instalacao atomica.
- IF NOT EXISTS nao atualiza estruturas antigas.
- Nao aplicar os arquivos historicos no prototipo atual.
- Nunca usar a conta postgres na conexao normal da API.
- Nao utilizar dados reais antes de implementar as protecoes pendentes.

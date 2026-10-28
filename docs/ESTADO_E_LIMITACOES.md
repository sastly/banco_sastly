# Estado do banco e evidencias

## Modelo preservado

Esquema inicial compativel com a API local, com nove tabelas:
empresas, usuarios, tokens_recuperacao_senha, obras,
obra_empresas_contratadas, colaboradores, colaborador_obras, desvios e ocorrencias.

O desvio exige colaborador por NOT NULL e chave estrangeira. Os vinculos
permitem uma empresa contratada ou colaborador em mais de uma obra.
CNPJ de empresa e email de usuario sao unicos globalmente no modelo atual.
Nao ha validacao fiscal de CNPJ no banco.

O banco armazena senha_hash. Gerar/verificar o hash e responsabilidade da
API, que usa bcrypt. O esquema nao impede que um cliente incorreto grave
texto inadequado nesse campo; isso nao equivale a uma auditoria de seguranca.

## Testes locais em 2026-10-27

Antes da separacao deste pacote, no ambiente local de origem:

- SQL: aprovado o teste de contratos, permissoes, vinculos em varias obras,
  persistencia de hash e colaborador obrigatorio com integridade referencial.
- API: compilacao e testes de login/JWT aprovados.
- HTTP/API: criacao e consulta de obra/colaborador, vinculo, desvio com ciencia
  e validacao, e criacao/atualizacao de ocorrencia aprovadas.
- Persistencia confirmada diretamente no PostgreSQL.
- Dados transitorios desfeitos/removidos; preservados uma empresa e um Admin
  ficticios somente no banco local, nao neste pacote.
- Web compilou e respondeu HTTP 200 em seis rotas, mas ainda usa mocks.
  Lint da web reprovou; a interface nao foi testada visualmente.

Nesta separacao foram conferidos a integridade das copias e a sintaxe do
executor PowerShell. Nenhuma instalacao ou alteracao adicional no banco foi
executada para organizar a pasta. Isso nao representa instalacao validada
em outro computador; os pre-requisitos continuam necessarios.

## Pendencias antes de uso real

- RLS e isolamento completo entre organizacoes ainda nao implementados.
- Fluxo de status de ocorrencias ainda nao implementado no esquema inicial.
- Exclusoes fisicas continuam permitidas conforme a API atual; politica de
  historico, retencao e acesso a registros encerrados ainda precisa ser definida.
- Vinculos e validacoes adicionais de empresas/colaboradores estao pendentes.
- Integracao web/API, revisao de seguranca e requisitos de privacidade pendentes.

Este pacote e uma base de prototipo, nao uma declaracao de conformidade LGPD
nem uma liberacao para producao.

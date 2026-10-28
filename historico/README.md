# Referencia historica — nao executar

Estes arquivos foram preservados para consulta e rastreabilidade, fora da
pasta de instalacao. A extensao final `.txt` e intencional: nao sao migracoes
ativas e nao devem ser enviados automaticamente ao psql.

- `adiados/002_status_ocorrencias_e_vinculos.sql.txt`: proposta anterior de
  status/diagnostico/indices que foi adiada a pedido do responsavel pelo projeto.
- `reversoes/002_retorno_schema_inicial.sql.txt`: reversao usada anteriormente
  para voltar ao esquema inicial. Contem DROP; nao executar em uma instalacao
  nova nem repetir no banco atual. Qualquer reutilizacao exige revisao do
  destino, dependencias e dados, e autorizacao especifica.

O executor de instalacao nao le esta pasta.

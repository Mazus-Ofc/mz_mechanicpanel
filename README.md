# mz_mechanicpanel

Painel premium de mecânica para QBCore.

## O que faz
- Baia de mecânica configurável por oficina.
- Painel NUI na direita.
- Câmera real no veículo no mundo.
- Preview de mods antes de cobrar.
- Orçamento em tempo real.
- Aprovação e pagamento pelo proprietário do veículo.
- Logs de serviço e tabela de ordens com status completo.
- Reparos externos por item (repairkit, advancedrepairkit, tirerepairkit, cleaningkit, veh_toolbox).
- Liberação por job mecânico ou grupos admin/god do cfg.

## Dependências
- qb-core
- qb-inventory
- oxmysql

## Instalação
1. Coloque a pasta `mz_mechanicpanel` em `resources/[jobs]` ou similar.
2. O recurso já verifica e cria automaticamente as tabelas, colunas e índices faltantes ao iniciar.
3. Se quiser instalar manualmente do zero, rode o SQL de `sql/install.sql`.
4. Adicione `ensure mz_mechanicpanel` no `server.cfg`.
5. Ajuste `config/config.lua` e `config/prices.lua`.
6. Garanta que os itens de reparo já existam no seu inventário:
   - repairkit
   - advancedrepairkit
   - tirerepairkit
   - cleaningkit
   - veh_toolbox

## Status de ordens
- `pending` -> orçamento enviado e aguardando aprovação.
- `approved` -> aprovado e pago pelo proprietário ou bypass de admin.
- `declined` -> recusado pelo proprietário.
- `cancelled` -> sessão encerrada antes da conclusão.
- `expired` -> pedido expirou sem resposta.
- `completed` -> serviço salvo no veículo e ordem finalizada.

## Observações
- O recurso salva as props em `player_vehicles.mods` quando a ordem é aprovada e concluída.
- Para salvar corretamente, a tabela `player_vehicles` precisa ter pelo menos `plate`, `citizenid` e `mods`.
- Por padrão o painel só abre com o veículo na baia e vazio por dentro.
- O proprietário precisa estar perto para aprovar e pagar, salvo bypass de admin.
- Os logs agora salvam order_id, status, modelo do veículo, oficina e metadata do evento.

## Comandos
- `/mechpanel` -> tenta abrir o painel na baia atual.
- `/mechcancel` -> cancela a sessão atual e reverte o preview.

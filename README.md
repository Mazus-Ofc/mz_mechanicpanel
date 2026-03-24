# mz_mechanicpanel

Painel premium de mecânica para QBCore.

## O que faz
- Baia de mecânica configurável por oficina.
- Painel NUI na direita.
- Câmera real no veículo no mundo.
- Preview de mods antes de cobrar.
- Orçamento em tempo real.
- Aprovação e pagamento pelo proprietário do veículo.
- Logs de serviço e tabela de ordens.
- Reparos externos por item (repairkit, advancedrepairkit, tirerepairkit, cleaningkit, veh_toolbox).
- Liberação por job mecânico ou grupos admin/god do cfg.

## Dependências
- qb-core
- qb-inventory
- oxmysql

## Instalação
1. Coloque a pasta `mz_mechanicpanel` em `resources/[jobs]` ou similar.
2. Rode o SQL de `sql/install.sql`.
3. Adicione `ensure mz_mechanicpanel` no `server.cfg`.
4. Ajuste `config/config.lua` e `config/prices.lua`.
5. Garanta que os itens de reparo já existam no seu inventário:
   - repairkit
   - advancedrepairkit
   - tirerepairkit
   - cleaningkit
   - veh_toolbox

## Observações
- O recurso salva as props em `player_vehicles.mods` quando a ordem é aprovada.
- Para salvar corretamente, a tabela `player_vehicles` precisa ter pelo menos `plate`, `citizenid` e `mods`.
- Por padrão o painel só abre com o veículo na baia e vazio por dentro.
- O proprietário precisa estar perto para aprovar e pagar, salvo bypass de admin.

## Comandos
- `/mechpanel` -> tenta abrir o painel na baia atual.
- `/mechcancel` -> cancela a sessão atual e reverte o preview.

## Dica de produção
Comece com uma ou duas baias, teste o fluxo inteiro e depois expanda preços e categorias.

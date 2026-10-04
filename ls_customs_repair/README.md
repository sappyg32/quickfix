# ls_customs_repair

An ESX resource that adds an LS Customs repair shop with a map blip.

## Install
1. Drop the `ls_customs_repair` folder into your `resources/` directory.
2. Add `ensure ls_customs_repair` to your `server.cfg`.
3. Run `refresh` and `ensure ls_customs_repair` in the server console (or restart the server).

## Config
- Location: `client.lua` -> `shopCoords` (vec4 -210.93, -1323.63, 30.62, 213.57)
- Price: `client.lua` -> `repairPrice` (default 500)
- Blip name: `client.lua` -> `Repair Shop`

## Notes
- Payment uses ESX Legacy (`getMoney` / `removeMoney`). On an older ESX 1.1
  build, swap these for `getCash` / `removeCash` or `getAccount('bank')`.
- Only the driver of a vehicle can trigger the repair.
- The server validates the price and handles the money deduction, so the
  client cannot repair for free by spoofing the event.

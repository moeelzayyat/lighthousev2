-- Definitions domain (S5.1): the catalogs are checked here at boot. S5.4 adds `_Registry`, which validates
-- every catalog and refuses to boot on a bad definition; until then this phase only holds the slot in the order.

local Definitions = { Name = "Definitions" }

function Definitions.Init(_ctx) end

return Definitions

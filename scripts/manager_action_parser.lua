-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ability
--  action = CR, Attributes(e.g IQ, ST+1, etc.), DMG, etc.
--  desc = some description
--  roll = Target to roll against
--  mod = modifier to roll
--  startindex/endindex = index of ability within full string (for highlighting purposes).

-- ROLL
--    .sType
--    .sDesc
--    .aDice
--    .nMod
--    (Any other fields added as string -> string map, if possible)


local ATTRIBS = { 
    { "ST", "attributes.strength" },
    { "DX", "attributes.dexterity" },
    { "IQ", "attributes.intelligence" },
    { "HT", "attributes.health" },
    { "WILL", "attributes.will" },
    { "PER", "attributes.perception" }
  };
  
function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function lastCrBefore(sText, index)
  local last = 1;
  while true do
    local n = string.find(sText, "\n", last, true);
    if not n then return last; end
    if n > index then
      return last;
    end
    last = n + 1;
  end
end

function parseComponents(sText)
  local aAbilities = {};
  local last = 1;
  for w in string.gmatch(sText, "%[.-%]") do
    local i, j = string.find(sText, w, last, true);
    local action, target, mod = isAction(sText, i, j);
    if action then
      local ability = {};
      ability.action = action;
      ability.orig = string.sub(sText, i+1, j-1)
      local startOfLine = lastCrBefore(sText, i);
      ability.desc = trim(string.sub(sText, startOfLine, i-1));
      ability.target = target;
      ability.mod = mod;
      ability.startindex = i;
      ability.endindex = j + 1;
      table.insert(aAbilities, ability);
      last = j+1;
    end
  end
  return aAbilities;
end

function isAction(sText, i, j)
  local c1, c2, c3;
  local cmd = string.sub(sText, i+1, j-1);
  c1 = capture(cmd, "CR: ?(%d*)");
  if c1 then return "CR", c1; end
  for i, a in pairs(ATTRIBS) do
    if cmd == a[1] then return a[1]; end    -- [ST]
    c1, c2 = capture(cmd, a[1].."(%d+)([+-]?%d*)");   -- [ST5]
    if c1 then return a[1], c1 , c2; end
    c1, c2 = capture(cmd, a[1].."(%d*)([+-]%d+)");   -- [ST+2]
    if c1 then return a[1], c1 , c2; end
  end
  c1, c2 = capture(cmd, "(%d+)[dD]([+-]?%d*)")
  if c1 then return "DMG", c1, c2; end
end

function capture(sText, sPattern)
  for c1, c2, c3 in string.gmatch(sText, sPattern) do
    return c1, c2, c3
  end
end

function empty(s)
  if not s then return true; end
  return string.len(s) == 0;
end

function roll(type, desc, target, td, mod, dmg)
  local rRoll ={};
  rRoll.sType = type;
  rRoll.sDesc = desc;
  rRoll.nTarget = tostring(target);
  rRoll.sTargetDesc = td;
  rRoll.sDamage = dmg;
  rRoll.aDice = { "d6","d6","d6" };
  if (dmg) then
    local d ={};
    for i = 1, tonumber(target), 1 do d[i] = "d6"; end;
    rRoll.aDice = d;
  end
  rRoll.nMod = 0; 
  if not empty(mod) then rRoll.nMod = tonumber(mod); end
  return rRoll;
end


function doAction(dbNode, rActor, ability)
  if ability.action == "CR" then
    local rRoll = roll("ability", "[SELF CONTROL]", ability.target, ability.desc);
    ActionsManager.performAction(null, rActor, rRoll);
    return;
  end
  if ability.action == "DMG" then
    local rRoll = roll("damage", "[DAMAGE]", ability.target, "", ability.mod, ability.orig);
    ActionsManager.performAction(null, rActor, rRoll);
    return;
  end
  
  for i, a in pairs(ATTRIBS) do
    if ability.action == a[1] then
      local target = ability.target;
      if empty(target) then target = DB.getValue(dbNode, a[2]); end
      local rRoll = roll("ability", "[ATTRIBUTE]", target, ability.action, ability.mod);
      ActionsManager.performAction(null, rActor, rRoll);
      return;
    end
  end
  Debug.console("ERROR!!   Should not have gotten here:", ability);
end
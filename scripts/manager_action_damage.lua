-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


DICE_DEFAULT = 6;

function onInit()
	ActionsManager.registerResultHandler("damage", onDamage);
end

function onDamage(rSource, rTarget, rRoll)
  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  local nTotal = 0;

  local bAddMod = false;
  if GameSystem.actions[rRoll.sType] then
    bAddMod = GameSystem.actions[rRoll.sType].bAddMod;
  end

  -- Send the chat message
  local bShowMsg = true;
  if not rSource then
    bShowMsg = false;
  end
  
  if bShowMsg then
    local _, _, sOperator, nNum = parseDamage(rRoll.sDamage);
    
    rMessage.text = string.format("%s\n%s%s%s %s",
        (string.format("%s%s",(rTarget and string.format("%s || ",rTarget.sName) or ""), rMessage.text)),
        (rRoll.sWeapon or ""), 
        ((rRoll.sWeapon and rRoll.sWeapon ~= '' and rRoll.sMode and rRoll.sMode ~= '') and "\n" or ""), 
        (rRoll.sMode or ""), 
        (string.format("[%s]%s", (rRoll.sDamage or ""), (rRoll.nMod ~= 0 and string.format("(%s%d)",(rRoll.nMod > 0 and "+" or ""),rRoll.nMod) or "")) or "")
    );

    rMessage.diemodifier = 0;
    
    -- Calculate Damage 
    for _,v in ipairs(rRoll.aDice) do
      nTotal = nTotal + v.result;
    end
  
    local nMod = (bAddMod and rRoll.nMod or 0);
    if sOperator then 
      if (sOperator == "+") then
        nTotal = nTotal + (nNum or 0);
        rMessage.diemodifier = (nNum or 0) + nMod;
      elseif (sOperator == "-") then
        nTotal = nTotal - (nNum or 0);
        rMessage.diemodifier = -(nNum or 0) + nMod;
      elseif (sOperator == "x") then
        nTotal = nTotal * (nNum or 1);
        rMessage.diemodifier = 0;
      elseif (sOperator == "/") then
        nTotal = nTotal / (nNum or 1);
        rMessage.diemodifier = 0;
      end
    end
    nTotal = nTotal + nMod;
    Comm.deliverChatMessage(rMessage);

    -- Deliver Total Damage
    rMessage.type = "number";
    rMessage.icon = "action_damage";
    rMessage.text = string.format("Total [%s]%s", (rRoll.sDamage or ""), (rRoll.nMod ~= 0 and string.format("(%s%d)",(rRoll.nMod > 0 and "+" or ""),rRoll.nMod) or ""));
    rMessage.dice = {};
    rMessage.diemodifier = (nTotal > 0 and nTotal or 0);
    rMessage.dicedisplay = 0;
    Comm.deliverChatMessage(rMessage);
  end
end

-- Necessary because Lau's floor function always moves in the negative.
function tointeger(x)
    num = tonumber(x)
    return num < 0 and math.ceil( num ) or math.floor( num )
end

function applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
  -- Get health fields
  local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
  if sTargetType ~= "pc" and sTargetType ~= "ct" then
    return;
  end
  
  local nMultiplier = 1;
  local sDamageType;
  if string.find(sDamage, "cr]$") then
    sDamageType = "Crushing";
  elseif string.find(sDamage, "burn]$") then
    sDamageType = "Burning";
  elseif string.find(sDamage, "cor]$") then
    sDamageType = "Corrosion";
  elseif string.find(sDamage, "fat]$") then
    sDamageType = "Fatigue";
  elseif string.find(sDamage, "tox]$") then
    sDamageType = "Toxic";
  elseif string.find(sDamage, "cut]$") then
    nMultiplier = 1.5;
    sDamageType = "Cutting";
  elseif string.find(sDamage, "imp]$") then
    nMultiplier = 2;
    sDamageType = "Impaling";
  elseif string.find(sDamage, "pi]$") then
    nMultiplier = 1;
    sDamageType = "Piercing";
  elseif string.find(sDamage, "pi%-]$") then
    nMultiplier = 0.5;
    sDamageType = "Small Piercing";
  elseif string.find(sDamage, "pi%+]$") then
    nMultiplier = 1.5;
    sDamageType = "Large Piercing";
  elseif string.find(sDamage, "pi%+%+]$") then
    nMultiplier = 2;
    sDamageType = "Huge Piercing";
  end
  
  
  if sDamageType then
    local sIndent = "    ";
    local nDR = tonumber(DB.getValue(nodeTarget, "combat.dr", 0));
    local nOrigDR = nDR;
    local i, j = string.find(sDamage, "%(%d*%.?%d*%)");
    local nArmorDivisor = 1;
    local sNote1 = "";
    local sNote2 = "";
    local sNote3 = "";
    local sNote4 = "";
    if i then
      local sAdjustment = "reduced";
      nArmorDivisor = tonumber(string.sub(sDamage, i+1, j-1));
      nDR = tointeger(nDR / nArmorDivisor);    -- B378
      if nArmorDivisor < 1 then
        sAdjustment = "increased";
        if nDR == 0 then
          nDR = 1;
          sNote3 = "\n" .. sIndent .. "  (minimum of DR [1] for armor divisors less than 1 [B379])"
        end
      end
      sNote2 = "\n\n" .. sIndent ..  "* The original DR [" .. nOrigDR .. "] was " .. sAdjustment .. " to "..nDR.." by the armor divisor [" .. nArmorDivisor .. "].";
      sNote1 = "*";
    end
      
    local sMesg = "Do you wish to apply the damage roll \"" .. sDamage .. "  " .. nTotal .. "\" to the Torso using the Damage and Injury rules [B377-379]?\n";
    local nResult = tonumber((nTotal - nDR) * nMultiplier);
    if nResult < 1 and nResult > 0 then  -- Min 1pt damage for any fraction that makes it through DR [B379]
      nResult = 1;
      sNote4 = "*";
      sNote2 = "\n\n" .. sIndent ..  "* The minimum damage is 1 HP for any attack that penetrates DR.  [B379]" .. sNote2;
    end
    if nResult < 0 then
      nResult = 0;
    end
    nResult = tointeger(nResult);
    sMesg = sMesg .. "\n\nYes, apply " .. nResult .. " damage" .. sNote4 .. ".\n\n";
    sMesg = sMesg .. sIndent .. "( Damage Roll [" .. nTotal .. "] - Torso DR [" .. nDR .. "]" .. sNote1 .." )  X  modifier for " .. sDamageType .. " [" .. nMultiplier .. "]";
    sMesg = sMesg .. sNote2 .. sNote3;
    sMesg = sMesg .. "\n\nNo, just apply " .. nTotal .. " damage.";
    sMesg = sMesg .. "\n\nCancel, do not apply any damage.";
  
    local ans = Interface.dialogMessage(sMesg, "Apply Damage", "yesnocancel");
    if ans == "cancel" then
      return;
    elseif ans == "yes" then
      nTotal = nResult;
    end
  end

  local nHP, nCHP;
  if sTargetType == "pc" then
    nHP = DB.getValue(nodeTarget, "attributes.hitpoints", 0);
    nCHP = DB.getValue(nodeTarget, "attributes.hps", 0) - nTotal;
    DB.setValue(nodeTarget, "attributes.hps", "number", nCHP);
  else
    nHP = DB.getValue(nodeTarget, "attributes.hitpoints", 0);
    nCHP = DB.getValue(nodeTarget, "hps", 0) - nTotal;
    DB.setValue(nodeTarget, "hps", "number", nCHP);
  end
end

function parseDamage(s)
  -- SETUP
  local aDice = {};
  local nMod = 0;
  
  local nDieCount = 0;
  local nDice = 0;
  local sOperator = "";
  local nNum = 0
  
  -- PARSING
  if s then
    nDieCount, nDice, sOperator, nNum = s:match("^(%d*)[dD]([%dF]*)%s*([+-x]?)%s*([%dF]*)");
    
    if nDieCount then
      local sDie = string.format("d%d", (tonumber(nDice) or DICE_DEFAULT));
      
      for i = 1, nDieCount do
        table.insert(aDice, sDie);
      end
    end
    
    if sOperator and nNum then
      nNum = (tonumber(nNum) or 0);
    end
  end
  
  -- RESULTS
  return aDice, nMod, sOperator, nNum;
end


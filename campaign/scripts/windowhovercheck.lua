---- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
--
--

local bParsed = false;
local bEditing = false;
local aAbilities = {};
local hoverAbility;

function onInit()
--  Debug.console(window);
--  Debug.console(window.getDatabaseNode());
--  Debug.console(window.getMainNode());
--  Debug.console(window.getDatabaseNode().getParent().getParent());
--  Debug.console(window.getDatabaseNode().getParent().getParent().getParent());
--  Debug.console(ActorManager.getActor("pc", window.getDatabaseNode()));
--  Debug.console(ActorManager.getActor("pc", window.getDatabaseNode().getParent()));
--  Debug.console("PC/NPC");
--  Debug.console(ActorManager.getActor("npc", window.getDatabaseNode()));
--  Debug.console(ActorManager.getActor("npc", window.getDatabaseNode().getParent()));
end


function onValueChanged()
  bParsed = false;
  bEditing = false;
  --Debug.console("VALUE CHANGED");
end

function onClickDown()
  bEditing = true;
end

function onLoseFocus()
  bEditing = false;
end

-- Reset selection when the cursor leaves the control
function onHover(bOnControl)
  if bEditing or bOnControl then
    return;
  end

  hoverAbility = nil;
  setSelectionPosition(0);
end

function onHoverUpdate(x, y)
  if bEditing then
    setHoverCursor("arrow");
    return;
  end

  if not bParsed then
    aAbilities = ActionParser.parseComponents(getValue());
    bParsed = true;
  end
  local nMouseIndex = getIndexAt(x, y);
  hoverAbility = nil;

  for i = 1, #aAbilities do
    if aAbilities[i].startindex <= nMouseIndex and aAbilities[i].endindex > nMouseIndex then
      setCursorPosition(aAbilities[i].startindex);
      setSelectionPosition(aAbilities[i].endindex);
      hoverAbility = i;     
    end
  end
  
  if hoverAbility then
    setHoverCursor("hand");
  else
    setHoverCursor("arrow");
  end  
end

function onDoubleClick(x, y)
  if hoverAbility then
    local sType, rParent = window.getMainNode();
    local rActor = ActorManager.getActor(sType, rParent)
    ActionParser.doAction(rParent, rActor, aAbilities[hoverAbility]);
    bEditing = false;
    return true;
  end
end

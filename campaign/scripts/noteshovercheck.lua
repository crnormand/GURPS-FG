---- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
--
--
--
local bParsed = false;
local bEditing = false;
local aAbilities = {};
local hoverAbility;
local buttons = {};

function onInit()
  rebuild();
  Debug.console(window);
  Debug.console(window.getDatabaseNode());
  Debug.console(window.getDatabaseNode().getParent());
  Debug.console(window.getDatabaseNode().getParent().getParent());
  Debug.console(window.getDatabaseNode().getParent().getParent().getParent());
  Debug.console(ActorManager.getActor("pc", window.getDatabaseNode()));
  Debug.console(ActorManager.getActor("pc", window.getDatabaseNode().getParent().getParent().getParent()));
  Debug.console(window.text);
end

function onValueChanged()
  rebuild();
end

function rebuild()
  removeButtons(); 
  aAbilities = ActionParser.parseComponents(getValue());
  --buildButtons();
end

function buttonPressed()
  Debug.console("Now what?!?");
end

function buildButtons()
  if #aAbilities == 0 then return; end
  local parent = "text";
  for i, a in pairs(aAbilities) do
    local bn = "b"..i;
    Debug.console("Button", bn, a.orig);
    
    buttons[i] = window.createControl("notes_actions", bn);
    --buttons[i].setAnchor("top", parent, "bottom", "relative");
    parent = bn;
    buttons[i].setText(a.orig);
   end
end

function removeButtons()
  if #buttons == 0 then return; end
  for i, b in pairs(buttons) do
    b.destroy();
  end
end

function onDoubleClick(x, y)
  if hoverAbility then
    local rParent = window.getDatabaseNode().getParent().getParent().getParent();
    local rActor = ActorManager.getActor("pc", rParent)
    ActionParser.doAction(rParent, rActor, aAbilities[hoverAbility]);
    bEditing = false;
    return true;
  end
end
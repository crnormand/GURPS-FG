---- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
--
--
--
local bBuilt = false;
local bEditing = false;
local aAbilities = {};
local hoverAbility;
local buttons = {};
local bShowing = false;
local buttonsleft;
local buttonstop;
local buttonsright;
local buttonsbottom;
local destroying = false;
local depressed = {};


function onInit()
  parseActions();
end

function parseActions()
  local sType, rParent = getMainNode();
  --Debug.console(rParent, getValue());
  aAbilities = ActionParser.parseComponents(getValue(), rParent, true);
end

function getMainNode()
--  return "pc", window.getDatabaseNode().getParent().getParent().getParent();
  return window.getMainNode();
end

function onValueChanged()
  removeButtons();
  parseActions();
end

function onHoverUpdate(x, y)
  if #aAbilities == 0 then return; end
  local szx, szy = getSize();
  --Debug.console(x,y,szx,szy, buttonsleft, buttonsright, buttonstop, buttonsbottom);
  if x >= buttonsleft and x <= buttonsright and y >= buttonstop and y <= buttonsbottom then
    if not bShowing and not bEditing then
      showButtons()
      bShowing = true;
    end
  else
    if bShowing and not Input.getMouseButtonState(1) then
      hideButtons();
      bShowing = false;
    end
  end
end

function onHover(inside)
  if inside then
    if not bBuilt then
      buildButtons();
    end
  else
    bEditing = false;
  end
end

function setButtons(show)
  if #buttons == 0 then return; end
  for i, b in pairs(buttons) do
    b.setFrame("buttonup");
    b.setVisible(show);
  end
end

function showButtons()
  setButtons(true);    
end

function hideButtons()
  setButtons(false);
end

function buttonPressed(rButton)
  local action = aAbilities[tonumber(rButton.getName())];
  local sType, rParent = getMainNode();
  local rActor = ActorManager.getActor(sType, rParent)
  ActionParser.doAction(rParent, rActor, action);
  --rButton.setFrame("buttonup");
  depressed[tonumber(rButton.getName())] = false;
end

function onBClickDown(rButton)
  depressed[tonumber(rButton.getName())] = true;
  rButton.setFrame("buttondown");
end

function onBClickRelease(rButton)
  depressed[tonumber(rButton.getName())] = false;
  rButton.setFrame("buttonup");
end

function onBDragStart(rButton, button, x, y, draginfo)
  depressed[tonumber(rButton.getName())] = false;
  local action = aAbilities[tonumber(rButton.getName())];
  local sType, rParent = window.getMainNode();
  local rActor = ActorManager.getActor(sType, rParent)
  action.desc="test";
  Debug.console("onBDragStart", rParent, rActor, action, draginfo);
  ActionParser.doAction(rParent, rActor, action, draginfo);
  return true;
end

function onBHover(rButton, state)
  if depressed[tonumber(rButton.getName())] then
    if state then
      rButton.setFrame("buttondown");
    else
      rButton.setFrame("buttonup");
    end
  end
end


function onClickDown(button, x, y)
  bEditing = true;
  hideButtons();
end

function buildButtons()
  bBuilt = true;
  --Debug.console("Build", #aAbilities);
  local szx, szy = getSize();
  local q1x = szx / 4;
  local parent = "text";
  local buttonH = 20;
  local offset = #aAbilities * buttonH;
  local top = (szy / 3) - (offset / 2);
  local odd = true;
  buttonstop = szy / 4;
  buttonsleft = q1x;
  buttonsright = q1x *3;
  buttonsbottom = buttonstop * 3;
  if #aAbilities == 0 then return; end
  for i, a in pairs(aAbilities) do
    local bn = tostring(i);   
    buttons[i] = window.createControl("notes_actions", bn);   -- "notes_actions","buttoncontrol"
    local label = "Click to roll ["..a.orig.."]";
    buttons[i].setText(label);
    --buttons[i].setText(label, "Rolling ["..a.orig.."]!");
    --buttons[i].setStateText(0, label, "Rolling ["..a.orig.."]!");
    --buttons[i].setStateFrame("normal", "buttonup");
    --buttons[i].setStateFrame("pressed", "buttondown");
    buttons[i].setAnchor("left", parent, "left", "absolute", q1x);
    buttons[i].setAnchoredWidth(q1x * 2);
    buttons[i].setAnchor("top", parent, "top", "absolute", top);
    buttons[i].setAnchor("bottom", parent, "top", "absolute", top + buttonH);
    buttons[i].setHoverCursor("hand");
    depressed[i] = false;
    top = top + buttonH;
    odd = not odd;
  end
end

function removeButtons()
  if destroying then return; end
  if #buttons == 0 then return; end
  destroying = true;
  bBuilt = false;
  for i, b in pairs(buttons) do
    b.setVisible(false);
    b.destroy();
  end
  buttons = {};
  destroying = false;
end

function onDoubleClick(x, y)
  if hoverAbility then
    local sType, rParent = getMainNode();
    local rActor = ActorManager.getActor(sType, rParent);
    ActionParser.doAction(rParent, rActor, aAbilities[hoverAbility]);
    bEditing = false;
    return true;
  end
end
-- VoidMark Mini Map help: FAQ and every command, opened from settings or /vmini help.
-- Help window renderer. The same code ships in every VoidMark addon (one copy
-- per addon, own frame name), so each addon works on its own.
-- HELP = { title=..., intro=..., sections={ {title=..., commands={{'/cmd','what it does'},...}}
--                                            or {title=..., faq={{'Question?','Answer.'},...}} } }
local function HelpText(help,filter)
  filter=type(filter)=='string' and filter:lower():match('^%s*(.-)%s*$') or ''
  local function hit(...)
    if filter=='' then return true end
    for i=1,select('#',...) do
      local s=select(i,...)
      if type(s)=='string' and s:lower():find(filter,1,true) then return true end
    end
    return false
  end
  local out={}
  if filter=='' and help.intro then out[#out+1]=help.intro;out[#out+1]='' end
  local found=0
  for _,section in ipairs(help.sections or {}) do
    local lines={}
    for _,c in ipairs(section.commands or {}) do
      if hit(c[1],c[2],section.title) then lines[#lines+1]='|cffffd200'..c[1]..'|r  '..c[2];found=found+1 end
    end
    for _,q in ipairs(section.faq or {}) do
      if hit(q[1],q[2],section.title) then lines[#lines+1]='|cffffd200Q: '..q[1]..'|r';lines[#lines+1]='A: '..q[2];lines[#lines+1]='';found=found+1 end
    end
    if #lines>0 then
      out[#out+1]='|cffb86cff'..section.title:upper()..'|r'
      for _,l in ipairs(lines) do out[#out+1]=l end
      if lines[#lines]~='' then out[#out+1]='' end
    end
  end
  if found==0 then out[#out+1]='Nothing matches "'..filter..'".' end
  return table.concat(out,'\n'),found
end

local function HelpWindow(frameName,help)
  local w={help=help}
  local f,text,search
  local function render()
    if not f then return end
    local s=HelpText(help,search and search:GetText() or '')
    w.current=s
    text:SetText(s)
    local _,breaks=s:gsub('\n','\n')
    text:SetHeight(math.max(400,(breaks+1)*15+40))
  end
  local function build()
    f=CreateFrame('Frame',frameName,UIParent,BackdropTemplateMixin and 'BackdropTemplate' or nil)
    f:SetSize(580,620);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG')
    if f.SetToplevel then f:SetToplevel(true) end
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart',function() f:StartMoving() end)
    f:SetScript('OnDragStop',function() f:StopMovingOrSizing() end)
    if f.SetBackdrop then
      f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
      f:SetBackdropColor(.035,.025,.06,.97);f:SetBackdropBorderColor(.48,.25,.72,1)
    end
    local title=f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    title:SetPoint('TOPLEFT',16,-14);title:SetText(help.title or 'Help')
    local close=CreateFrame('Button',nil,f,'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT',-2,-2);close:SetScript('OnClick',function() f:Hide() end)
    local label=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    label:SetPoint('TOPLEFT',18,-48);label:SetText('Search:')
    search=CreateFrame('EditBox',frameName..'Search',f,'InputBoxTemplate')
    search:SetSize(220,20);search:SetPoint('TOPLEFT',70,-43)
    if search.SetAutoFocus then search:SetAutoFocus(false) end
    search:SetScript('OnTextChanged',function() render() end)
    search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    search:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
    local hint=f:CreateFontString(nil,'OVERLAY','GameFontDisableSmall')
    hint:SetPoint('LEFT',search,'RIGHT',12,0);hint:SetText('Click the text, Ctrl+A, Ctrl+C to copy.')
    local scroll=CreateFrame('ScrollFrame',frameName..'Scroll',f,'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT',16,-72);scroll:SetPoint('BOTTOMRIGHT',-34,16)
    text=CreateFrame('EditBox',nil,scroll)
    if text.SetMultiLine then text:SetMultiLine(true) end
    if text.SetFontObject then text:SetFontObject(GameFontHighlight) end
    if text.SetAutoFocus then text:SetAutoFocus(false) end
    text:SetWidth(520)
    text:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    -- Read only: typing puts the help text back.
    text:SetScript('OnTextChanged',function(self,user) if user and w.current then self:SetText(w.current) end end)
    scroll:SetScrollChild(text)
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]=frameName end
    f:Hide()
  end
  function w.Open(filter)
    if not f then build() end
    if filter~=nil and search then search:SetText(filter) end
    render();f:Show()
    return f
  end
  function w.Toggle()
    if f and f:IsShown() then f:Hide() else w.Open() end
  end
  function w.Text(filter) return HelpText(help,filter) end
  function w.Frame() return f end
  return w
end

local HELP={title='VoidMark Mini Map: Help & commands',
 intro='Open this window from the Mini Map settings (gear button or /vmini) > Help & commands, or type /vmini help. Type in Search to filter.',
 sections={
 {title='Map',commands={
  {'/vmini  (or /voidmarkminimap)','Open or close the settings window.'},
  {'/vmm','Same as /vmini, only when VoidMark Market is not installed (Market owns /vmm).'},
  {'/vmini help [word]','This window; a word searches it.'},
  {'/vmini unlock','Drag the zone bar to move the map; drag the // corner to resize.'},
  {'/vmini lock','Lock the map in place (hides the resize handle).'},
  {'/vmini size 350','Set the map size (180-600).'},
  {'/vmini reset','Default size (300) and top-right position.'}}},
 {title='Herb colours',commands={
  {'/vmherb','Status: your Herbalism, colour steps and what has been learned.'},
  {'/vmherb on | off','Show or hide the herb box when you hover a herb.'},
  {'/vmherb tip on | off','Colour squares on map herb labels.'},
  {'/vmherb scan','Hover a herb on the map; it is read 3 seconds later.'},
  {'/vmherb reset','Forget learned herb colours (back to Classic steps).'}}},
 {title='Layer (experimental)',commands={
  {'/vmlayer on | off','Show or hide the layer indicator.'},
  {'/vmlayer reset','Forget the current layer guess.'},
  {'/vmlayer debug','What the layer guess is based on.'}}},
 {title='Every VoidMark addon',commands={
  {'Whisper "inv" or "invite"','From one of your Voidmark characters: you get a group invite.'}}},
 {title='FAQ',faq={
  {'How do I move or resize the map?','Type /vmini unlock, drag the zone-name bar to move it and the // handle at the bottom right to resize. /vmini lock when done.'},
  {'The map does not change. Why?','Another minimap addon is active (Leatrix Plus Enhance minimap, MoveAny Minimap, SexyMap or ElvUI). Turn that feature off and /reload.'},
  {'Where did my addon buttons go?','They sit around the edge of the map. Untick "Place addon buttons around map" to put them back where they were.'},
  {'What do the herb colours mean?','Orange/yellow/green herbs still give skill-ups; grey ones do not. Hover herbs in the world and the steps are learned from the game.'},
  {'What is MS?','Server (world) latency, updated every 5 seconds. FPS and MS can be shown separately.'},
  {'Is the layer number official?','No. It is an estimate from nearby creatures and shows [Layer ?] when Forever hides that data.'},
  {'Changed a setting in combat and nothing happened?','Layout changes wait until combat ends, then apply by themselves.'},
  {'How do the party markers work?','Each party member is a big dot in their class colour with the first letter of their name, drawn above quest icons. If they are off the map (your zone or the next one over), the dot sits on the edge with an arrow pointing at them and the distance in yards. Turn it on/off and change the size in the Mini Map settings.'},
  {'Are settings per character?','Yes. Size, position and options are saved for each character.'}}}}}
_G.VoidMarkMiniMapHelp=HelpWindow('VoidMarkMiniMapHelpWindow',HELP)

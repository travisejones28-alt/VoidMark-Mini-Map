return function(t)
 local tick=function(dt)t.controller.scripts.OnUpdate(t.controller,dt or .01)end
 local option=function(key,value)
  local control=VoidMarkMiniMapOptions[key]
  control:SetChecked(value);control.scripts.OnClick(control)
 end
 local mail=VoidMarkMiniMapMailButton
 assert(mail and not mail:IsShown(),'Missing APIs must not fabricate mail')
 local texture
 for _,frame in ipairs(t.frames) do if frame.parent==mail and frame.kind=='Texture' then texture=frame end end
 if VMM_TEST_ATLAS then
  assert(texture.atlas=='ui-hud-minimap-mail-up' and texture.width==24 and texture.height==18,'Atlas proportions')
 else assert(texture.texture=='Interface\\Icons\\INV_Letter_15','Known mail fallback') end
 local waiting=false
 HasNewMail=function()return waiting end
 t.event('UPDATE_PENDING_MAIL');assert(not mail:IsShown())
 waiting=true;t.event('UPDATE_PENDING_MAIL');assert(mail:IsShown())
 local anchor=mail.point
 assert(anchor[1]=='TOPLEFT' and anchor[3]=='TOPLEFT' and anchor[4]==6 and anchor[5]==-6,'Mail inset inside top-left terrain')
 GetLatestThreeSenders=function()return 'Sender A',nil,'Sender C' end
 mail.scripts.OnEnter(mail)
 assert(GameTooltip.owner==mail and GameTooltip.lines[1]=='Sender A' and GameTooltip.lines[2]=='Sender C','Sparse senders retained')
 GameTooltip.owner=UIParent;mail.scripts.OnLeave(mail);assert(GameTooltip:IsShown(),'Do not hide another tooltip')
 waiting=false;t.event('MAIL_INBOX_UPDATE');assert(not mail:IsShown())
 HasNewMail=nil;C_Mail={HasNewMail=function()return true end}
 t.event('MAIL_CLOSED');assert(mail:IsShown(),'Namespaced fallback')
 C_Mail.HasNewMail=function()error('Unavailable')end
 t.event('MAIL_SHOW');assert(mail:IsShown(),'Transient unavailable API preserves last state')
 t.command('size 420');t.event('UI_SCALE_CHANGED')
 assert(mail.point==anchor and mail.parent==VoidMarkMiniMapFrame,'Mail follows stable viewport anchor')
 assert(not MinimapCluster.mouse and not MinimapCluster.Selection.mouse,'Transparent native hit regions disabled')
 assert(not Minimap.ZoomHitArea:IsShown(),'Native zoom hit area suppressed')
 assert(Minimap:IsShown() and Minimap.mouse and Minimap.parent==VoidMarkMiniMapFrame,'Renderer survives')
 for _,value in ipairs({.5,2,1.25,.5,1.25})do
  VoidMarkMiniMapOptions.iconScale:SetValue(value)
  assert(Minimap.iconScale==value and Minimap:GetScale()==1 and Minimap.width==420,'Icon size must not compound terrain scale')
 end
 option('rotate',true);assert(GetCVar('rotateMinimap')=='1')
 -- Forever delivers its native CVar update after our initial layout. The
 -- callback replaces the terrain mask and shows the circular compass underlay.
 MinimapCluster:UpdateMinimapConfig();tick()
 assert(Minimap.mask=='Interface\\Buttons\\WHITE8X8','Restore square mask after Forever rotation callback')
 assert(not MinimapCompassTextureUnderlay:IsShown(),'Suppress rotation circle')
 MinimapCompassTextureUnderlay:Show()
 assert(not MinimapCompassTextureUnderlay.parent:IsShown(),'Native Show cannot reveal ring under hidden parent')
 Minimap:SetMaskTexture('another-native-mask');tick()
 assert(Minimap.mask=='Interface\\Buttons\\WHITE8X8','Direct native mask restoration is observed')
 t.combat(true);MinimapCluster:UpdateMinimapConfig();tick()
 assert(Minimap.mask=='ui-hud-minimap-frame-generic-mask','Mask restoration defers during combat')
 t.combat(false);t.event('PLAYER_REGEN_ENABLED')
 assert(Minimap.mask=='Interface\\Buttons\\WHITE8X8','Mask restored after combat')
 option('headerBelow',true)
 assert(t.header.point[3]=='BOTTOMRIGHT' and Minimap.height==420,'Header below, independent terrain')
 option('headerBelow',false);assert(t.header.point[3]=='TOPRIGHT' and t.header.point[5]==24,'Header above outside map')
 -- Reproduce native layout rewriting detached map and invisible cluster.
 Minimap:SetParent(MinimapCluster.MinimapContainer);Minimap:SetScale(2)
 Minimap:SetSize(150,150);Minimap:SetIconScale(.75);MinimapCluster:EnableMouse(true)
 tick()
 assert(Minimap.parent==VoidMarkMiniMapFrame and Minimap.width==420 and Minimap:GetScale()==1)
 assert(Minimap.iconScale==1.25 and not MinimapCluster.mouse,'Restore settings after native writes')
 local original=Minimap.iconScale
 t.combat(true);VoidMarkMiniMapOptions.iconScale:SetValue(2)
 tick();assert(Minimap.iconScale==original,'No protected mutation during combat')
 t.combat(false);t.event('PLAYER_REGEN_ENABLED');assert(Minimap.iconScale==2)
 EditModeManagerFrame=CreateFrame('Frame');EditModeManagerFrame:Show()
 Minimap:SetIconScale(.6);tick();assert(Minimap.iconScale==.6,'Defer during HUD editing')
 EditModeManagerFrame:Hide();tick();assert(Minimap.iconScale==2,'Restore after HUD editing')
 -- Native drag handlers remain owned by their addons; square projection is deferred.
 option('drawer',true);tick()
 local icon=t.icon
 icon:SetPoint('CENTER',Minimap,'CENTER',80,40);tick()
 assert(icon.point[2]~=Minimap and icon.point[4]>0 and icon.point[5]>0,'Drag projected onto square viewport')
 assert(next(VoidMarkMiniMapDB.rimPositions),'Rim position persisted')
 t.command('size 300');tick()
 assert(math.abs(icon.point[4]*icon:GetScale()-166)<.001,'Rim follows resize without compounded scale')
 -- Unchanged layout has no per-tick or two-second anchor writes.
 tick(2);tick()
 local writes=0
 hooksecurefunc(icon,'SetPoint',function()writes=writes+1 end)
 for i=1,30 do tick(.2) end
 assert(writes==0,'Idle rim must not repeatedly write anchors')
 local before=VoidMarkMiniMapDB.iconScale
 t.event('PLAYER_ENTERING_WORLD');assert(VoidMarkMiniMapDB.iconScale==before,'Settings preserved')
 local setter=Minimap.SetIconScale
 Minimap.SetIconScale=false;t.command('size 300')
 assert(VoidMarkMiniMapOptions.iconText.text:find('unavailable'),'Missing native icon API must be explained')
 Minimap.SetIconScale=setter
 t.print('PASS: mail state/atlas/senders, native hit regions, ownership restoration, independent scaling, headers, combat/Edit Mode, drag persistence and idle rim')
end

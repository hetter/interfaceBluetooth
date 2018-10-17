--[[
NPL.load("(gl)Mod/LogitowMonitor/BlueToothSearchPage.lua");
local BlueToothSearchPage = commonlib.gettable("MyCompany.Aries.Game.GUI.BlueToothSearchPage");
]]

local BlueToothSearchPage = commonlib.gettable("MyCompany.Aries.Game.GUI.BlueToothSearchPage");
local LogitowMonitor = commonlib.gettable("Mod.LogitowMonitor.LogitowMonitor");

function BlueToothSearchPage.OnInit()
	BlueToothSearchPage.page = document:GetPageCtrl();
end

function BlueToothSearchPage.OnClose()
	if BlueToothSearchPage.page then
		BlueToothSearchPage.page:CloseWindow();
		BlueToothSearchPage.page = nil;
	end	
end

function BlueToothSearchPage.OnShowPage()
	if not BlueToothSearchPage.page then
		local params = {
				url = "Mod/LogitowMonitor/BlueToothSearchPage.html", 
				name = "PC.BlueToothSearchPage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				bToggleShowHide=false, 
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = false,
				enable_esc_key = false,
				bShow = true,
				--isTopLevel = true,
				zorder = 999,
				click_through = true, 
				cancelShowAnimation = true,
				directPosition = true,
					align = "_fi",
					x = 0,
					y = 0,
					width = 0,
					height = 0,
				};
			
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		
		commonlib.echo("--------------------------Mod/LogitowMonitor/BlueToothSearchPage.html");
	end
	
	BlueToothSearchPage.SetBlueTips();
end

function BlueToothSearchPage.SetBlueTips()
	local isBlueConnect = LogitowMonitor.isConnect;
	if BlueToothSearchPage.page then
		if isBlueConnect then
			if BlueToothSearchPage.searchTimer then
				BlueToothSearchPage.searchTimer:Change();
				BlueToothSearchPage.searchTimer = nil;
			end	
			
			
			local blv = math.floor(LogitowMonitor.blueBattery or 0);
			
			BlueToothSearchPage.page:SetValue("txt_battery", string.format("%d%%", blv));	
			BlueToothSearchPage.page:SetValue("progressbar_battery", blv);
			local mcmlNode = BlueToothSearchPage.page:GetNode("lense");
			mcmlNode:SetAttribute("visible", "false");
		else	
			BlueToothSearchPage.page:SetValue("txt_battery", "--");
			BlueToothSearchPage.page:SetValue("progressbar_battery", 0);
			--local mcmlNode = BlueToothSearchPage.page:GetNode("lense");
			--mcmlNode:SetAttribute("visible", "true");
			
			BlueToothSearchPage.doSearchAnim();
		end	
		BlueToothSearchPage.page:Refresh(0.01);
	end
end	

function BlueToothSearchPage.RefreshOnLoadWorldFinshed()
	if BlueToothSearchPage.page then
		BlueToothSearchPage.OnClose();
		BlueToothSearchPage.OnShowPage();
	else
		BlueToothSearchPage.OnShowPage();
	end
end

function BlueToothSearchPage.doSearchAnim()
	if(not BlueToothSearchPage.searchTimer) then
		if LogitowMonitor.isConnect then
			return;
		end
	
		BlueToothSearchPage.searchTimer = commonlib.Timer:new({callbackFunc = function(timer)
			local mcmlNode = BlueToothSearchPage.page:GetNode("lense");
			local visible = mcmlNode:GetAttributeWithCode("visible", nil, true);
			visible = tostring(visible);			
			if(visible and visible == "false")then
				mcmlNode:SetAttribute("visible", "true");
			else
				mcmlNode:SetAttribute("visible", "false");
			end	
			BlueToothSearchPage.page:Refresh(0.01);
		end})
		
		BlueToothSearchPage.searchTimer:Change(500, 500);
	end
end
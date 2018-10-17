--[[
Title: bluetooth
Author(s): dummy
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/LogitowMonitor/main.lua");
local LogitowMonitor = commonlib.gettable("Mod.LogitowMonitor");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/PluginBlueTooth/main.lua");
local PluginBlueTooth = commonlib.gettable("Mod.PluginBlueTooth");

NPL.load("(gl)Mod/LogitowMonitor/BtCommand.lua");
local BtCommand = commonlib.gettable("Mod.LogitowMonitor.BtCommand");

local LogitowMonitor = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.LogitowMonitor"));

function LogitowMonitor:ctor()

end

-- virtual function get mod name
function LogitowMonitor:OnClickExitApp()
	return true;
end	

function LogitowMonitor:GetName()
	return "LogitowMonitor"
end

-- virtual function get mod description 

function LogitowMonitor:GetDesc()
	return "LogitowMonitor is a plugin in paracraft"
end

function LogitowMonitor:init()
	BtCommand:init();
	
	NPL.load("(gl)Mod/LogitowMonitor/LogitowMonitor.lua");
	local logitowMonitor = commonlib.gettable("Mod.LogitowMonitor.LogitowMonitor");	
	
	local function initMonitor(pBluetooth)
		logitowMonitor.setup(pBluetooth);
	end	
	
	if PluginBlueTooth.Single then
		initMonitor(PluginBlueTooth.Single);
	else
		local function onInitBluetooth(pBluetooth)
			GameLogic:GetFilters():remove_filter("blueTooth_on_init", onInitBluetooth);
			initMonitor(pBluetooth);
		end	
		GameLogic:GetFilters():add_filter("blueTooth_on_init", onInitBluetooth);
	end
	
	logitowMonitor.InstallCommand()
	
	GameLogic:Connect("WorldLoaded", LogitowMonitor, LogitowMonitor.onLoadWorldFinshed, "LogitowMonitor")	
end

function LogitowMonitor:OnLogin()

end

function LogitowMonitor.onRestoreCameraSetting(movieCamera)
	return false;
end

-- called when a new world is loaded. 
function LogitowMonitor:OnWorldLoad()			
	return true;	
end

function LogitowMonitor.onLoadWorldFinshed()
	NPL.load("(gl)Mod/LogitowMonitor/LogitowMonitor.lua");
	local logitowMonitor = commonlib.gettable("Mod.LogitowMonitor.LogitowMonitor");	
	logitowMonitor.onLoadWorldFinshed()
end

function LogitowMonitor:OnInitDesktop()
end

function LogitowMonitor:OnLeaveWorld()
end

function LogitowMonitor:OnDestroy()

end
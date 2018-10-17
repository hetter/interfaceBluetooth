--[[
Title: BtCommand
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/LogitowMonitor/BtCommand.lua");
local BtCommand = commonlib.gettable("Mod.LogitowMonitor.BtCommand");
------------------------------------------------------------
]]
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local BtCommand = commonlib.inherit(nil,commonlib.gettable("Mod.LogitowMonitor.BtCommand"));

function BtCommand:ctor()
end

function BtCommand:init()
	LOG.std(nil, "info", "BtCommand", "init");
	self:InstallCommand();
end

function BtCommand:InstallCommand()
	
	Commands["initLogitowBlueTooth"] = {
		name="initLogitowBlueTooth", 
		quick_ref="/initLogitowBlueTooth ", 
		desc=[[]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			local logitowMonitor = commonlib.gettable("Mod.LogitowMonitor.LogitowMonitor");
			logitowMonitor.initWork();
		end,
	};

end

--[[
Title: bluetooth monitor
Author(s): dummy
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/LogitowMonitor/LogitowMonitor.lua");
local LogitowMonitor = commonlib.gettable("Mod.LogitowMonitor.LogitowMonitor");
------------------------------------------------------------
]]

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local PluginBlueTooth = commonlib.gettable("Mod.PluginBlueTooth");

local LogitowMonitor = commonlib.gettable("Mod.LogitowMonitor.LogitowMonitor");

NPL.load("(gl)Mod/LogitowMonitor/BuildBlock.lua");
local BuildBlock = commonlib.gettable("Mod.LogitowMonitor.BuildBlock");

NPL.load("(gl)Mod/LogitowMonitor/BtBaseBuildTask.lua");
local BtBaseBuildTask = commonlib.gettable("Mod.LogitowMonitor.BtBaseBuildTask");

NPL.load("(gl)Mod/LogitowMonitor/BlueToothSearchPage.lua");
local BlueToothSearchPage = commonlib.gettable("MyCompany.Aries.Game.GUI.BlueToothSearchPage");

local BlueConstants = {
	READ_BLOCK_SERVER = "69400001-b5a3-f393-e0a9-e50e24dcca99";--数据通讯的服务UUID  HEART_RATE_MEASUREMENT
	READ_BLOCK_CHARACTERISTIC = "69400003-b5a3-f393-e0a9-e50e24dcca99";--可读对象UUID CLIENT_CHARACTERISTIC_CONFIG
	WRITE_BLOCK_CONFIG = "7f510004-b5a3-f393-e0a9-e50e24dcca9e";--模块驱动的服务UUID HEART_RATE_MODEL
	WRITE_CHARACTERISTIC_CONFIG = "7f510005-b5a3-f393-e0a9-e50e24dcca9e";--可写对象UUID
	MODEL_CLIENT_CHARACTERISTIC = "7f510006-b5a3-f393-e0a9-e50e24dcca9e";--可读对象UUID
	BATTERY_DESC = "00002902-0000-1000-8000-00805f9b34fb";
	WRITE_GET_BATTERY_HEX = "AD02";
	LOGITOW_DEVICE = "LOGITOW";
}

function LogitowMonitor.setup(pluginBlueTooth)	
	LogitowMonitor.pluginBlueTooth = pluginBlueTooth;
	GameLogic:GetFilters():add_filter("blueTooth_set_blueStatus", LogitowMonitor.OnBlueStatus);
	GameLogic:GetFilters():add_filter("blueTooth_check_device", LogitowMonitor.OnCheckDevice);
	--GameLogic:GetFilters():add_filter("blueTooth_read_characteristic_finshed", LogitowMonitor.OnReadFinshed);
	GameLogic:GetFilters():add_filter("blueTooth_on_characteristic", LogitowMonitor.OnCharacteristic);
	GameLogic:GetFilters():add_filter("blueTooth_on_descriptor", LogitowMonitor.OnDescriptor);

    --LogitowMonitor.initWork();
end

function LogitowMonitor.initWork()
    LogitowMonitor.pluginBlueTooth:setDeviceName(BlueConstants.LOGITOW_DEVICE);

    local serId = BlueConstants.READ_BLOCK_SERVER;
    local chaId = BlueConstants.READ_BLOCK_CHARACTERISTIC;
    LogitowMonitor.pluginBlueTooth:setCharacteristicsUuid(serId, chaId);

    LogitowMonitor.pluginBlueTooth:setCharacteristicsUuid(BlueConstants.WRITE_BLOCK_CONFIG, BlueConstants.WRITE_CHARACTERISTIC_CONFIG);

    LogitowMonitor.pluginBlueTooth:setupBluetoothDelegate()
end

function LogitowMonitor.startBuildTask()
	local function onEnd()
		BuildBlock.Clear();
		LogitowMonitor.nowBuildTask = nil;
	end
	local buildTask = BtBaseBuildTask:new({onEndFunc = onEnd});
	buildTask:Run();
	LogitowMonitor.nowBuildTask = buildTask;
end	

function LogitowMonitor.OnBlueStatus(isConnect)
	LogitowMonitor.isConnect = isConnect;
	LogitowMonitor.getBleLevel(isConnect);	
	--BlueToothSearchPage.OnShowPage();
	
	if(isConnect) then
		BuildBlock.Clear();
		BlueToothSearchPage.RefreshOnLoadWorldFinshed();
	else	
		--commonlib.echo("---------------LogitowMonitor.nowBuildTask nil nil nil nil nil")
		LogitowMonitor.nowBuildTask = nil;
		BlueToothSearchPage.OnClose();
	end
end	

function LogitowMonitor.OnCheckDevice(_, device_params)
	if device_params.name == BlueConstants.LOGITOW_DEVICE and device_params.rssi > -70 then
		return true;
	end
	return _;
end	

function LogitowMonitor.OnReadFinshed()
	local serId = BlueConstants.READ_BLOCK_SERVER;
	local chaId = BlueConstants.READ_BLOCK_CHARACTERISTIC;
	local decId = BlueConstants.BATTERY_DESC;
	
	LogitowMonitor.pluginBlueTooth:readCharacteristic(serId, chaId);
	LogitowMonitor.pluginBlueTooth:setCharacteristicNotification(serId, chaId, true);	
	LogitowMonitor.pluginBlueTooth:setDescriptorNotification(serId, chaId, decId);	
	
	do
		local serId = BlueConstants.WRITE_BLOCK_CONFIG;
		local chaId = BlueConstants.WRITE_CHARACTERISTIC_CONFIG;
		local decId = BlueConstants.BATTERY_DESC;
		
		LogitowMonitor.pluginBlueTooth:readCharacteristic(serId, chaId);
		LogitowMonitor.pluginBlueTooth:setCharacteristicNotification(serId, chaId, true);	
		LogitowMonitor.pluginBlueTooth:setDescriptorNotification(serId, chaId, decId);	
	end
end

function LogitowMonitor.OnCharacteristic(params)
	commonlib.echo(string.format("-------------------------- OnCharacteristic uuid:%s data:%s io:%s", params.uuid, params.data, params.io));

	if(params.io ~= "c")then
		return;
	end

	if not(params.data) then
        return;
	end

    local dataJs = commonlib.Json.Decode(params.data);
    local blockDataStr = dataJs.data;
    commonlib.echo(string.format("-------------------------- OnCharacteristic blockDataStr:%s len:%s", dataJs.data, dataJs.len));

	
	local function getNumber(pData, pBit)
		local byte = string.byte(pData, pBit);
		--commonlib.echo("getnumbers:" .. byte);
		-- 0~9
		if byte >= 48 and byte <= 57 then
			return byte - 48;
		-- A~F	
		elseif byte >= 65 then
			return (byte - 65) + 10;
		end
	end
	
	local function getBattery(blockDataStr)
		local floatA = getNumber(blockDataStr, 1)* 16^1 + getNumber(blockDataStr, 2) * 16^0;
		local floatB = getNumber(blockDataStr, 3)* 16^1 + getNumber(blockDataStr, 4) * 16^0;
		local floatM = string.format("%d.%d", floatA, floatB);
		local num = (floatM - 1.5)*100.0;
		local fnum = (num/60)*100;
		
		fnum = math.min(100, fnum)
		fnum = math.max(0, fnum)
		
		LogitowMonitor.blueBattery = fnum;
		--commonlib.echo(string.format("!!!!! lv varvarvar:%s %s %s %s %s", floatA, floatB, floatM, num, fnum));
	end	
	

    local dataLen = string.len(blockDataStr);
    if dataLen >= 6 then
        if (LogitowMonitor.lastBlockDataStr == blockDataStr) then
            --return;
        end
        LogitowMonitor.lastBlockDataStr = blockDataStr;

        local box_id = getNumber(blockDataStr, 1) * 16^5 +getNumber(blockDataStr, 2)*16^4+getNumber(blockDataStr, 3)*16^3+getNumber(blockDataStr, 4)*16^2+getNumber(blockDataStr, 5)*16^1+ getNumber(blockDataStr, 6)*16^0;
        local box_face = getNumber(blockDataStr, 7) * 16 + getNumber(blockDataStr, 8);
        local child_id = getNumber(blockDataStr, 9) * 16^5 +getNumber(blockDataStr, 10)*16^4+getNumber(blockDataStr, 11)*16^3+getNumber(blockDataStr, 12)*16^2+getNumber(blockDataStr, 13)*16^1+ getNumber(blockDataStr, 14)*16^0;

        commonlib.echo("!!!!! box_id:" .. box_id);
        commonlib.echo("!!!!! box_face:" .. box_face);
        commonlib.echo("!!!!! child_id:" .. child_id);

        if LogitowMonitor.nowBuildTask == nil and child_id ~= 0 and not BuildBlock.isRepeatCmd(box_id, box_face, child_id) then
            --commonlib.echo("!!!!! LogitowMonitor.startBuildTask():");
            LogitowMonitor.startBuildTask();
        end
        BuildBlock.ProcessCommand(box_id, box_face, child_id);
    elseif dataLen >= 4 then
        getBattery(blockDataStr);
    end
end	

function LogitowMonitor.OnDescriptor(params)
	if BlueConstants.READ_BLOCK_CHARACTERISTIC ~= LogitowMonitor.fatherMap[params.uuid] then
		--commonlib.echo("--------------------------OnDescriptor return return -end2:" .. params.uuid);
		return;
	end	
	

end	

function LogitowMonitor.getBleLevel(isUpdate)
	if (isUpdate) then
		LogitowMonitor._updateBleLv();
	else	
		LogitowMonitor._un_updateBleLv();
	end	
end

function LogitowMonitor._updateBleLv()
	if not LogitowMonitor.mytimer then
		LogitowMonitor.mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			LogitowMonitor._updateBleLv();
		end})
		
		LogitowMonitor.mytimer:Change(0, 1000);
	end
	
	if LogitowMonitor.isConnect then
		local writeData = BlueConstants.WRITE_GET_BATTERY_HEX;
		LogitowMonitor.pluginBlueTooth:writeToCharacteristic(BlueConstants.WRITE_BLOCK_CONFIG, BlueConstants.WRITE_CHARACTERISTIC_CONFIG, writeData);

        LogitowMonitor.pluginBlueTooth:characteristicGetStrValue(BlueConstants.WRITE_BLOCK_CONFIG, BlueConstants.WRITE_CHARACTERISTIC_CONFIG);

		BlueToothSearchPage.SetBlueTips()
	end	
end

function LogitowMonitor._un_updateBleLv()
	if LogitowMonitor.mytimer then
		LogitowMonitor.mytimer:Change();
		LogitowMonitor.mytimer = nil;
	end	
end	

function LogitowMonitor.InstallCommand()
	local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
	Commands["runBlueBuild"] = {
		name="runBlueBuild", 
		quick_ref="/runBlueBuild [animId]", 
		desc=[[@param]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			NPL.activate("pluginBle.dll", {cmd = "startble", luaPath = "(gl)Mod/PluginBlueTooth/main.lua"});
		end			
	};
end

function LogitowMonitor.onLoadWorldFinshed()
	if LogitowMonitor.isConnect then
		BlueToothSearchPage.RefreshOnLoadWorldFinshed();
	end	
end

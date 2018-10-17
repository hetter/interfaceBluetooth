--[[
Title: bluetooth
Author(s): dummy
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/PluginBlueTooth/main.lua");
local PluginBlueTooth = commonlib.gettable("Mod.PluginBlueTooth");
------------------------------------------------------------
]]

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local PluginBlueTooth = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.PluginBlueTooth"));

--对应oc/java互调
local BLUETOOTH_SYSTEM_CALL = 
{
	CHECK_DEVICE = 1101;
	SET_BLUE_STATUS = 1102;
	ON_READ_CHARACTERISTIC_FINSHED = 1103;
	ON_CHARACTERISTIC = 1104;
	ON_DESCRIPTOR = 1105;
    ON_READ_ALL_GATT = 1106;
}

local single;
function PluginBlueTooth.getSingle()
	return single;
end

function PluginBlueTooth:ctor()
	single = self;
end

-- virtual function get mod name
function PluginBlueTooth:OnClickExitApp()
	return true;
end	

function PluginBlueTooth:GetName()
	return "PluginBlueTooth"
end

-- virtual function get mod description 

function PluginBlueTooth:GetDesc()
	return "PluginBlueTooth is a plugin in paracraft"
end

local LocalService = {callBacks = {}};
function PluginBlueTooth:initProtoclFunc()
	local function Split(szFullString, szSeparator)  
		local nFindStartIndex = 1
		local nSplitIndex = 1 
		local nSplitArray = {}
		
		if szFullString then
			while true do  
			   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
			   if not nFindLastIndex then  
				nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
				break  
			   end  
			   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
			   nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
			   nSplitIndex = nSplitIndex + 1  
			end  
		end
		return nSplitArray  
	end

	LocalService.RegisterProtocolCallBacks = function (pid, pfunc)
		LocalService.callBacks[pid] = pfunc;
	end

	-- 设置蓝牙状态
	local function setBlueStatus(pId, pData)
		LOG.std("PluginBlueTooth/main", "info", "setBlueStatus", pData);
		local isConnect = ("1" == pData);
		GameLogic.GetFilters():apply_filters("blueTooth_set_blueStatus", isConnect);
	end
	LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.SET_BLUE_STATUS, setBlueStatus);
	
	local function checkDevice(pId, pData)
		local device_params = commonlib.Json.Decode(pData);
		local isLink = GameLogic.GetFilters():apply_filters("blueTooth_check_device", false, device_params);
		if (isLink) then
			self:LinkDevice(device_params.addr);
		end
	end
	LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.CHECK_DEVICE, checkDevice);	
	
	local function onReadBlueGattUUid(pId, pData)
		self.blueGattUUidMap = commonlib.Json.Decode(pData);
		GameLogic.GetFilters():apply_filters("blueTooth_read_blueGattUuid", self.blueGattUUidMap);
	end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_READ_ALL_GATT, onReadBlueGattUUid);

    local function onReadCharacteristicFinshed(pId, pData)
        GameLogic.GetFilters():apply_filters("blueTooth_read_characteristic_finshed");
    end
	LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_READ_CHARACTERISTIC_FINSHED, onReadCharacteristicFinshed);



	local function onCharacteristic(pId, pData)
		local cha_params = commonlib.Json.Decode(pData);
		GameLogic.GetFilters():apply_filters("blueTooth_on_characteristic", cha_params);		
	end	
	LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_CHARACTERISTIC, onCharacteristic);
	
	local function onDescriptor(pId, pData)
		local desc_params = commonlib.Json.Decode(pData);
		GameLogic.GetFilters():apply_filters("blueTooth_on_descriptor", desc_params);		
	end	
	LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_DESCRIPTOR, onDescriptor);	
end

---- npl call enginee
local g_engine_call_Lua;
function PluginBlueTooth.regNplEngineeBridge()
	local platform = System.os.GetPlatform();
	if (platform == "android") then
		if LuaJavaBridge then
			return;
		end	
		
		if LuaJavaBridge == nil then
			NPL.call("LuaJavaBridge.cpp", {});
		end
		
		if LuaJavaBridge then

			local LuaJavaBridge = LuaJavaBridge;

			local callJavaStaticMethod = LuaJavaBridge.callJavaStaticMethod

			local args = {luaPath = "(gl)Mod/PluginBlueTooth/main.lua"}  
			local sigs = "(Ljava/lang/String;)V" --传入string参数，无返回值  		
			local ret = callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "registerLuaCall", sigs, args)		
		end
	elseif (platform == "win32") then
		NPL.activate("pluginBle.dll", {cmd = "startble", luaPath = "(gl)Mod/PluginBlueTooth/main.lua"});
    elseif (platform == "ios") then
        NPL.call("LuaObjcBridge.cpp", {});
        local args = {luaPath = "(gl)Mod/PluginBlueTooth/main.lua"}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "registerLuaCall", args)
        local ok2, ret2 = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "reconnectBlu", args)
	end	
	
	if not g_engine_call_Lua then
		g_engine_call_Lua = function(pData)
			local splt_pos = string.find(pData, "_");
			if splt_pos then
				local extData = string.sub(pData, splt_pos + 1)
				local extId = tonumber(string.sub(pData, 1, splt_pos - 1));
				
				commonlib.echo(string.format("----------------------java call lua id:%s, data:%s", extId, extData));
				
				if LocalService and LocalService.callBacks then
					if LocalService.callBacks[extId] then
						LocalService.callBacks[extId](extId, extData);
					end
				end
			end
		end
	end	
end

function PluginBlueTooth:setDeviceName(name)
    local platform = System.os.GetPlatform();

    if (platform == "android") then
		local args = {name}
		local sigs = "(Ljava/lang/String;)V"		
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "setDeviceName", sigs, args)	
    elseif (platform == "win32") then
    elseif (platform == "ios") then
        local args = {name = name}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setDeviceName", args)
    end
end

function PluginBlueTooth:setCharacteristicsUuid(serUuid, chaUuid)
    local platform = System.os.GetPlatform();

    if (platform == "android") then
		local args = {serUuid, chaUuid}
		local sigs = "(Ljava/lang/String;Ljava/lang/String;)V"		
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "setCharacteristicsUuid", sigs, args)		
    elseif (platform == "win32") then
    elseif (platform == "ios") then
        local args = {serUuid = serUuid, chaUuid = chaUuid}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setCharacteristicsUuid", args)
    end
end

function PluginBlueTooth:setupBluetoothDelegate()
    local platform = System.os.GetPlatform();

    if (platform == "android") then
		local args = {}
		local sigs = "()V"
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "setupBluetoothDelegate", sigs, args)
    elseif (platform == "win32") then
    elseif (platform == "ios") then
        local args = {}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setupBluetoothDelegate", args)
    end
end

function PluginBlueTooth:readAllBlueGatt()
    local platform = System.os.GetPlatform();

    if (platform == "android") then
		local args = {}
		local sigs = "()Ljava/lang/String;"
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "readAllBlueGatt", sigs, args)	
		if(type(ret.result) == "string") then
			ret.result = commonlib.Json.Decode(ret.result);
		end
		return ret.result;
    elseif (platform == "win32") then
    elseif (platform == "ios") then
        local args = {}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "readAllBlueGatt", args)
		if(type(ret) == "string") then
			ret = commonlib.Json.Decode(ret);
		end
		return ret;		
    end
end


NPL.this(function()
    commonlib.echo("-------NPL.this NPL.this NPL.this NPL.this NPL.this:" .. tostring(msg));
	if g_engine_call_Lua then
		local msg = msg;
		g_engine_call_Lua(msg);
	end
end);


function PluginBlueTooth:LinkDevice(addr)
	local platform = System.os.GetPlatform();
	if (platform == "android") then
		local args = {addr}  
		local sigs = "(Ljava/lang/String;)V"		
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "connectDevice", sigs, args)
    elseif (platform == "ios") then
        local args = {addr = addr}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "linkDevice", args)
	end
end

function PluginBlueTooth:writeToCharacteristic(ser_uuid, cha_uuid, writeByte)
	local platform = System.os.GetPlatform();
	if (platform == "android") then
		local args = {ser_uuid, cha_uuid, writeByte}  
		local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"	
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "writeToCharacteristic", sigs, args)
    elseif (platform == "ios") then
        local args = {ser_uuid = ser_uuid, cha_uuid = cha_uuid, writeByte = writeByte}  
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "writeToCharacteristic", args)
	end
end

function PluginBlueTooth:characteristicGetStrValue(ser_uuid, cha_uuid)
	local platform = System.os.GetPlatform();
	if (platform == "android") then
		local args = {ser_uuid, cha_uuid}  
		local sigs = "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"	
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "characteristicGetStrValue", sigs, args)		
		if(type(ret.result) == "string") then
			ret.result = commonlib.Json.Decode(ret.result);
		end
		return ret.result;
    elseif (platform == "ios") then
        local args = {ser_uuid = ser_uuid, cha_uuid = cha_uuid}
        local ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "characteristicGetStrValue", args)
	end
end

function PluginBlueTooth:readCharacteristic(ser_uuid, cha_uuid)
	local platform = System.os.GetPlatform();
	if (platform == "android") then		
		local args = {ser_uuid, cha_uuid}  
		local sigs = "(Ljava/lang/String;Ljava/lang/String;)V"	
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "readCharacteristic", sigs, args)
    elseif (platform == "ios") then
        local args = {ser_uuid = ser_uuid, cha_uuid = cha_uuid}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "readCharacteristic", args)	
	end	
end	

function PluginBlueTooth:setCharacteristicNotification(ser_uuid, cha_uuid, isNotify)
	local platform = System.os.GetPlatform();
	if (platform == "android") then	
		local args = {ser_uuid, cha_uuid, isNotify}  
		local sigs = "(Ljava/lang/String;Ljava/lang/String;Z)V"	
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "setCharacteristicNotification", sigs, args)
    elseif (platform == "ios") then
        local args = {ser_uuid = ser_uuid, cha_uuid = cha_uuid, isNotify = isNotify}
        local ok, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setCharacteristicNotification", args)	
	end	
end

function PluginBlueTooth:setDescriptorNotification(ser_uuid, cha_uuid, desc_uuid)
	local platform = System.os.GetPlatform();
	if (platform == "android") then		
		local args = {ser_uuid, cha_uuid, desc_uuid}  
		local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"	
		local ret = LuaJavaBridge.callJavaStaticMethod("plugin/Bluetooth/InterfaceBluetooth" , "setDescriptorNotification", sigs, args)
    elseif (platform == "ios") then
        -- not need
	end	
end


--


function PluginBlueTooth:init()
	PluginBlueTooth.Single = self;
	commonlib.echo("--------------------------init PluginBlueTooth");
	PluginBlueTooth.regNplEngineeBridge();
	self:initProtoclFunc();
	GameLogic.GetFilters():apply_filters("blueTooth_on_init", self);
end

function PluginBlueTooth:OnLogin()

end

function PluginBlueTooth.onRestoreCameraSetting(movieCamera)
	return false;
end

-- called when a new world is loaded. 
function PluginBlueTooth:OnWorldLoad()
	GameLogic:Connect("WorldLoaded", PluginBlueTooth, PluginBlueTooth.onLoadWorldFinshed, "PluginBlueTooth")				
	return true;	
end

function PluginBlueTooth.onLoadWorldFinshed()

end

function PluginBlueTooth:OnInitDesktop()
end

function PluginBlueTooth:OnLeaveWorld()
end

function PluginBlueTooth:OnDestroy()
	single = nil;
end

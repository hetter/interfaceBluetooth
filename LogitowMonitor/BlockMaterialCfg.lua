--[[
Title: BlockMaterialCfg
Author(s): dummy
Date: 20170729
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/LogitowMonitor/BlockMaterialCfg.lua");
local BlockMaterialCfg = commonlib.gettable("Mod.LogitowMonitor.BlockMaterialCfg");
------------------------------------------------------------
]]

-- 白 1048576———2097151
local BlockMaterialCfg = commonlib.gettable("Mod.LogitowMonitor.BlockMaterialCfg");

function BlockMaterialCfg:getModelColor(boxid)
	if(not boxid)then
		LOG.std("LogitowMonitor","info","BlockMaterialCfg","boxid is nil!");
		return;
	end
	--if BlockMaterialCfg.cfg[boxid] then
		--return BlockMaterialCfg.cfg[boxid];
	--end
	if (boxid >= 65536 and boxid <= 131071)then
		return 4095;--c白
	end
	if (boxid >= 131072 and boxid <= 196607)then
		return 16;--c黑
	end
	if (boxid >= 196608 and boxid <= 262143)then
		return 3088;--c红
	end
	if (boxid >= 262144 and boxid <= 327679)then
		return 4000;--c橙
	end
	if (boxid >= 327680 and boxid <= 393215)then
		return 4080;--c黄
	end
	if (boxid >= 393216 and boxid <= 458751)then
		return 240;--c绿
	end
	if (boxid >= 458752 and boxid <= 524287)then
		return 3010;--c青
	end
	if (boxid >= 524288 and boxid <= 589823)then
		return 15;--c蓝
	end
	if (boxid >= 589824 and boxid <= 655359)then
		return 1097;--c紫
	end
	if (boxid >= 655360 and boxid <= 720895)then
		return 3193;--c粉色
	end
	if (boxid >= 1048576 and boxid <= 2097151)then
		return 4095;--白
	end
	if (boxid >= 2097152 and boxid <= 3145727)then
		return 16;--黑
	end
	if (boxid >= 3145728 and boxid <= 4194303)then
		return 3088;--红
	end
	if (boxid >= 4194304 and boxid <= 5242879)then
		return 4000;--橙
	end
	if (boxid >= 5242880 and boxid <= 6291455)then
		return 4080;--黄
	end
	if (boxid >= 6291456 and boxid <= 7340031)then
		return 240;--绿
	end
	if (boxid >= 7340032 and boxid <= 8388607)then
		return 3010;--青
	end
	if (boxid >= 8388608 and boxid <= 9437183)then
		return 15;--蓝
	end
	if (boxid >= 9437184 and boxid <= 10485759)then
		return 1097;--紫
	end
	if (boxid >= 10485760 and boxid <= 11534335)then
		return 3193;--粉色
	end
	if (boxid >= 11534336 and boxid <= 12582911)then
		return 2184;--灰色
	end
	return 4095;
end

--[[
BlockMaterialCfg.cfg = 
{
--red
[6292418]=4095;
[6292315]=4095;
}
]]
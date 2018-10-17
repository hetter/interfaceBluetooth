--[[
Title: For files from blue tooth. 
Author(s): 
Date: 
Desc:
------------------------------------------------------------
NPL.load("(gl)Mod/LogitowMonitor/BtBaseBuildTask.lua");
local BtBaseBuildTask = commonlib.gettable("Mod.LogitowMonitor.BtBaseBuildTask");
-------------------------------------------------------
]]

NPL.load("(gl)Mod/LogitowMonitor/BuildBlock.lua");
local BuildBlock = commonlib.gettable("Mod.LogitowMonitor.BuildBlock");

local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

NPL.load("(gl)Mod/LogitowMonitor/BlockMaterialCfg.lua");
local BlockMaterialCfg = commonlib.gettable("Mod.LogitowMonitor.BlockMaterialCfg");

local BtBaseBuildTask = commonlib.inherit(nil, commonlib.gettable("Mod.LogitowMonitor.BtBaseBuildTask"));

local cur_instance;

-- end tag  64
BtBaseBuildTask.EndBlockIds = {
	[64] = true;
	[16777215] = true;
}

-- global function
function BtBaseBuildTask.OnBuildBlockDataChange(blocks, box_id, box_face, child_id)
	cur_instance:BuildBlockDataChange(blocks, box_id, box_face, child_id);
end

-- member function
function BtBaseBuildTask:ctor()
	self.updataDelta = 100;
	self.finished = true;
	self.is_exclusive = true;
end

function BtBaseBuildTask:setNowCamDir()	
	local att = ParaCamera.GetAttributeObject();
	local rot_y = att:GetField("CameraRotY", 0);
	
	while(rot_y > math.pi * 2) do
		rot_y = rot_y - math.pi * 2
	end
	
	while(rot_y < -math.pi * 2) do
		rot_y = rot_y + math.pi * 2
	end	
	local camDirY = 1;
	if rot_y >= math.pi/4 and rot_y <= math.pi/4 * 3 then
		camDirY = 1;
	elseif (rot_y >= math.pi/4 and rot_y <= math.pi) or (rot_y <= -math.pi/4 * 3 and rot_y >= -math.pi) then	
		camDirY = 2;		
	elseif rot_y <= -math.pi/4 and rot_y >= -math.pi/4 * 3 then	
		camDirY = 3;	
	elseif (rot_y <= 0 and rot_y >= -math.pi/4) or (rot_y >= 0 and rot_y <= math.pi/4) then	
		camDirY = 4;	
	end
	
	self.camDirY = camDirY;
end	

-- 根据方向调整方块的位置
function BtBaseBuildTask:blockConvertToParacraftXyz(blockData)
	if blockData and self.camDirY then
		local b = blockData;
		local cx, cy, cz = self.cx, self.cy, self.cz;
		if self.camDirY == 4 then
			return cx+b[1], cy+b[2], cz+b[3];
		elseif self.camDirY == 3 then
			return cx-b[3], cy+b[2], cz+b[1];
		elseif self.camDirY == 2 then
			return cx-b[1], cy+b[2], cz-b[3];	
		elseif self.camDirY == 1 then
			return cx+b[3], cy+b[2], cz-b[1];								
		end
	end
end

function BtBaseBuildTask:Run()
	TaskManager.AddTask(self);

	cur_instance = self;
	
	self.lastHigh = 0;
	
	if not self.cx then	
		self.cx, self.cy, self.cz = EntityManager.GetPlayer():GetBlockPos();
	end	

	self:setNowCamDir();

	GameLogic.GetFilters():add_filter("BuildBlock_SendBuildBlockData", BtBaseBuildTask.OnBuildBlockDataChange);

	self.finished = false;

	BuildBlock.Clear();
--	BuildBlock.Export2BuilData();
end

function BtBaseBuildTask:ConvertToBlockData(bb)
	local writeBlock = {};
	writeBlock[1] = bb.X;
	writeBlock[2] = bb.Y;
	writeBlock[3] = bb.Z;

	-- 结束id处理
	if BtBaseBuildTask.EndBlockIds[bb.id] then
		writeBlock[4] = bb.id;
	else
		writeBlock[4] = 10;
	end

	local color = BlockMaterialCfg:getModelColor(bb.id);
	-- 结束id处理
	if BtBaseBuildTask.EndBlockIds[bb.id] then
		color = 4095;
	end
	writeBlock[5] = color;

	return writeBlock;
end

function BtBaseBuildTask:setSingleBlock(buildBlockData, blockParams)
	local x, y, z = blockParams[1], blockParams[2], blockParams[3];
	
	BlockEngine:SetBlock(x, y, z, blockParams[4], blockParams[5], blockParams[6], blockParams[7]);
end	

function BtBaseBuildTask:BuildBlockDataChange(blockDatas, box_id, box_face, child_id)
	if(blockDatas == nil)then
		return
	end

	-- Convert build block
	local preCheckData = {};
	local blocks = {};
	blocks.map = {};
	local last_set_block;
	
	local off_dir_up = {0, 1, 0};	
	local off_dir = off_dir_up; -- last block dir
	for blockInx = 1, #blockDatas do
		local buildBlock = blockDatas[blockInx];
		blocks[blockInx] = self:ConvertToBlockData(buildBlock);
		
		local nowBlock = blocks[blockInx];
		local x, y, z = self:blockConvertToParacraftXyz(nowBlock);
		nowBlock[1] = x;
		nowBlock[2] = y;
		nowBlock[3] = z;
		blocks.map[string.format("%s_%s_%s", x, y, z)] = {};

		-- init preCheckData
		if not preCheckData.aaPos then
			preCheckData.aaPos = {x, y, z};
			preCheckData.bbPos = {x, y, z};	
			preCheckData.ctPos = {x, y, z};			
		else
			-- update preCheckData
			for i = 1, 3 do
				preCheckData.aaPos[i] = math.min(preCheckData.aaPos[i], nowBlock[i]); 
				preCheckData.bbPos[i] = math.max(preCheckData.bbPos[i], nowBlock[i]);
				preCheckData.ctPos[i] = preCheckData.aaPos[i] + (preCheckData.bbPos[i] - preCheckData.aaPos[i]) / 2;
			end
		end
		
		if (buildBlock.id > 0 and buildBlock.id == child_id) then
			last_set_block = nowBlock;
			if x >= preCheckData.ctPos[1] then
				off_dir = {-1, 0, 0}
			elseif x <= preCheckData.ctPos[1] then
				off_dir = {1, 0, 0}
			elseif z >= preCheckData.ctPos[3] then
				off_dir = {0, 0, -1}
			elseif z <= preCheckData.ctPos[3] then
				off_dir = {0, 0, 1}
			end			
		end		
	end
	
	-- check collision
	local function checkCollision(bInfo, offsetPos)
		if (bInfo == nil) then
			return false;
		end
		local checkPos = {bInfo[1] + offsetPos[1], bInfo[2] + offsetPos[2], bInfo[3] + offsetPos[3]}
		
		local block_id = BlockEngine:GetBlockId(checkPos[1], checkPos[2], checkPos[3]);
		--commonlib.echo(string.format("-----------------------checkCollision:%s %s %s id:%s", checkPos[1], checkPos[2], checkPos[3], block_id))
		
		return (block_id ~= 0);
	end	
	
	-- clear last blocks
	local last_blocks = self.blocks or {};
	last_blocks.map = last_blocks.map or {};	
	local function checkBlocksCollision(offsetPos)
		for i = 1, #blocks do
			local blockInfo = blocks[i];
			
			local sparse_index = string.format("%s_%s_%s", blockInfo[1], blockInfo[2], blockInfo[3]);
			if(not last_blocks.map[sparse_index]) then
				if(checkCollision(blockInfo, offsetPos)) then
					return true;
				end
			end
		end
		return false;
	end	
	
	local isCollision = checkBlocksCollision({0, 0, 0});
	

	for i = 1, #last_blocks do
		local lb = last_blocks[i];
		if isCollision then
			self:setSingleBlock(lb, {lb[1], lb[2], lb[3], 0});
		else
			local sparse_index = string.format("%s_%s_%s", lb[1], lb[2], lb[3]);
			if(not blocks.map[sparse_index]) then
				self:setSingleBlock(lb, {lb[1], lb[2], lb[3], 0});
			end	
		end
	end
	
	-- calc offset
	local function makeOffset()
		if not checkBlocksCollision(off_dir) then
			return off_dir;
		end
		
		if off_dir ~= off_dir_up and not checkBlocksCollision(off_dir_up) then
			return off_dir_up;
		end		
		
		local height = preCheckData.bbPos[2] - preCheckData.aaPos[2] + 1;
		local searchUp = {0, height, 0};
		local searchRet = checkBlocksCollision(searchUp);
		
		local breakCount = 0;
		repeat
			breakCount = breakCount + 1;
			if breakCount > 10 then
				return searchUp;
			end
	
			if (searchRet) then
				searchUp[2] = searchUp[2] + height;
				searchRet = checkBlocksCollision(searchUp);
			else
				return searchUp;
			end
		until(not searchRet)
	end		
	
	local offsetPos = {0, 0, 0}
	if isCollision then
		offsetPos = makeOffset() or {0, 0, 0};
		self.cx = self.cx + offsetPos[1];
		self.cy = self.cy + offsetPos[2];
		self.cz = self.cz + offsetPos[3];
	end
	
	local isEndBlock = false;	
	for blockInx = 1, #blocks do
		
		local blockInfo = blocks[blockInx];
		-- do offset
		--commonlib.echo(string.format("-----------------------11 checkCollision off:%s %s %s binfo:%s %s %s", offsetPos[1], offsetPos[2], offsetPos[3], blockInfo[1], blockInfo[2], blockInfo[3]))
		for i = 1, 3 do
			blockInfo[i] = blockInfo[i] + offsetPos[i];
		end
		
		--commonlib.echo(string.format("-----------------------22 checkCollision off:%s %s %s binfo:%s %s %s", offsetPos[1], offsetPos[2], offsetPos[3], blockInfo[1], blockInfo[2], blockInfo[3]))
		
		local sparse_index = string.format("%s_%s_%s", blockInfo[1], blockInfo[2], blockInfo[3]);
		
		local new_id = blockInfo[4] or 10;
		
		local pb_data = blockInfo[5] or 0;
		
		if BtBaseBuildTask.EndBlockIds[new_id] then
			isEndBlock = true;
			-- 结束方块材质和正常方块一样
			new_id = 266;
			blockInfo[4] = new_id;
		end	
		
		blocks.map[sparse_index] = {};	
		-- 记录材质id
		blocks.map[sparse_index].new_id = new_id;
		-- 记录方块data
		blocks.map[sparse_index].pb_data = pb_data;
		
		blocks.map[sparse_index].blockInx = blockInx;

		if(isCollision or last_blocks.map[sparse_index] == nil or 
			(not (last_blocks.map[sparse_index].new_id == new_id and last_blocks.map[sparse_index].pb_data == pb_data))) then		
			self:setSingleBlock(blocks.map[sparse_index], {blockInfo[1], blockInfo[2], blockInfo[3], new_id, pb_data, blockInfo[6], blockInfo[7]});
		end	
	end
	
	self.blocks = blocks;
	if isEndBlock then
		self:setEndBlock();
	end	
end

function BtBaseBuildTask:setEndBlock()
	self.finished = true;
	cur_instance = nil;
	GameLogic.GetFilters():remove_filter("BuildBlock_SendBuildBlockData", BtBaseBuildTask.OnBuildBlockDataChange);
	self.blocks = {};
	self.blocks.map = {};
	BuildBlock.Clear();
	
	if (self.onEndFunc) then
		self.onEndFunc();
	end
end

function BtBaseBuildTask:FrameMove(deltaTime)
end
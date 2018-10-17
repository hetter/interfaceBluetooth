--[[
Title: For files from blue tooth. 
Author(s): 
Date: 
Desc:
------------------------------------------------------------
NPL.load("(gl)Mod/LogitowMonitor/BuildBlock.lua");
local BuildBlock = commonlib.gettable("Mod.LogitowMonitor.BuildBlock");
-------------------------------------------------------
]]

local BuildBlock = commonlib.inherit(nil,commonlib.gettable("Mod.LogitowMonitor.BuildBlock"));
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

function BuildBlock:_clearSelf()
	self.Childs = {};
	self.X = 0;
	self.Y = 0;
	self.Z = 0;
	self.faces = { 1, 2, 3, 4, 5, 6 };
	self.id = -1;
end

function BuildBlock.Clear()
	local faces = { 1, 2, 3, 4, 5, 6 };
	BuildBlock.root = BuildBlock:new(); 
	BuildBlock.root:_clearSelf();    
	BuildBlock.root.faces = faces;   
	BuildBlock.root.id = 0;
	BuildBlock.root.X = 0;
	BuildBlock.root.Y = 0;
	BuildBlock.root.Z = -1;
end	

function BuildBlock:FindChildById(nm)
	
	if self.id == nm then
		return self;
	end	

	local cube = nil;

	for i = 1, 6 do
		if self.Childs[i] ~= nil then
			cube = self.Childs[i]:FindChildById(nm);
			if cube ~= nil then
				break;
			end	
		end	
	end

	return cube;
end

function BuildBlock:ExportXML()

end

function BuildBlock:FindChildByPos(x, y, z)
	if (x == self.X and y == self.Y and z == self.Z) then
		return self;
	end	

	local retCube;

	for i = 1, 6 do
		if self.Childs[i] ~= nil then
			retCube = self.Childs[i]:FindChildByPos(x, y, z);
			if retCube ~= nil then
				break;
			end
		end		
	end

	return retCube;
end

-- <summary>
-- 获取方向
-- </summary>
-- <param name="face_id"></param>
-- <returns></returns>
function BuildBlock:find_dir_idx(face_id)
	for i = 1, 6 do
		if (face_id == self.faces[i]) then
			return i;
		end
	end

	return -1;
end

--子积木和父积木连接时，俩个积木同一平面的面号对应关系,以父积木的面号为索引
local child_same_face = 
{
	{ 0,0,0,0,0,0 }, --连接父积木的0面,不可能连接××××××
	{ 1, 2, 3, 4, 5, 6 }, --连接父积木的1面
	{ 5,3,2,6,1,4 }, --连接父积木的2面
	{5,3,4,2,6,1},--连接父积木的3面
	{5,3,1,4,2,6},--连接父积木的4面
	{5,3,6,1,4,2},--连接父积木的5面
};

local first_child_face = 
{
	{ 0,0,0,0,0,0 }, --连接父积木的0面,不可能连接××××××
	{ 1, 2, 3, 4, 5, 6 }, --连接父积木的1面
	{ 3, 5, 2, 4, 1, 6 }, --连接父积木的2面
	{3,5,6,2,4,1},--连接父积木的3面
	{3,5,1,6,2,4},--连接父积木的4面
	{3,5,4,1,6,2},--连接父积木的5面
};

function BuildBlock.Connect(box_id, connect_face, child_id)
	local parent = BuildBlock.root:FindChildById(box_id);
	if (parent == nil) then
		LOG.std(nil, "info", "BuildBlock", "BuildBlock Connect:could not found block root!");
		return false;
	end
	
	local dir_idx = parent:find_dir_idx(connect_face);

	if (parent.Childs[dir_idx] ~= nil) then
		LOG.std(nil, "info", "BuildBlock", "BuildBlock Connect:duplicate block id:%s!!", parent.Childs[dir_idx].id);
		return false;
	end

	local child = BuildBlock:new();
	child:_clearSelf(); 	
	child.id = child_id;
	parent.Childs[dir_idx] = child;

	local pos_offset_default = { { 0, -1, 0}, { 0, 1, 0}, { 0, 0, -1 }, { 1, 0, 0 }, { 0, 0, 1 }, { -1, 0, 0 } };
	
	local pos_offset = GameLogic.GetFilters():apply_filters("BuildBlock_GetPosOffset", pos_offset_default);

	-- 计算子积木坐标
	child.X = parent.X + pos_offset[dir_idx][1];
	child.Y = parent.Y + pos_offset[dir_idx][2];
	child.Z = parent.Z + pos_offset[dir_idx][3];

	--LOG.std("BuildBlock", "debug", "Connect", "child_id:"..child_id);

	-- 计算子积木各面的方向
	for parent_face_id = 1, 6 do
		for dir_id = 1, 6 do
			if (parent_face_id == parent.faces[dir_id]) then

				if(box_id == 0) then
					child.faces[dir_id] = first_child_face[connect_face][parent_face_id];
				else
					child.faces[dir_id] = child_same_face[connect_face][parent_face_id];
				end

				break;
			end
		end
	end

	return true;
end


function BuildBlock.DeConnect(id, face)
	local parent = BuildBlock.root:FindChildById(id);
	LOG.std("BuildBlock", "debug", "DeConnect", "parentid:"..id);
	if (parent == nil) then
		LOG.std(nil, "info", "BuildBlock", "BuildBlock DeConnect:could not found block:%s", id);
		return false;
	end	

	local dir_idx = parent:find_dir_idx(face);

	if (parent.Childs[dir_idx] == nil) then
		LOG.std(nil, "info", "BuildBlock", "BuildBlock DeConnect:block id: %s face: %s has no child block", id, face);
		return false;
	end

	parent.Childs[dir_idx] = nil;
	return true;
end

function BuildBlock.isRepeatCmd(box_id, box_face, child_id)
	if(	BuildBlock.last_box_id == box_id and
		BuildBlock.last_box_face == box_face and
		BuildBlock.last_child_id == child_id ) then
			commonlib.echo("----------------repeat mask");		
		return true;
	end
end	

--指令处理
function BuildBlock.ProcessCommand(box_id, box_face, child_id) 
	
	if(BuildBlock.isRepeatCmd(box_id, box_face, child_id)) then
		return;
	end	
	
	if(BuildBlock.root == nil) then
		BuildBlock.Clear();
		commonlib.echo("----------------nil init init init!!!!!");	
	end	
	
	--clear
	if (box_id == 0 and box_face == 0 and box_face == 0) then
		BuildBlock.clearAllBlock();
		return;
	end

	if (box_face < 1 or box_face > 6) then
		--out_msg(header + "参数错误，连接面必须是1～6");
		LOG.std(nil, "info", "BuildBlock", "error insert face(must be 1~6)!!");
		return;
	end
	
	local ret_ = true;	
	--删除积木
	if (child_id == 0) then
		ret_ = BuildBlock.DeConnect(box_id, box_face);
		if (ret_) then
			--out_msg(header + "移除成功");
		else
			--out_msg(header + "移除失败, " + ret);
			LOG.std(nil, "info", "BuildBlock", "remove failed");
		end
	else
		ret_ = BuildBlock.Connect(box_id, box_face, child_id);

		if (ret_) then
			--out_msg(header .. "插入成功");
		else
			--out_msg(header .. "插入失败, " .. ret);
			LOG.std(nil, "info", "BuildBlock", "insert failed");
		end
	end
	
	if (ret_) then
		BuildBlock.last_box_id = box_id;
		BuildBlock.last_box_face = box_face;
		BuildBlock.last_child_id = child_id;

		BuildBlock.Export2BuilData();
	end
end

function BuildBlock.clearAllBlock()
	
	BuildBlock.last_box_id = -1;
	BuildBlock.last_box_face = -1;
	BuildBlock.last_child_id = -1;
	
	BuildBlock.Clear();
	BuildBlock.Export2BuilData();
end

function  BuildBlock:paracraftXyzConvertToBlock(blockData)
	local att = ParaCamera.GetAttributeObject();
	local rot_y = att:GetField("CameraRotY", 0);
	local camDirY;
	
	while(rot_y > math.pi * 2) do
		rot_y = rot_y - math.pi * 2
	end
	
	while(rot_y < -math.pi * 2) do
		rot_y = rot_y + math.pi * 2
	end	
	
	if rot_y >= math.pi/4 and rot_y <= math.pi/4 * 3 then
		camDirY = 1;
	elseif (rot_y >= math.pi/4 and rot_y <= math.pi) or (rot_y <= -math.pi/4 * 3 and rot_y >= -math.pi) then	
		camDirY = 2;		
	elseif rot_y <= -math.pi/4 and rot_y >= -math.pi/4 * 3 then	
		camDirY = 3;		
	elseif (rot_y <= 0 and rot_y >= -math.pi/4) or (rot_y >= 0 and rot_y <= math.pi/4) then	
		camDirY = 4;		
	end

	--camDirY = camDirY;
	local bx, by, bz = EntityManager.GetPlayer():GetBlockPos();
	local cx = bx; 
	local cy = by; 
	local cz = bz; 
	if camDirY == nil then
		camDirY = 3;
	end

	if blockData and camDirY then
		local b = blockData;
		return cx-b[1], b[2]-cy, cz-b[3];
	end
end

function BuildBlock._setBlockData(wrapBlock, blocks)
	local bb = wrapBlock;
	
	local inx = #blocks + 1;
	blocks[inx] = bb;	
	
	for _, v in pairs(wrapBlock.Childs) do
		BuildBlock._setBlockData(v, blocks);
	end		
end

function BuildBlock.getChildBlocks()
	local function _getChildBlocksDefault(BuildBlockRoot)
		--添加第1个空主机
		local child = BuildBlock:new();
		child:_clearSelf(); 
		child.id = -1;
		child.Childs[3] = BuildBlockRoot;	
		--{ 3, 5, 2, 4, 1, 6 }
		return child;
	end
	
	local getChildBlocksFunc = GameLogic.GetFilters():apply_filters("BuildBlock_GetChildBlockFunc", _getChildBlocksDefault);	
	return getChildBlocksFunc(BuildBlock.root);
end	

function BuildBlock.Export2BuilData()	
	local retBlocks = {};
	local child = BuildBlock.getChildBlocks();
	BuildBlock._setBlockData(child, retBlocks);
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
	GameLogic.GetFilters():apply_filters("BuildBlock_SendBuildBlockData", retBlocks, BuildBlock.last_box_id, BuildBlock.last_box_face, BuildBlock.last_child_id);

	return retBlocks;
end


function BuildBlock.DeepCopy(object)      
    local SearchTable = {}  

    local function Func(object)  
        if type(object) ~= "table" then  
            return object         
        end  
        local NewTable = {}  
        SearchTable[object] = NewTable  
        for k, v in pairs(object) do  
            NewTable[Func(k)] = Func(v)  
        end     

        return setmetatable(NewTable, getmetatable(object))      
    end    

    return Func(object)  
end  
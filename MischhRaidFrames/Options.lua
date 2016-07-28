--[[ Defined Methods: :GetOption(), :SuppressOptionUpdates() ]]
--Doing (very) repetetive :Get() is not the best way of doing stuff with these Options.
--make a local copy of the Value you are looking for, apply all Updates to that one and
--only use the Option to :Set() with DIFFERENT values.
--:Set within a :OnUpdate will very easily end in a endless loop. Be Careful.

local MRF = Apollo.GetAddon("MischhRaidFrames")
do --all workarounds for :GetOption(...)
	local option_parents = {};
	local master_option = {route = {}, children = {}}; --this is only a fake Option for :GetOption(); the children may change (and will)
	local template_option = {};
	local update_suppess = false
	
	local function route(tbl, key1, key2, ...)
		if key2 then
			if not tbl[key1] then tbl[key1] = {} end
			return route(tbl[key1], key2, ...)
		end
		return tbl, key1;
	end
	
	function template_option:Get()		
		local t, k = route(option_parents, unpack(self.route))
		return t[k]
	end
	
	function template_option:Set(value)
		local t, k = route(option_parents, unpack(self.route))
		t[k] = value;
		
		if update_suppess then return end --if updates get suppressed, we will make a :Set() public.
		
		(self.pushTo or self):ForceUpdate(); --see :GatherUpdates() for this.
	end
	
	function template_option:OnUpdate(handler, func)
		self.updating[handler] = func or true
	end
	
	local function replace_ForceUpdate(self)
		self.cached = true
	end
	
	local function template_option_ForceUpdate(self)
		self.ForceUpdate = replace_ForceUpdate
	
		--let the update-force flow to all children.
		for routeIndex, child in pairs(self.children) do
			child:ForceUpdate()
		end
		
		local value = self:Get()
		--and pass the update to all registered handlers.
		for handler, func in pairs(self.updating) do
			if type(handler) == "function" then
				handler(value)
			else
				handler[func](handler, value) --assume handler:func(value) is defined.
			end
		end
		
		if not self.block then 
			self.ForceUpdate = template_option_ForceUpdate
			if self.cached then
				self.cached = false
				self:ForceUpdate()
			end
		end
	end
	
	template_option.ForceUpdate = template_option_ForceUpdate

	function template_option:BlockUpdates()
		self.ForceUpdate = replace_ForceUpdate
		self.block = true --this option could possibly already be in a :ForceUpdate() 
		--we need to makre sure he stays in the replacement.
	end
	
	function template_option:UnblockUpdates()
		self.block = false
		self.ForceUpdate = template_option_ForceUpdate
		if self.cached then
			self.cached = false
			self:ForceUpdate()
		end
	end
	
	--same as :GetOption():Set(optSource) -> Use instead of this. | thats a profile swap.
	function MRF:InitOptionsManager(optSource)
		option_parents[0] = optSource;
	end

	local function append(tbl, item)
		local ret = {unpack(tbl)}
		ret[#ret+1] = item
		return ret
	end
	
	local function buildOption(parentOpt, indexKey) --a option built this way should be immediatly applied to the parents children.
		local option = {
			pushTo = parentOpt.pushTo, --if nil -> stays nil. 
			children = {},
			route = append(parentOpt.route, indexKey), --add the indexKey to the route of its parent. Call it my Route.
			updating = {},
		}
		
		for i,v in pairs(template_option) do --apply the template for :Get, :Set, :OnUpdate & :ForceUpdate
			option[i] = v
		end
		
		return option
	end
	
	local function getChild(option, childKey)
		option.children[childKey] = option.children[childKey] or buildOption(option, childKey)
		return option.children[childKey];
	end
	
	local function trackOption(option, childKey, ...)
		if childKey then
			option = getChild(option, childKey)
			return trackOption(option, ...)
		end
		return option
	end
	
	-- parentOption can be
	--	string (name) for a Option that can be completely independent set 
	--	another option to recieve Updates, if the parent updates
	--	nil to use the default options Source.
	function MRF:GetOption(parent, ...) --doing :GetOption(nil) returns you the whole profile. :Set() this to switch it.
		-- build some sort of startpoint out of the parentOption.
			-- nil -> option of option_parents[0]
			-- string -> option of option_parents[string]
			-- obj -> assume the obj is a option.
		if type(parent) == "string" then
			parent = getChild(master_option, parent)
		elseif type(parent) ~= "table" then --default to [0]
			parent = getChild(master_option, 0)
		end
		
		--if neither of the above was true, we assume the table which was passed is a option.
		return trackOption(parent, ...)
	end
	
	local function applyPushingChildren(option, target)
		option.pushTo = target
		for routeKey, childOpt in pairs(option.children) do
			applyPushingChildren(childOpt, target)
		end
	end
	
	--make all children (and below) push their updates up to this option - this makes all objects below this one push its update
	--up here once anything changes. - this does not change the way forced updates act. (only updates by :Set)
	function MRF:GatherUpdates(option)
		--iterate throught all children and mark them to push their information up, instead of dealing with it themselves.
		applyPushingChildren(option, option)
	end
	
	
	local selectHandler = {}
	
	function MRF:SelectRemote(optionName, targetOption)
		default = default or false --we do not want default to be nil.
	
		local selected = self:GetOption(optionName)
		local selector = self:GetOption("selector:"..optionName)
		
		local strSelector = "setSelector:"..optionName
		local strSelected = "setSelected:"..optionName
		
		selectHandler[strSelector] = function(_, index)
			local val = nil
			if index then
				local selection = targetOption:Get()
				val = selection[index]
			end
			selected:Set(val) --all of these are nil-proof, except the :GetOption(), scince that one will return the same, as called with one argument less.
		end
		selectHandler[strSelected] = function() --dont care which value is set - just pass the update
			targetOption:ForceUpdate()
		end
		
		selector:OnUpdate(selectHandler, strSelector)
		selected:OnUpdate(selectHandler, strSelected)
		self:GatherUpdates(selected)
		
		return selector, selected
	end
	
	-- ONLY USE WITH CARE.
	-- Suppresses all Updates fired from a :Set() on ANY Option.
	-- true activates the suppression, false deactivates.
	function MRF:SuppressOptionUpdates(suppress)
		update_suppess = suppress;
	end
end

do
	local function opt_ipairs(choices)
		local cur_i = 0
		local ref_i = 0
		local ref_max = #choices
		local tbl = choices.opt:Get()
		local returned = {}
		
		return function() --next()
			--we want to keep stuff in the order it was scince this object was created.
			--go throught these in the order they were and return them first, if still valid.
			while ref_i < ref_max do
				ref_i = ref_i + 1
				--if the choice is still there, keep it and return the index.
				if tbl[choices[ref_i]] then
					cur_i = cur_i+1
					choices[cur_i] = choices[ref_i] --move the value to the 'new' appropriate place
					returned[choices[ref_i]] = true
					return cur_i, choices[cur_i]
				else
					choices[ref_i] = nil --we do this now, to not need another for loop at the end.
				end
			end
			
			--search for additional indexes, which were not yet returned.
			for i,v in pairs(tbl) do
				if not returned[i] then
					cur_i = cur_i+1
					choices[cur_i] = i
					returned[i] = true
					return cur_i, i
				end
			end
			return nil -- Returned everything.
		end
	end
	
	function MRF:newOptionIndexChoices(option, hasNone) --the 'None' - Entry is always the boolean false.
		return {ipairs = opt_ipairs, opt = option} 
	end
end
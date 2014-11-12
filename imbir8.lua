
local function find(T,X)
	for i,val in ipairs(T) do
		if X == val then
			return i
		end
	end
end

local function work(s)
	if s:sub(1,1) == '~' then
		return s:sub(2,-1), false
	end
	return s,true
end
local function fitsProt(c1,c2)
	local flag = true
	for cname,_ in pairs(c1) do
		local cn,cond = work(cname)
		if (c2[cn] == nil) == cond then
			flag = false
			break
		end
	end
	return flag
end

local function Run(S,r,args)
	local R = {}
	for imbir,_ in pairs(S._truei) do
		local r = S._Logic(imbir._c,r,args)
		if r then
			table.insert(R,r)
		end
	end
	return R
end






local IMBIR_META = {
	__index = function(self,key)
		return self._c[key]
	end,
	__newindex = function(self,key,value)
		self._c[key] = value
		for world,_ in pairs(self._w) do
			world = world - self
			world = world + self
		end
	end
	}

local WORLD_META = {
	__add = function(self,IS)
		IS = IS or {}
		if not (IS._imbir or IS._system) then
			error 'World + error: +ed object is neither a system nor imbir'
		end
		if IS._imbir and not self._i[IS] then
			for system,_ in pairs(self._s) do
				system = system + IS
			end
			IS._w[self] = true
			self._i[IS] = true
		elseif IS._system and not self._s[IS] then
			for imbir,_ in pairs(self._i) do
				IS = IS + imbir
			end
			self._s[IS] = true
		end
		return self
	end,
	__sub = function(self,IS)
		IS = IS or {}
		if not (IS._imbir or IS._system) then
			error 'World - error: -ed object is neither a system nor imbir'
		end
		if IS._imbir and self._i[IS] then
			for system,_ in pairs(self._s) do
				system = system - IS
			end
			IS._w[self] = nil
			self._i[IS] = nil
		elseif IS._system and self._s[IS] then
			for imbir,_ in pairs(self._i) do
				IS = IS - imbir
			end
			self._s[IS] = nil
		end
		return self
	end,
	__call = function(self,C)
		local r = {}
		local c = {}
		for i,j in ipairs(C) do
			c[j] = true
		end
		for imbir,_ in pairs(self._i) do
			if fitsProt(c,imbir._c) then
				table.insert(r,imbir)
			end
		end
		return r
	end
	}


local SYSTEM_META = {
	__add = function(self,I)
		if not I._imbir then
			error 'System + error: +ed object is not an imbir'
		end
		if not self._i[I]  and  fitsProt(self._c,I._c) then
			self._i[I] = true
		end
		return self
	end,
	__sub = function(self,I)
		if not I._imbir then
			error 'System - error: -ed object is not an imbir'
		end
		if self._i[I] then
			self._i[I] = false
		end
		return self
	end
}









-- **** INTERFACE **** --

-- table insert('before'|'after', table, valueToInsert, relativeValue)
function tins(mode,T,X,Y)
	local i = find(T,Y)
	if i then
		i = mode == 'after' and i+1 or i
		table.insert(T,i,X)
	end
end


-- call Before->Logic->After for all systems in table S, forwarding return values to next systems
function Iterate(S)
	local r = {}
	for _,system in ipairs(S) do
		local flag = true
		if system._fps and S.dt then
			system._t = system._t + S.dt
			if system._t < system._fps then
				flag = false
			else
				system._t = system._t - system._fps
			end
		end
		
		if flag then
			for imbir,_ in pairs(system._i) do
				system._truei[imbir] = system._i[imbir] or nil
				system._i[imbir] = nil
			end
			if system._Before then
				r = system._Before(r,S.args)
			end
			r = Run(system,r,S.args)
			if system._After then
				r = system._After(r,S.args)
			end
		end
	end
	return r
end



function World()
	return setmetatable({_i={}, _s={}, _world=true}, WORLD_META)
end

function System(T)
	local s = setmetatable({_system=true, _i={}, _truei={}, _Logic=T.Logic, _Before=T.Before, _After=T.After, _c={}, _fps=(T.FPS and 1/T.FPS), _t = 0}, SYSTEM_META)
	for _,cname in ipairs(T) do 
		s._c[cname] = true
	end
	return s
end

function Imbir(C)
	return setmetatable({_w = {}, _c = C, _imbir = true}, IMBIR_META)
end









--[[
s = System{
	'a',	-- please do not place anything other in the table part
	'~b', 	-- ~ before component name means imbirs should NOT have the component in question. This system accepts all imbirs that have 'a' component, but do NOT have 'b' component
	
	-- r1: ipairs table returned by previously called system. Read-write
	-- 		if you call Iterate{s1,s2,s3}, then:
	--		r1 for s1 = {}
	--		r1 for s2 == s1's r3 (look below)
	--		r1 for s3 == s2's r3
	-- args: local data passed to Iteration. Read-write
	Before = function(r1,args)		-- optional, called only once per iteration BEFORE calling Logic
		assert(#r1 == 0)
		for i,j in ipairs(r1) do
		
		end
		return r1
	end,
	
	
	-- i: current imbir
	-- r2: r2 == r1
	Logic = function(i, r2,args) -- required, this one is called for each imbir that follows protocol, IN UNDEFINED ORDER (BTW. inserting imbirs during system iteration is valid, but the changes that you make will be visible only when current system finishes calling Logic for its subordinates)
		print('logic',i.s) 
		assert(i.s == 'a' or i.s == 'z')
		return i
	end,
	
	
	-- r3 = {Logic(r2,args,i1), Logic(r2,args,i2)...  , Logic(r2,args,iN)}   where N = number of imbirs following system's component protocol
	After = function(r3,args)		-- optional, called only once per iteration AFTER calling Logic
		assert(args == ARGS)
		assert(#r3 == 2)
		for i,j in ipairs(r3) do
			
		end
		return r3
	end,
	
	
	FPS = 60		-- optional, how many times per second to call the system. Use it to limit refresh rate or something
	}
	
void1 = System{
	'__VOID',	-- we'll use this one to call a function once per iteration
	Logic = function(i) -- gets called only once per iteration if an Imbir{__VOID=true} is present
		print('void system')
		assert(i.__VOID == true)
	end
	}
void2 = System{
	'__VOID',	-- we'll use this one to call a function once per iteration
	Logic = function(i) -- gets called only once per iteration if an Imbir{__VOID=true} is present
		print('other void system')
		assert(i.__VOID == true)
	end
	}
	
w = World()
-- component's value is NOT checked in any way, as long as it is NOT nil
a = Imbir{a=1,s='a'}			-- has 'a' and 's' components
b = Imbir{b=2,s='b'}			-- has 'b' and 's' components
c = Imbir{a=3,b=3,s='c'}		-- has 'a','b' and 's' components
w = w+a+b+s+c-s+s-a+a			-- do some fucking around
w = w-a-b-c 					-- remove imbirs from w
w = w-s 						-- remove system from w (this updates system s's internal imbir table)
w = w+s 						-- subscribe system to world again
w = w+s 						-- repetitions are harmless and do not come with performance penalty
w = w+a+b+c						-- add imbirs to world, this updates all of w's systems' internal imbir tables
w = w+a+b+c						-- another repetition
--w = w+Imbir{__VOID=true}+void1+void2		-- enable void systems


otherw = World()
otherw = otherw+s + Imbir{a=1,s='z'} 	-- only s will contain this imbir

dt = 1/60
ARGS = {1,2,3}							-- ARGS will not be directly mutated by Iterate (but systems themselves can change it)
T = {void1,void2,s, dt=dt, args=ARGS}  	-- call 3 systems, one after another, pass time since last call (optional) and local data (optional)
for i=1,120 do
	print('i',i)
	Iterate(T)						-- Iterate will make a shallow copy of T
end
--]]



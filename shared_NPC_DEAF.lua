-- include("shared.lua")

AddCSLuaFile()

local gbIsOff             = true           -- On/Off the blackness
local gvDown              = Vector(0,0,-0.1) -- Direction of the light
local gnAbov              = 60             -- How far above its position
local gnBRat              = 0.2            -- Time to switch the light/dark
local gsModelNPC          = "models/player/woody/woody.mdl"
                          
                          
ENT.Base                  = "sf2_npc_base"
ENT.Spawnable             = false
ENT.AutomaticFrameAdvance = true 
ENT.AdminSpawnable        = false
                          
ENT.Speed                 = 500
ENT.HealthAmount          = 600
ENT.Damage                = 99999999999999999
ENT.AttackWaitTime        = 0.1
ENT.AttackFinishTime      = 1
ENT.IdleAnim              = "idle_angry"
ENT.DeathRagdoll          = gsModelNPC

if ( CLIENT ) then

  language.Add("SF2_Woody", "Woody")

  timer.Simple(gnBRat, function()
    if(gbIsOff) then gbIsOff = false else gbIsOff = true end
  end ) 

  function ENT:Think()
    local dlt = DynamicLight( self:EntIndex() )
    if ( dlt ) then
        if(gbIsOff) then
          dlt.r = 0 
          dlt.g = 0
          dlt.b = 0
        else
          dlt.r = 170 
          dlt.g = 230
          dlt.b = 255
        end
        dlt.pos        = self:GetPos() - gnAbov * gvDown
        dlt.dir        = gvDown
        dlt.brightness = 1
        dlt.size       = 750
        dlt.decay      = 0.1
        dlt.dieTime    = CurTime() + 0.01
    end
    self:NextThink(CurTime() + 0.1); return true
  end


end

function ENT:Initialize()
  self:SetPlaybackRate( 1 )
  local seq = self:LookupSequence("run_all")
	self.LaughNoise = {
    Sound("slender/woody/theme.wav",100, 100),
    Sound("slender/woody/woodychase3.mp3",100, 100)
  }
  
  timer.Create( "scare_sound", 20, 0, function()
    if not IsValid(self) then return end
    if GetConVarNumber("fnaf2_scare_off") == 0 then
      self:EmitSound(self.LaughNoise[math.random(#self.LaughNoise)])
    end
  end)
    
  self:EmitSound(self.LaughNoise[math.random(#self.LaughNoise)])
  self:SetSequence(seq)
	self:SetCycle( 0 )
	self:ResetSequence( seq )
	self:SetPlaybackRate( 1 )
	self:SetCycle( 0 )
  self:SetModel(gsModelNPC)	
  -- self.Entity:SetCollisionBounds( Vector(-4,-4,0), Vector(4,4,64) )
  self:SetCollisionGroup(COLLISION_GROUP_DEBRIS )
	self:SetHealth(self.HealthAmount)
	self.LoseTargetDist	= 6000000	-- How far the enemy has to be before we lose them
	self.SearchRadius 	= 5000000	-- How far to search for enemies
	--Misc--
	self:Precache()
	if SERVER then
    self.loco:SetAcceleration(900)
    self.loco:SetDeceleration(400)
  end
	self.LastPos = self:GetPos()
	self.nextbot = true
end

function ENT:BodyUpdate()
	local act = self:GetActivity()
	if ( act == ACT_RUN ) then
		self:BodyMoveXY()
	end
	self:FrameAdvance()
end

function ENT:OnRemove()
  if IsValid(self.Enemy) then
  self.Enemy:ConCommand( "pp_mat_overlay  " ) end
  --if !IsValid(self.Victim) then return end
  --self.Victim:SendLua([[RunConsoleCommand("stopsound")]])
  --self.Victim:ConCommand( "pp_mat_overlay  " )
  timer.Destroy("scare undo")
  timer.Destroy("scare undo2")
  timer.Destroy("scare undo3")
  timer.Destroy("scare_sound")
  timer.Destroy( "static_undo" )
  --timer.Destroy( "removebody" )
  self:StopSound( "slender/woody/theme.wav") 
  self:StopSound( "slender/woody/woodychase3.mp3") 
end


function ENT:ChaseEnemy( options )
  if GetConVarNumber("ai_disabled") == 0 then
    if GetConVarNumber("fnaf2_hallucination_off") == 0 then
      local model = math.random(1,2)
        if model == 1 then
          self.Enemy:ConCommand( "pp_mat_overlay overlays/fivenights_puppet/puppetface" ) else
        if model == 2 then
          self.Enemy:ConCommand( "pp_mat_overlay overlays/fivenights_puppet/puppetlookup" ) end
      end
      timer.Create( "stopscaring", 0.4, 3, function()
        if !IsValid(self) then return end
        self.Enemy:ConCommand( "pp_mat_overlay  " )
      end)
		end
	end
--if GetConVarNumber("fnaf2_npc_off") == 0 then
if GetConVarNumber("ai_disabled") == 0 then
--self:EmitSound("legitfreddy/run.wav", 75, 100)
--timer.Create( "run sound", 2, 0, function()
--if !IsValid(self) then return end
--self:EmitSound("legitfreddy/run.wav", 75, 100)
--end)
	local options = options or {}
	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, self:GetEnemy():GetPos() )
	if (  !path:IsValid() ) then return "failed" end
	while ( path:IsValid() and self:HaveEnemy() ) do

		if ( path:GetAge() > 0.0001 ) then	
			path:Compute( self, self:GetEnemy():GetPos() )
		end
		path:Update( self )	
		if ( options.draw ) then path:Draw() end
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end
	
	if SERVER then
	end
	
	local door = ents.FindInSphere(self:GetPos(),65)
		if door then
			for i = 1, #door do
				local v = door[i]
				if !v:IsPlayer() and v != self and IsValid( v ) then
					if self:GetDoor( v ) == "door" then
					
						if v.Hitsleft == nil then
							v.Hitsleft = 3
						end
						
						if v != NULL and v.Hitsleft > 0 then
							if (self:GetRangeTo(v) < 75) then
							
									local sequence = self:LookupSequence("throw1")
self:SetSequence(sequence)
								coroutine.wait(self.AttackWaitTime)
								self:EmitSound(self.DoorBreak)
								
								if v != NULL and v.Hitsleft != nil then
									if v.Hitsleft > 0 then
									v.Hitsleft = v.Hitsleft - 1
									
									end
								end
							end
						end
						
						if v != NULL and v.Hitsleft < 10 then
							v:Remove()
							
						local door = ents.Create("prop_physics")
						door:SetModel(v:GetModel())
						door:SetPos(v:GetPos())
						door:SetAngles(v:GetAngles())
						door:Spawn()
						door:EmitSound("Wood_Plank.Break")
						
						local phys = door:GetPhysicsObject()
						if (phys != nil && phys != NULL && phys:IsValid()) then
						phys:ApplyForceCenter(self:GetForward():GetNormalized()*20000 + Vector(0, 0, 2))
						end
						
						door:SetSkin(v:GetSkin())
						door:SetColor(v:GetColor())
						door:SetMaterial(v:GetMaterial())
					end
						coroutine.wait(self.AttackFinishTime)	
			local sequence = self:LookupSequence("throw1")
self:SetSequence(sequence)
					
						end
						end
						end
						end
						
		
	local ent = ents.FindInSphere( self:GetPos(), 50) 
		for k,v in pairs( ent ) do
		
		if ((v:IsNPC() || (v:IsPlayer() && v:Alive() && !self.IgnorePlayer))) then
		if not ( v:IsValid() && v:Health() > 0 ) then return end
		
		if SERVER then
		local sounds = {}
	sounds[1] = (self.Attack1)
	sounds[2] = (self.Attack2)
		self:EmitSound( sounds[math.random(1,2)] )
		end
	
			local sequence = self:LookupSequence("throw1")
self:SetSequence(sequence)
		coroutine.wait(self.AttackWaitTime)
		self:EmitSound(self.Miss)
			local sequence = self:LookupSequence("throw1")
self:SetSequence(sequence)
		
		if (self:GetRangeTo(v) < 30) then

		if v:IsPlayer() then
		if !IsValid(v) then return end
		v:TakeDamage(self.Damage, self)
				local sequence = self:LookupSequence("throw1")
		self:SetPlaybackRate( 1 )
		if GetConVarNumber("fnaf2_scare_off") == 0 then
		v:EmitSound("slender/woody/woodycatch.mp3",75, 100)
		v:ConCommand( "pp_mat_overlay overlays/slender/omgwoody" )
	--if GetConVarNumber("fnaf2_spawn_table") == 1 then
	--local ents = ents.Create( "freddy_table" )
	--ents:SetPos(v:GetPos())
	--ents:SetAngles(v:GetAngles())
	--ents:Spawn()
	--undo.Create("Freddy Table") 		
	--undo.AddEntity(ents) for k,v in pairs( player.GetAll()) do undo.SetPlayer(v) 
	--end 	
	--undo.Finish()	
	--if GetConVarNumber("fnaf2_keep_bodies") == 0 then
	--timer.Create( "removebody", 10, 1, function()
	--if !IsValid(ents) then return end
	--ents:Remove()
	--end)
	--else
	--end
	--else
	--end
timer.Create( "freakout_undo", 1, 1, function()
	if !IsValid(v) then return end
	--v:ConCommand( "pp_mat_overlay  " )
	--v:SendLua([[RunConsoleCommand("stopsound")]])
	end)
	timer.Create( "freakout_undo2", 1, 1, function()
	if !IsValid(self) then return end
	if !IsValid(v) then return end
	self:EmitSound( "slender/woody/woodyrape.mp3",75, 100 )
	v:ConCommand( "pp_mat_overlay  " )
	end)
	timer.Create( "freakout_undo3", 2.9, 1, function()
	if !IsValid(v) then return end
	--v:SendLua([[RunConsoleCommand("stopsound")]])
	end)
	else
	timer.Create( "freakout_undo", 1, 1, function()
	if !IsValid(v) then return end
	end)
	timer.Create( "freakout_undo2", 1.2, 1, function()
	if !IsValid(v) then return end
	--v:EmitSound( "legitfreddy/static.wav" )
	end)
	timer.Create( "freakout_undo3", 5, 1, function()
	if !IsValid(v) then return end
	end)
	end
			v:EmitSound(self.Hit)
			v:TakeDamage(self.Damage, self)
			end

		if v:IsNPC() then
			v:EmitSound(self.Hit)
			v:TakeDamage(self.Damage, self)	
			end

		end
		coroutine.wait(self.AttackFinishTime)	
		end
		end
		
		if (self:GetEnemy() != nil) then
			if (self:GetEnemy():GetPos():Distance(self:GetPos()) < 50 || self:AttackProp()) then
			else
			if (self:GetEnemy():GetPos():Distance(self:GetPos()) < 50 || self:AttackBreakable()) then
			end
			end
			
		end
		coroutine.yield()
	end
	return "ok"
end
end
	
	list.Set( "NPC", "SF2_Woody", {
	Name = "Woody",
	Class = "SF2_Woody",
	Category = "SF2"
} )

function ENT:RunBehaviour()
	while ( true ) do
		if ( self:HaveEnemy() ) then
		local sequence = self:LookupSequence("run_all")
		self:SetPlaybackRate( 1 )
			self:SetPoseParameter("move_x",1)
			self.loco:SetDesiredSpeed(self.Speed)
			self:ChaseEnemy() 
		else
			-- Wander around
		local sequence = self:LookupSequence("run_all")
		self:SetPlaybackRate( 1 )
			self:SetPoseParameter("move_x",1)
			self.loco:SetDesiredSpeed(self.Speed)
			self:MoveToPos( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 400 )
		end
		coroutine.wait( 5 )
	end
end

function ENT:AttackProp()
	local entstoattack = ents.FindInSphere(self:GetPos(), 55)
	for _,v in pairs(entstoattack) do
	
		if (v:GetClass() == "prop_physics") then
		
		if SERVER then
		local sounds = {}
	sounds[1] = (self.Attack1)
	sounds[2] = (self.Attack2)
		self:EmitSound( sounds[math.random(1,2)] )
		end
	
	
		local sequence = self:LookupSequence("idle")
self:SetSequence(sequence)
		coroutine.wait(self.AttackWaitTime)
		self:EmitSound(self.Miss)
		
		if not ( v:IsValid() ) then return end
		local phys = v:GetPhysicsObject()
			if (phys != nil && phys != NULL && phys:IsValid()) then
			phys:ApplyForceCenter(self:GetForward():GetNormalized()*30000 + Vector(0, 0, 2))
			v:EmitSound(self.DoorBreak)
			v:TakeDamage(self.Damage, self)	
			end
			
		coroutine.wait(self.AttackFinishTime)	
		self:StartActivity( ACT_RUN,2 )
		self:SetPlaybackRate( 1 )
			return true
		end
	end
	return false
end

if(SERVER) then
  function ENT:Think() 
    self.LastPos = self.Entity:GetPos() 
  end
end
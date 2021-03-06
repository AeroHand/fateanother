require("Physics")
require("util")

avalonCooldown = true -- UP if true, 
vectorA = Vector(0,0,0)
combo_available = false
currentHealth = 0

function OnInstinctStart(keys)
	keys.caster:AddNewModifier(keys.caster, nil, "modifier_item_sphere_target", {Duration = 1.0}) -- Just the particles
end

function CreateWind(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local movespeed = ability:GetLevelSpecialValueFor( "speed", ability:GetLevel() - 1 )
	
	local particleName = "particles/custom/saber/saber_invisible_air_trail.vpcf"
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( fxIndex, 3, caster:GetAbsOrigin() )
	
	caster.invisible_air_reach_target = false
	caster.invisible_air_pos = caster:GetAbsOrigin()
	
	local invisAirCounter = 0
	Timers:CreateTimer( function() 
			-- If over 3 seconds
			if invisAirCounter > 3.0 then
				ParticleManager:DestroyParticle( fxIndex, false )
				ParticleManager:ReleaseParticleIndex( fxIndex )
				return
			end
				
			local forwardVec = ( target:GetAbsOrigin() - caster.invisible_air_pos ):Normalized()
				
			caster.invisible_air_pos = caster.invisible_air_pos + forwardVec * movespeed * 0.05
				
			ParticleManager:SetParticleControl( fxIndex, 3, caster.invisible_air_pos )
			
			-- Reach first
			if caster.invisible_air_reach_target then
				ParticleManager:DestroyParticle( fxIndex, false )
				ParticleManager:ReleaseParticleIndex( fxIndex )
				return nil
			else
				invisAirCounter = invisAirCounter + 0.05
				return 0.05
			end
		end
	)
end

function InvisibleAirPull(keys)
	if IsSpellBlocked(keys.target) then return end -- Linken effect checker

	keys.caster.invisible_air_reach_target = true					-- Addition
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()

	if target:GetName() == "npc_dota_hero_bounty_hunter" and target:GetPlayerOwner().IsPFWAcquired then return end

	giveUnitDataDrivenModifier(caster, target, "drag_pause", 1.0)
	if ply.IsChivalryAcquired == true then keys.Damage = keys.Damage + 200 end
	DoDamage(caster, target , keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

    local pullTarget = Physics:Unit(keys.target)
    local dist = (keys.caster:GetAbsOrigin() - keys.target:GetAbsOrigin()):Length2D() 
    target:PreventDI()
    target:SetPhysicsFriction(0)
    target:SetPhysicsVelocity((keys.caster:GetAbsOrigin() - keys.target:GetAbsOrigin()):Normalized() * dist * 2)
    target:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    target:FollowNavMesh(false)

  	Timers:CreateTimer('invispull', {
		endTime = 1.0,
		callback = function()
		target:PreventDI(false)
		target:SetPhysicsVelocity(Vector(0,0,0))
		target:OnPhysicsFrame(nil)
	end
	})

	target:OnPhysicsFrame(function(unit)
	  local diff = caster:GetAbsOrigin() - unit:GetAbsOrigin()
	  local dir = diff:Normalized()
	  unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * dir)
	  if diff:Length() < 100 then
	  	target:RemoveModifierByName("drag_pause")
		target:RemoveModifierByName( "modifier_invisible_air_target" )		-- Addition
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		unit:OnPhysicsFrame(nil)
        FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	  end
	end)
end

--[[
	Author: kritth
	Date: 10.01.2015.
	Create magnataur shockwave in tracking manner upon start
]]
function CaliburnSlash( keys )
	-- Variables
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local movespeed = ability:GetLevelSpecialValueFor( "speed", ability:GetLevel() - 1 )
	local particleName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf"
	

	-- Create particle
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
	
	-- Global value
	caster.caliburn_reach_target = false
	caster.caliburn_pos = caster:GetAbsOrigin()
	
	-- Change forward vector over interval
	Timers:CreateTimer( function() 
			local targetPos = target:GetAbsOrigin()
			local forwardVec = targetPos - caster.caliburn_pos
			forwardVec = forwardVec:Normalized()
			
			caster.caliburn_pos = caster.caliburn_pos + forwardVec * ( movespeed / 10 )
			
			ParticleManager:SetParticleControl( fxIndex, 1, forwardVec * movespeed )
			
			if caster.caliburn_reach_target then
				ParticleManager:DestroyParticle( fxIndex, false )
				return nil
			else
				return 1.0 / movespeed
			end
		end
	)
end

--[[
	Author: kritth
	Date: 10.01.2015.
	Create yellowish explosion upon hitting unit
]]
function CaliburnExplode( keys )
	-- Turn the flag
	keys.caster.caliburn_reach_target = true
	
	print("Exploding")

	-- Variables
	local caster = keys.caster
	local target = keys.target
	local lightParticleName = "particles/units/heroes/hero_brewmaster/brewmaster_primal_split_explosion_swirl_b.vpcf"
	local explodeParticleName = "particles/units/heroes/hero_batrider/batrider_flamebreak_explosion_i.vpcf"


	-- Create particle
	local lightFxIndex = ParticleManager:CreateParticle( lightParticleName, PATTACH_ABSORIGIN, target )
	local explodeFxIndex = ParticleManager:CreateParticle( explodeParticleName, PATTACH_ABSORIGIN, target )
	ParticleManager:SetParticleControl( explodeFxIndex, 3, target:GetAbsOrigin() )
	
	Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( lightFxIndex, false )
			ParticleManager:DestroyParticle( explodeFxIndex, false )
			return nil
		end
	)
end

function OnCaliburnHit(keys) 
	if IsSpellBlocked(keys.target) then return end -- Linken effect checker
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()



	if ply.IsChivalryAcquired == true then 
		keys.Damage = keys.Damage + 200 
		if not IsImmuneToSlow(target) then ability:ApplyDataDrivenModifier(caster, target, "modifier_caliburn_slow", {}) end
	end
	local aoedmg = keys.Damage * keys.AoEDamage

	DoDamage(caster, target , keys.Damage - aoedmg , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
         DoDamage(caster, v , aoedmg , DAMAGE_TYPE_MAGICAL, 0, ability, false)
    end

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())

    caster:EmitSound("Saber.Caliburn")

end

function OnExcaliburStart(keys)
	EmitGlobalSound("Saber.Excalibur_Ready")
	print("Excalibur")
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	local frontward = caster:GetForwardVector()
	
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 4.0)
	local excal = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = casterloc,
        fDistance = keys.Range,
        fStartRadius = keys.StartRadius,
        fEndRadius = keys.EndRadius,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = frontward * keys.Speed
	}
	Timers:CreateTimer(0.5, function() 
		if caster:IsAlive() then
			EmitGlobalSound("Saber.Excalibur") return 
		end
	end)

	Timers:CreateTimer(2.5, function() -- Adjust 2.5 to 3.2 to match the sound
		if caster:IsAlive() then
			excal.vSpawnOrigin = caster:GetAbsOrigin() 
			
			-- Create Particle for projectile
			local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			Timers:CreateTimer( function()
					if dummy ~= nil then
						local newLoc = dummy:GetAbsOrigin() + keys.Speed * 0.03 * frontward
						dummy:SetAbsOrigin( newLoc )
						return 0.03
					else
						return nil
					end
				end
			)
			
			local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/generic/fate_generic_beam_charge.vpcf", PATTACH_ABSORIGIN, dummy )
			ParticleManager:SetParticleControl( excalFxIndex, 1, Vector( keys.EndRadius, keys.EndRadius, keys.EndRadius ) )
			ParticleManager:SetParticleControl( excalFxIndex, 2, frontward * keys.Speed )
			ParticleManager:SetParticleControl( excalFxIndex, 6, Vector( 2.5, 0, 0 ) )
			
			Timers:CreateTimer( 2.5, function()
					ParticleManager:DestroyParticle( excalFxIndex, false )
					ParticleManager:ReleaseParticleIndex( excalFxIndex )
					Timers:CreateTimer( 0.5, function()
							dummy:RemoveSelf()
							return nil
						end
					)
					return nil
				end
			)
			
			local projectile = ProjectileManager:CreateLinearProjectile(excal)
			
			return 
		end
	end)
end

function OnExcaliburHit(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	if ply.IsExcaliburAcquired == true then keys.Damage = keys.Damage + 300 end

	DoDamage(keys.caster, keys.target, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false) 
end

function OnMaxStart(keys)
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	caster:FindAbilityByName("saber_excalibur"):StartCooldown(37.0)
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	
	local max_excal = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = keys.Range,
        fStartRadius = keys.Width,
        fEndRadius = keys.Width,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 6.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * keys.Speed
	}
	
	EmitGlobalSound("Saber.Excalibur_Ready")
	Timers:CreateTimer({
		endTime = 1.5, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
	    EmitGlobalSound("Saber.Excalibur")
	end})
	
	Timers:CreateTimer({
		endTime = 3, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()

		--[[for i=0, 9 do
			local player = PlayerResource:GetPlayer(i)
			if player ~= nil then 
				hero = PlayerResource:GetPlayer(i):GetAssignedHero()
				ParticleManager:CreateParticle("particles/custom/screen_yellow_splash.vpcf", PATTACH_EYES_FOLLOW, hero)
			end
		end]]
		ParticleManager:CreateParticle("particles/custom/screen_yellow_splash.vpcf", PATTACH_EYES_FOLLOW, caster)

	    local projectile = ProjectileManager:CreateLinearProjectile( max_excal )
		
		-- Create Particle for projectile
		local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		Timers:CreateTimer( function()
				if dummy ~= nil then
					local newLoc = dummy:GetAbsOrigin() + keys.Speed * 0.03 * frontward
					dummy:SetAbsOrigin( newLoc )
					return 0.03
				else
					return nil
				end
			end
		)
		
		local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/generic/fate_generic_beam_charge.vpcf", PATTACH_ABSORIGIN, dummy )
		ParticleManager:SetParticleControl( excalFxIndex, 1, Vector( keys.Width, keys.Width, keys.Width ) )
		ParticleManager:SetParticleControl( excalFxIndex, 2, caster:GetForwardVector() * keys.Speed )
		ParticleManager:SetParticleControl( excalFxIndex, 6, Vector( 2.5, 0, 0 ) )
			
		Timers:CreateTimer( 2.5, function()
				ParticleManager:DestroyParticle( excalFxIndex, false )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
				Timers:CreateTimer( 0.5, function()
						dummy:RemoveSelf()
						return nil
					end
				)
				return nil
			end
		)
		
		-- Function to create rock follow the projectile
		local rockFxIndex = ParticleManager:CreateParticle( "particles/custom/saber_excalibur_max_rock_emitter.vpcf", PATTACH_CUSTOMORIGIN, dummy )
		local burnFxIndex = ParticleManager:CreateParticle( "particles/custom/saber_excalibur_max_burn.vpcf", PATTACH_CUSTOMORIGIN, dummy )
		local currentLocation = caster:GetAbsOrigin()
		local forwardVec = caster:GetForwardVector()
		local distance_traverse = 0
		Timers:CreateTimer( 0.2, function()
				if distance_traverse < keys.Range then
					currentLocation = currentLocation + forwardVec * keys.Speed * 0.03
					ParticleManager:SetParticleControl( rockFxIndex, 0, currentLocation )
					ParticleManager:SetParticleControl( burnFxIndex, 3, currentLocation )
					distance_traverse = distance_traverse + keys.Speed / 10
					return 0.03
				else
					ParticleManager:DestroyParticle( rockFxIndex, false )
					ParticleManager:DestroyParticle( burnFxIndex, false )
					ParticleManager:ReleaseParticleIndex( rockFxIndex )
					ParticleManager:ReleaseParticleIndex( burnFxIndex )
					return nil
				end
			end
		)
	end})
end

function OnMaxHit(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	if ply.IsExcaliburAcquired == true then keys.Damage = keys.Damage + 2000 end

	DoDamage(keys.caster, keys.target, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

function OnAvalonStart(keys)
	currentHealth = keys.caster:GetHealth()
	EmitGlobalSound("Saber.Avalon")
	EmitGlobalSound("Saber.Avalon_Shout")
	SaberCheckCombo(keys.caster, keys.ability)
end

function AvalonOnTakeDamage(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local pid = caster:GetPlayerID() 
	local diff = 0
	local damageTaken = keys.DamageTaken
	local newCurrentHealth = caster:GetHealth()
	local emitwhichsound = RandomInt(1, 2)

	if caster.IsAvalonPenetrated then return end

	if caster.IsAvalonProc == true and caster.IsAvalonOnCooldown ~= true then 
		if emitwhichsound == 1 then attacker:EmitSound("Saber.Avalon_Counter1") else attacker:EmitSound("Saber.Avalon_Counter2") end
		AvalonDash(caster, attacker, keys.Damage, keys.ability)
		caster.IsAvalonOnCooldown = true
		Timers:CreateTimer({
			endTime = 3, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
			callback = function()
		    caster.IsAvalonOnCooldown = false
		    end
		})
	end 
	--[[if (damageTaken > keys.Threshold) then
		if avalonCooldown and not caster:HasModifier("pause_sealdisabled") then
			if emitwhichsound == 1 then attacker:EmitSound("Saber.Avalon_Counter1") else attacker:EmitSound("Saber.Avalon_Counter2") end
			
			AvalonDash(caster, attacker, keys.Damage, keys.ability)
			-- dash attack 3 seconds cooldown
			avalonCooldown = false
			Timers:CreateTimer({
				endTime = 3, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
				callback = function()
			    avalonCooldown = true
			    end
			})
		end
	end
	-- if damage would have been lethal without Avalon, set Saber's health to health when Avalon was cast
	if newCurrentHealth == 0 then
		caster:SetHealth(currentHealth)
	else
		caster:SetHealth(newCurrentHealth + damageTaken)
	end]]
end -- function end

function AvalonDash(caster, attacker, counterdamage, ability)
	local targetPoint = attacker:GetAbsOrigin()
	local casterDash = Physics:Unit(caster)
	local distance = targetPoint - caster:GetAbsOrigin()

	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5)
    caster:PreventDI()
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(distance:Normalized() * distance:Length2D()*2)
    caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    caster:FollowNavMesh(true)
	caster:SetAutoUnstuck(false)
	
	Timers:CreateTimer({
		endTime = 0.5,
		callback = function()
		
		-- Particles
		local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/saber_avalon_impact.vpcf", PATTACH_ABSORIGIN, caster )
		local explosionFxIndex = ParticleManager:CreateParticle( "particles/custom/saber_avalon_explosion.vpcf", PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl( explosionFxIndex, 3, caster:GetAbsOrigin() )
		EmitSoundOn( "Hero_EarthShaker.Fissure", caster )
		
		Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( impactFxIndex, false )
				ParticleManager:DestroyParticle( explosionFxIndex, false )
			end
		)
		
		-- Original function
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 300
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, counterdamage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.5})
	    end

	    --stop the dash
	    caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end
	})
end

function OnStrikeAirStart(keys)
	local caster = keys.caster
	local strikeair = 
	{
		Ability = keys.ability,
        EffectName = "particles/custom/saber_strike_air_blast.vpcf",
        iMoveSpeed = 5000,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = 1200,
        fStartRadius = 400,
        fEndRadius = 400,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 6.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 5000
	}
	
	Timers:CreateTimer({
		endTime = 1.75, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
		if caster:IsAlive() then 
			local projectile = ProjectileManager:CreateLinearProjectile(strikeair)
		end
	end})

	EmitGlobalSound("Saber.StrikeAir_Cast")
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 1.75)
	Timers:CreateTimer(1.75, function()  
		local sound = RandomInt(1,2)
		if sound == 1 then EmitGlobalSound("Saber.StrikeAir_Release1") else EmitGlobalSound("Saber.StrikeAir_Release2") end
	return end)

end

function StrikeAirPush(keys)
	local target = keys.target
	if target:GetName() == "npc_dota_hero_bounty_hunter" and target:GetPlayerOwner().IsPFWAcquired then return end

	DoDamage(keys.caster, keys.target, 650 + (keys.caster:FindAbilityByName("saber_caliburn"):GetLevel() + keys.caster:FindAbilityByName("saber_avalon"):GetLevel()) * 125, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	giveUnitDataDrivenModifier(keys.caster, keys.target, "pause_sealenabled", 0.5)

    local pushTarget = Physics:Unit(keys.target)
    keys.target:PreventDI()
    keys.target:SetPhysicsFriction(0)
	local vectorC = (keys.target:GetAbsOrigin() - keys.caster:GetAbsOrigin()) 
	-- get the direction where target will be pushed back to
	local vectorB = vectorC - vectorA
	keys.target:SetPhysicsVelocity(vectorB:Normalized() * 1000)
    keys.target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	local initialUnitOrigin = keys.target:GetAbsOrigin()
	
	keys.target:OnPhysicsFrame(function(unit) -- pushback distance check
		local unitOrigin = unit:GetAbsOrigin()
		local diff = unitOrigin - initialUnitOrigin
		local n_diff = diff:Normalized()
		unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
		if diff:Length() > 500 then -- if pushback distance is over 500, stop it
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			unit:OnPhysicsFrame(nil)
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		end
	end)
	
	keys.target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
	end)
end

function SaberCheckCombo(caster, ability)
	if caster:GetStrength() >= 20 and caster:GetAgility() >= 20 and caster:GetIntellect() >= 20 then
		if ability == caster:FindAbilityByName("saber_avalon") and caster:FindAbilityByName("saber_excalibur"):IsCooldownReady() and caster:FindAbilityByName("saber_max_excalibur"):IsCooldownReady() then
			caster:SwapAbilities("saber_excalibur", "saber_max_excalibur", true, true) 
			Timers:CreateTimer({
				endTime = 3,
				callback = function()
				caster:SwapAbilities("saber_excalibur", "saber_max_excalibur", true, true)
			end
			})			
		end
	end
end



function OnImproveExcaliburAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	ply.IsExcaliburAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnImproveInstinctAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	ply.IsInstinctImproved = true

	hero:FindAbilityByName("saber_improved_instinct"):SetLevel(1)
	hero:SwapAbilities("saber_instinct","saber_improved_instinct", false, true)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnChivalryAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	ply.IsChivalryAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnStrikeAirAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:SwapAbilities("saber_charisma","saber_strike_air", true, true)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end
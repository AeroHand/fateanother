require("physics")
require("util")
cdummy = nil

function OnManaEssenceAcquired(keys)
	print("Mana Essence Purchased")
end 

function OnBaseEntered(trigger)
	local hero = trigger.activator
	hero.IsInBase = true
	FireGameEvent( 'custom_error_show', { player_ID = hero:GetPlayerOwnerID(), _error = "Entered Base(Regular Item Cost)"} )
	print("Base entered")
end

function OnBaseLeft(trigger)
	local hero = trigger.activator
	hero.IsInBase = false
	
	FireGameEvent( 'custom_error_show', { player_ID = hero:GetPlayerOwnerID(), _error = "Left Base(50% Additiona Item Cost)" } )
	print("Base left")
end

function TransferItem(keys)
	local item = keys.ability
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	print("Transfering item to hero")
	local stash_item = hero:GetItemInSlot(keys.Slot+5) -- This looks for slot 6/7/8/9/10/11(Stash)
	--PrintTable(stash_item)
	-- If item is found, remove it from stash and add it to hero
	if stash_item ~= nil then
		--[[If hero has empty inventory slot, move item to hero
		local hero_item = hero:GetItemInSlot(i)
		for i=0, 5 do
			if hero_item == nil then
				hero:AddItem(stash_item) 
				caster:RemoveItem(stash_item)
				return
			end
		end]]
		local itemName = stash_item:GetName()
		hero:RemoveItem(stash_item) 
		--Timers:CreateTimer( 0.033, function()
		   	hero:AddItem(CreateItem(itemName, hero, hero)) 
		   	--return 
		--end)

		--[[hero:DropItemAtPosition(hero:GetAbsOrigin() , stash_item) 
		local dropitem = Entities:FindAllByClassname("dota_item_drop")
		print(#dropitem)
		hero:PickupDroppedItem(dropitem[1]) ]]
	else
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "No Items Found in Chosen Slot of Stash" } )
	end


end

function PotInstantHeal(keys)
	local caster = keys.caster
	caster:Heal(500, caster)
	caster:GiveMana(300) 

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification_g.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin()) -- target effect location

end

local TPLoc = nil 
function TPScroll(keys)
	print("TP initiated")
	local caster = keys.caster
	local targetPoint = keys.target_points[1]

	local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, 3000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_OTHER, 0, FIND_CLOSEST, false) 


	TPLoc = targets[1]:GetAbsOrigin() 
end

function TPSuccess(keys)
	print("TP successful")
	local caster = keys.caster
	caster:SetAbsOrigin(TPLoc)
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

function MassTPSuccess(keys)
	local caster = keys.caster
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1000
            , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)	
	for k,v in pairs(targets) do
		v:SetAbsOrigin(TPLoc)
		FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
	end

end

function TPFail(keys)
	print("TP failed")
end

function WardFam(keys)
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	local ward = CreateUnitByName("ward_familiar", targetPoint, true, caster, caster, caster:GetTeamNumber())
	ward:AddNewModifier(caster, caster, "modifier_invisible", {}) 
	ward:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 1600, duration = 105}) 
    ward:AddNewModifier(caster, caster, "modifier_kill", {duration = 105})
end

function ScoutFam(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerID()
	local scout = CreateUnitByName("scout_familiar", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	scout:SetControllableByPlayer(pid, true)
	keys.ability:ApplyDataDrivenModifier(caster, scout, "modifier_banished", {}) 
	LevelAllAbility(scout)
   	scout:AddNewModifier(caster, nil, "modifier_kill", {duration = 40})
end

function BecomeWard(keys)
	local caster = keys.caster
	local transform = CreateUnitByName("ward_familiar", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())

	transform:AddNewModifier(caster, caster, "modifier_invisible", {}) 
	transform:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 1600, duration = 105}) 
	transform:AddNewModifier(caster, caster, "modifier_kill", {duration = 105})
	caster:EmitSound("DOTA_Item.ObserverWard.Activate") 
	Timers:CreateTimer({
		endTime = 0.1,
		callback = function()
		caster:RemoveSelf() 
		return
	end
	})
end

function SpiritLink(keys)
	print("Spirit Link Used")
	local caster = keys.caster
	local targets = keys.target_entities
	--local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
	local linkTargets = {}
	caster:EmitSound("Hero_Warlock.FatalBonds" )
	-- set up table for link
	for i=1,#targets do
		linkTargets[i] = targets[i]
		--print("Added hero to link table : " .. targets[i]:GetName())
		RemoveHeroFromLinkTables(targets[i])

		-- particle
    	local pulse = ParticleManager:CreateParticle( "particles/units/heroes/hero_warlock/warlock_fatal_bonds_pulse.vpcf", PATTACH_CUSTOMORIGIN, caster )
	    ParticleManager:SetParticleControl( pulse, 0, caster:GetAbsOrigin())
	    ParticleManager:SetParticleControl( pulse, 1, targets[i]:GetAbsOrigin())
	end

	-- add list of linked targets to hero table
	for i=1,#targets do	
		targets[i].linkTable = linkTargets
		print("Table Contents " .. i .. " : " .. targets[i]:GetName())
		keys.ability:ApplyDataDrivenModifier(caster, targets[i], "modifier_share_damage", {}) 
	end
end

function OnLinkDamageTaken(keys)
    LoopOverHeroes(function(hero)
        if hero:HasModifier("modifier_share_damage") and hero:GetHealth() == 0 then
            print("Spirit Link broken on " .. hero:GetName())
            hero:SetHealth(1)
            hero:RemoveModifierByName("modifier_share_damage")
            RemoveHeroFromLinkTables(hero)
        end    
    end)
end

function OnLinkDestroyed(keys)
	local caster = keys.caster
	local target = keys.target
end

function GemOfResonance(keys)
	-- body
end


function Blink(keys)
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local targetPoint = keys.target_points[1]
	local newTargetPoint = nil

	if caster:HasModifier("modifier_purge") then 
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Cannot blink while Purged" } )
		keys.ability:EndCooldown()
		return
	end

	if GridNav:IsBlocked(targetPoint) or not GridNav:IsTraversable(targetPoint) then
		keys.ability:EndCooldown()  
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Cannot Travel to Targeted Location" } )
		return 
	end 

	 
	-- particle
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_blink_start.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, casterPos)
	caster:EmitSound("Hero_Antimage.Blink_out")
	local diff = targetPoint - caster:GetAbsOrigin()
	local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_blink_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	-- blink
	if diff:Length() <= 1000 then 
		caster:SetAbsOrigin(targetPoint)
		ProjectileManager:ProjectileDodge(caster)
		ParticleManager:SetParticleControl(particle2, 0, targetPoint)

	else  
		newTargetPoint = caster:GetAbsOrigin() + diff:Normalized() * 1000
		local i = 1
		while GridNav:IsBlocked(newTargetPoint) or not GridNav:IsTraversable(newTargetPoint) do
			i = i+1
			newTargetPoint = caster:GetAbsOrigin() + diff:Normalized() * (1000 - i*50)
		end

		caster:SetAbsOrigin(newTargetPoint) 
		ProjectileManager:ProjectileDodge(caster)
		ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
	end

	
	caster:EmitSound("Hero_Antimage.Blink_in")

	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

function StashBlink(keys)
	local caster = keys.caster
	local casterinitloc = caster:GetAbsOrigin() 
	local targetPoint = keys.target_points[1]
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	caster:SetAbsOrigin(hero:GetAbsOrigin())
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	
	Timers:CreateTimer(8.0, function() 
		caster:SetAbsOrigin(casterinitloc) 
		return
	end)

	caster:EmitSound("DOTA_Item.BlinkDagger.Activate")
	local particle2 = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle2, 1, caster:GetAbsOrigin()) -- target effect location
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

function CScroll(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerID()
	cdummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	ccaster = caster
	local dummy_passive = cdummy:FindAbilityByName("dummy_unit_passive")
	dummy_passive:SetLevel(1)
	local fire = cdummy:FindAbilityByName("dummy_c_scroll")
	fire:SetLevel(1)
	if fire:IsFullyCastable() then 
		cdummy:CastAbilityOnTarget(keys.target, fire, pid)
	end

	caster:RemoveItem(keys.ability)
end

function CScrollHit(keys)
	if IsSpellBlocked(keys.target) then return end
	DoDamage(keys.caster:GetPlayerOwner():GetAssignedHero(), keys.target, 100, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	keys.target:EmitSound("Hero_EmberSpirit.FireRemnant.Explode")
	if not keys.target:IsMagicImmune() then
		keys.target:AddNewModifier(keys.caster:GetPlayerOwner():GetAssignedHero(), keys.target, "modifier_stunned", {Duration = 1.0}) 
	end
	--keys.caster:RemoveSelf()
end


function BScroll(keys)
	local caster = keys.caster
	caster.BShieldAmount = keys.ShieldAmount
	

end

function AScroll(keys)
	local caster = keys.caster
	local particle = ParticleManager:CreateParticle("particles/prototype_fx/item_linkens_buff_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function SScroll(keys)
	local caster = keys.caster
	local target = keys.target
	if IsSpellBlocked(keys.target) then return end

	DoDamage(caster, target, 400, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	ApplyPurge(target)
	local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, caster) 
	ParticleManager:SetParticleControl(bolt, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z+((target:GetBoundingMaxs().z - target:GetBoundingMins().z)/2)))
end

function EXScroll(keys)
	local caster = keys.caster
	local target = keys.target
	local lightning = {
		attacker = caster,
		victim = target,
		damage = 600,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = 0,
		ability = keys.ability
	}
	DoDamage(caster, target, 600, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	ApplyPurge(target)

	local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, caster) 
	ParticleManager:SetParticleControl(bolt, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z+((target:GetBoundingMaxs().z - target:GetBoundingMins().z)/2)))

	local forkCount = 0
	local dist = target:GetAbsOrigin() - caster:GetAbsOrigin()
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin() + dist:Normalized() * dist:Length2D() + 350 , nil, 700
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		if forkCount == 4 then return end
		if v ~= target then 
	        DoDamage(caster, v, 600, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	        bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, caster) 
	        ParticleManager:SetParticleControl(bolt, 1, Vector(v:GetAbsOrigin().x,v:GetAbsOrigin().y,v:GetAbsOrigin().z+((v:GetBoundingMaxs().z - v:GetBoundingMins().z)/2)))
	        forkCount = forkCount + 1
    	end
    end
end



function HealingScroll(keys)
	local caster = keys.caster
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification_g.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 600
            , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		print("heal")
		ParticleManager:SetParticleControl(particle, 1, v:GetAbsOrigin()) -- target effect location
         v:Heal(500, caster) 
    end
end

function AntiMagic(keys)
	local caster = keys.caster
	caster:EmitSound("DOTA_Item.BlackKingBar.Activate")
end

function FullHeal(keys)
	local caster = keys.caster
	caster:SetHealth(caster:GetMaxHealth()) 
	caster:SetMana(caster:GetMaxMana())

	caster:EmitSound("DOTA_Item.Mekansm.Activate")
	ParticleManager:CreateParticle("particles/items2_fx/mekanism.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end
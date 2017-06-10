-- Config by LCR

AddCSLuaFile()

/* -------------------------------------------------- Effets / Decals des sabres -------------------------------------------------- */

-- game.AddDecal( "LSScorch", "effects/rb655_scorch" ) -- Why doesn't it work? (note de l'auteur)

function rb655_DrawHit( pos, dir )
	local effectdata = EffectData()
	effectdata:SetOrigin( pos )
	effectdata:SetNormal( dir )
	util.Effect( "StunstickImpact", effectdata, true, true )

	--util.Decal( "LSScorch", pos + dir, pos - dir )
	util.Decal( "FadingScorch", pos + dir, pos - dir )
end

if ( CLIENT ) then return end
/* -------------------------------------------------- Prevent +use pickup some users were reporting -------------------------------------------------- */

hook.Add( "AllowPlayerPickup", "rb655_lightsaber_prevent_use_pickup", function( ply, ent )
	if ( ent:GetClass() == "ent_lightsaber" ) then return false end
end )

/* -------------------------------------------------- Bruits (mort et "slice") -------------------------------------------------- */

local function DoSliceSound( victim, inflictor )
	if ( !IsValid( victim ) || !IsValid( inflictor ) ) then return end
	if ( string.find( inflictor:GetClass(), "_lightsaber" ) ) then
		victim:EmitSound( "lightsaber/saber_hit_laser" .. math.random( 1, 5 ) .. ".wav" )
	end
end

hook.Add( "EntityTakeDamage", "rb655_lightsaber_kill_snd", function( ent, dmg )
	if ( !IsValid( ent ) || !dmg || ent:IsNPC() || ent:IsPlayer() ) then return end
	if ( ent:Health() > 0 && ent:Health() - dmg:GetDamage() <= 0 ) then
		local infl = dmg:GetInflictor()
		if ( !IsValid( infl ) && IsValid( dmg:GetAttacker() ) && dmg:GetAttacker().GetActiveWeapon ) then // Ugly fucking haxing workaround, thanks VOLVO
			infl = dmg:GetAttacker():GetActiveWeapon()
		end
		DoSliceSound( ent, infl )
	end
end )

hook.Add( "PlayerDeath", "rb655_lightsaber_kill_snd_ply", function( victim, inflictor, attacker )
	if ( !IsValid( inflictor ) && IsValid( attacker ) && attacker.GetActiveWeapon ) then inflictor = attacker:GetActiveWeapon() end // Ugly fucking haxing workaround, thanks VOLVO
	DoSliceSound( victim, inflictor )
end )

hook.Add( "OnNPCKilled", "rb655_lightsaber_kill_snd_npc", function( victim, attacker, inflictor )
	if ( !IsValid( inflictor ) && IsValid( attacker ) && attacker.GetActiveWeapon ) then inflictor = attacker:GetActiveWeapon() end // Ugly fucking haxing workaround, thanks VOLVO
	DoSliceSound( victim, inflictor )
end )

/* -------------------------------------------------- Dégats -------------------------------------------------- */

-- Liste des entités qui ne prennent pas de dégats venant des sabres !
local rb655_ls_nodamage = {
	npc_rollermine = true, -- Sigh, Lua could use arrays
	npc_turret_floor = true,
	npc_combinedropship = true,
	npc_helicopter = true,
	monster_tentacle = true,
	monster_bigmomma = true,
}
function rb655_LS_DoDamage( tr, wep )
	local ent = tr.Entity

	if ( !IsValid( ent ) || ( ent:Health() <= 0 && ent:GetClass() != "prop_ragdoll" ) || rb655_ls_nodamage[ ent:GetClass() ] ) then return end

	local dmg = hook.Run( "CanLightsaberDamageEntity", ent, wep, tr ) or 25
	if ( dmg && dmg == false ) then return end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage( wep.SaberDamage or 100 )
	--MAKE MUCH NPC DAMAGE -- if ( ent:IsNPC() || !wep:IsWeapon() ) then dmginfo:SetDamage( dmg * 25 ) end
	dmginfo:SetDamageForce( tr.HitNormal * -13.37 )
	if !wep.CanKnockback then
		dmginfo:SetDamageForce( tr.HitNormal * 0 )	
	end
	if ( !ent:IsPlayer() || !ent:IsWeapon() ) then
		// This causes the damage to apply force the the target, which we do not want
		// For now, only apply it to the SENT
		dmginfo:SetInflictor( wep )
	end
	if ( ent:GetClass() == "npc_zombie" || ent:GetClass() == "npc_fastzombie" ) then
		dmginfo:SetDamageType( bit.bor( DMG_SLASH, DMG_CRUSH ) )
		dmginfo:SetDamageForce( tr.HitNormal * 0 )
	end
	if ( !IsValid( wep.Owner ) ) then
		dmginfo:SetAttacker( wep )
	else
		dmginfo:SetAttacker( wep.Owner )
		if wep.Owner:GetNWFloat( "RageTime", 0 ) >= CurTime() then
			dmginfo:ScaleDamage( 1.2 )
		end
	end

	ent:TakeDamageInfo( dmginfo )
	if !wep.CanKnockback then
		ent:SetVelocity( ent:GetVelocity()*-1 )
	end
end

function rb655_LS_DoDamage2( tr, wep )
	local ent = tr.Entity

	if ( !IsValid( ent ) || ( ent:Health() <= 0 && ent:GetClass() != "prop_ragdoll" ) || rb655_ls_nodamage[ ent:GetClass() ] ) then return end

	local dmg = hook.Run( "CanLightsaberDamageEntity", ent, wep, tr ) or 25
	if ( dmg && dmg == false ) then return end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage( wep.SaberDamage or 100 )
	if ( ent:IsNPC() || !wep:IsWeapon() ) then dmginfo:SetDamage( dmg * 25 ) end
	dmginfo:SetDamageForce( tr.HitNormal * -13.37 )
	if ( !ent:IsPlayer() || !ent:IsWeapon() ) then
		// This causes the damage to apply force the the target, which we do not want
		// For now, only apply it to the SENT
		dmginfo:SetInflictor( wep )
	end
	if ( ent:GetClass() == "npc_zombie" || ent:GetClass() == "npc_fastzombie" ) then
		dmginfo:SetDamageType( bit.bor( DMG_SLASH, DMG_CRUSH ) )
		dmginfo:SetDamageForce( tr.HitNormal * 0 )
	end
	if ( !IsValid( wep.Owner ) ) then
		dmginfo:SetAttacker( wep )
	else
		dmginfo:SetAttacker( wep.Owner )
	end

	ent:TakeDamageInfo( dmginfo )
end
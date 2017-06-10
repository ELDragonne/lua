-- Config by LCR


if ( SERVER ) then
		concommand.Add( "rb655_select_force_lbf", function( ply, cmd, args )
		if ( !IsValid( ply ) || !IsValid( ply:GetActiveWeapon() ) || !ply:GetActiveWeapon().IsLightsaber || !tonumber( args[ 1 ]) ) then return end

		local wep = ply:GetActiveWeapon()
		local typ = math.Clamp( tonumber( args[ 1 ]), 1, #wep.ForcePowers )
		wep:SetForceType( typ )

	end )
end

hook.Add( "GetFallDamage", "rb655_lightsaber_no_fall_damage_lbf", function( ply, speed )
	if ( IsValid( ply ) && IsValid( ply:GetActiveWeapon() ) && ply:GetActiveWeapon().IsLightsaber ) then
		local wep = ply:GetActiveWeapon()

		if ( ply:KeyDown( IN_DUCK ) ) then
			ply:SetNWFloat( "SWL_FeatherFall", CurTime() ) -- Hate on me for NWVars!
			wep:SetNextAttack( 0.5 )
			ply:ViewPunch( Angle( speed / 32, 0, math.random( -speed, speed ) / 128 ) )
			return 0
		end
	end
end )

hook.Add("UpdateAnimation", "Kadb_UpdateAnim",function(ply,velocity,maxseqgroundspeed)
	if not IsValid(ply:GetActiveWeapon()) or !ply:GetActiveWeapon().IsLightsaber then return end
	local len = velocity:Length()
	local movement = 1.0

	if ( len > 0.2 ) then
		movement = ( len / ply:GetWalkSpeed() )
	end

	local rate = math.min( movement, 2 )

	ply:SetPlaybackRate( ply:GetActiveWeapon().ForcedAnimSpeed or rate )
	return true
end )
timer.Simple( 8, function()
	hook.Add( "EntityTakeDamage", "arb655_sabers_armor_lbf", function( victim, dmg )
		local ply = victim
		if ( !ply.GetActiveWeapon || !ply:IsPlayer() ) then return end
		local wep = ply:GetActiveWeapon()
		if ( !IsValid( wep ) || !wep.IsLightsaber || wep.ForcePowers[ wep:GetForceType() ].name != "Barrage de Force" ) then return end
		if ( !ply:KeyDown( IN_ATTACK2 ) /*|| !ply:IsOnGround()*/ ) then return end
		local damage = dmg:GetDamage() / 7
		dmg:SetDamage( 0 )
		local force = wep:GetForce()
		if ( force < damage ) then
			wep:SetForce( 0 )
			dmg:SetDamage( ( damage - force ) * 5 )
			return
		end
		wep:SetForce( force - damage )
	end )

	hook.Add( "EntityTakeDamage", "arb655_sabers_reflect_lbf", function( ply, dmginfo )
		if ( !ply.GetActiveWeapon || !ply:IsPlayer() ) then return end
		if ply:GetNWFloat( "ReflectTime", 0 ) < CurTime() then return end
		local attacker = dmginfo:GetAttacker()
		if !IsValid( attacker ) then return end
		if !attacker:IsPlayer() then return end
		local damage = dmginfo:GetDamage()
		dmginfo:SetDamage( 0 )
		if attacker:GetNWFloat( "ReflectTime", 0 ) > CurTime() then return end
		
		local reflectdamage = DamageInfo()
		reflectdamage:SetAttacker( ply )
		reflectdamage:SetInflictor( ply:GetActiveWeapon() )
		reflectdamage:SetDamage( damage )
		attacker:TakeDamageInfo( reflectdamage )
		
	end )
end )

-- hook.Add("SetupMove", "ForceJumps!", function(ply, mv)
--	if ply:OnGround() then
--		return
--	end

--	if not IsValid(ply:GetActiveWeapon()) or !ply:GetActiveWeapon().IsLightsaber then return end

--	if not mv:KeyPressed(IN_JUMP) then
--		return
--	end

--	if ply:GetActiveWeapon():GetForce() < 10 then return end

--	ply:GetActiveWeapon():SetForce(ply:GetActiveWeapon():GetForce() - 10)
--	mv:SetVelocity(ply:GetAimVector() * 512 + Vector( 0, 0, 256 ))

--	ply:DoCustomAnimEvent(PLAYERANIMEVENT_JUMP , -1) 
-- end) 



hook.Add("CalcMainActivity", "lBf.ForceMeditate", function(pl, _)
    if(pl:GetNWBool("IsMeditating", false))then
        return pl:SetSequence(pl:LookupSequence( "sit_zen" ));
    end
end)

hook.Add( "PlayerDeath", "MeditateDead", function(pl, _)
    if(pl:GetNWBool("IsMeditating", false))then
		pl:SetNWBool("IsMeditating", false)
		pl:SetMoveType(MOVETYPE_WALK)
	 end
end )	

if CLIENT then

	hook.Add( "CalcView", "!!!111_rb655_lightsaber_3rdperson_lbf", function( ply, pos, ang )
		if ( !IsValid( ply ) or !ply:Alive() or ply:InVehicle() or ply:GetViewEntity() != ply ) then return end
		if ( !LocalPlayer().GetActiveWeapon or !IsValid( LocalPlayer():GetActiveWeapon() ) or !LocalPlayer():GetActiveWeapon().IsLightsaber ) then return end

		local trace = util.TraceHull( {
			start = pos,
			endpos = pos - ang:Forward() * 100,
			filter = { ply:GetActiveWeapon(), ply },
			mins = Vector( -4, -4, -4 ),
			maxs = Vector( 4, 4, 4 ),
		} )

		if ( trace.Hit ) then pos = trace.HitPos else pos = pos - ang:Forward() * 100 end

		return {
			origin = pos,
			angles = ang,
			drawviewer = true
		}
	end )

	hook.Add( "CreateMove", "rb655_lightsaber_no_fall_damage_lbf", function( cmd/* ply, mv, cmd*/ )
		if ( CurTime() - LocalPlayer():GetNWFloat( "SWL_FeatherFall", CurTime() - 2 ) < 1 ) then
			cmd:ClearButtons() -- No attacking, we are busy
			cmd:ClearMovement() -- No moving, we are busy
			cmd:SetButtons( IN_DUCK ) -- Force them to crouch
		end
	end )

	hook.Add( "PlayerBindPress", "rb655_sabers_force_lbf", function( ply, bind, pressed )
		if ( LocalPlayer():InVehicle() || ply != LocalPlayer() || !LocalPlayer():Alive() || !IsValid( LocalPlayer():GetActiveWeapon() ) || !LocalPlayer():GetActiveWeapon().IsLightsaber ) then ForceSelectEnabled = false return end
		local wep = LocalPlayer():GetActiveWeapon()
		if ( bind == "impulse 100" && pressed ) then
			wep.ForceSelectEnabled = !wep.ForceSelectEnabled
			return true
		end

		if ( !wep.ForceSelectEnabled ) then return end

		if ( bind:StartWith( "slot" ) ) then
			RunConsoleCommand( "rb655_select_force_lbf", bind:sub( 5 ) )
			return true
		end
	end )

	hook.Add( "PreDrawHalos", "lBf.ForceHolograms", function()

	local reflectors = {}
	local ragers = {}	
	local absorbtor = {}	
	
	for _,ply in pairs( player.GetAll() ) do
		if not IsValid( ply ) then continue end
		if not ply:Alive() then continue end
		if ply:GetNWFloat( "ReflectTime", 0 ) >= CurTime() then
			table.insert( reflectors, ply )
		end
		if ply:GetNWFloat( "RageTime", 0 ) >= CurTime() then
			table.insert( ragers, ply )
		end
		if ply:GetNWFloat( "AbsorbTime", 0 ) >= CurTime() then
			table.insert( absorbtor, ply )
		end
	end
	
	halo.Add( reflectors, Color( 0, 0, 255, 175 ), 5, 5, 3, true, false )
	halo.Add( ragers, Color( 255, 0, 0, 175 ), 5, 5, 3, true, false )
	halo.Add( absorbtor, Color( 0, 0, 255, 175 ), 5, 5, 3, true, false )
	end )
	
end




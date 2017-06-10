-- Config by LCR


hook.Add( "PostPlayerDraw", "lBf.DualSaberFixed", function( ply )

	local wep = ply:GetActiveWeapon()

	if ply:GetNWFloat( "CloakTime", 0 ) >= CurTime() then

		if ply:GetVelocity():Length() < 1 then

			if IsValid( wep ) then

				wep:SetMaterial("models/effects/vol_light001")

				wep:SetColor( Color( 0, 0, 0, 0 ) )

				

			end

			ply:SetMaterial("models/effects/vol_light001")

			ply:SetColor( Color( 0, 0, 0, 0 ) )

			ply:DrawShadow( false )

		else

			if IsValid( wep ) then

				wep:SetMaterial("models/shadertest/shader3")	

				wep:SetColor( Color( 255, 255, 255, 255 ) )

			end

			ply:SetMaterial("models/shadertest/shader3")

			ply:SetColor( Color( 255, 255, 255, 255 ) )

		end

	else

		if IsValid( wep ) then

			

			wep:SetColor( Color( 255, 255, 255, 0 ) )

		end

		ply:SetMaterial("")		

		ply:SetColor( Color( 255, 255, 255, 0 ) )

		ply:DrawShadow( true )

	end



	if !IsValid( wep ) or !wep.IsDualLightsaber then return end



	if ( !ply.DualWielded ) then

		ply.DualWielded = ClientsideModel( wep:GetSecWorldModel(), RENDERGROUP_BOTH ) -- wep.WorldModel is nil?

		ply.DualWielded:SetNoDraw( true )

	end

	ply.DualWielded:SetModel( wep:GetSecWorldModel() )



	local bone = ply:LookupBone( "ValveBiped.Bip01_L_Hand" )

	local pos, ang = ply:GetBonePosition( bone )

	if ( pos == ply:GetPos() ) then

		local matrix = ply:GetBoneMatrix( bone )

		if ( matrix ) then

			pos = matrix:GetTranslation()

			ang = matrix:GetAngles()

		end

	end

	



	ang:RotateAroundAxis( ang:Up(), 30 )

	ang:RotateAroundAxis( ang:Forward(), -5.7 )

	ang:RotateAroundAxis( ang:Right(), 92 )

	local offset = -5

	if wep:GetSecWorldModel():find( "_kr_" ) then

		offset = -1

	end

	pos = pos + ang:Up() * -3.3 + ang:Right() * 3.4 + ang:Forward()*offset

	



	ply.DualWielded:SetPos( pos )

	ply.DualWielded:SetAngles( ang )

	

	local clr = wep:GetSecCrystalColor()

	clr = Color( clr.x, clr.y, clr.z )

	

	ply.DualWielded:DrawModel()

	

	local model = ply.DualWielded

	

	if ply:GetNWFloat( "CloakTime", 0 ) >= CurTime() then

		if ply:GetVelocity():Length() < 1 then

			ply.DualWielded:SetMaterial("models/effects/vol_light001")

			ply.DualWielded:SetColor( Color( 0, 0, 0, 0 ) )

			return

		else

			ply.DualWielded:SetMaterial("models/shadertest/shader3")

			ply.DualWielded:SetColor( Color( 255, 255, 255, 0 ) )

			return

		end		

	else

		ply.DualWielded:SetMaterial( "" )

		ply.DualWielded:SetColor( Color( 255, 255, 255, 0 ) )

	end

	

	local bladesFound = false -- true if the model is OLD and does not have blade attachments

	local blades = 0



	for id, t in pairs( model:GetAttachments() ) do

		if ( !string.match( t.name, "blade(%d+)" ) && !string.match( t.name, "quillon(%d+)" ) ) then continue end



		local bladeNum = string.match( t.name, "blade(%d+)" )

		local quillonNum = string.match( t.name, "quillon(%d+)" )

		if ( bladeNum && model:LookupAttachment( "blade" .. bladeNum ) > 0 ) then

			blades = blades + 1

			local pos, dir = wep:GetSaberSecPosAng( bladeNum, false, model )

			rb655_RenderBlade( pos, dir, wep:GetSecBladeLength(), wep:GetSecMaxLength(), wep:GetSecBladeWidth(), clr, wep:GetSecDarkInner(), wep:EntIndex(), wep:GetOwner():WaterLevel() > 2, false, blades )

			bladesFound = true

		end



		if ( quillonNum && model:LookupAttachment( "quillon" .. quillonNum ) > 0 ) then

			blades = blades + 1

			local pos, dir = wep:GetSaberSecPosAng( quillonNum, true, model )

			rb655_RenderBlade( pos, dir, wep:GetSecBladeLength(), wep:GetSecMaxLength(), wep:GetSecBladeWidth(), clr, wep:GetSecDarkInner(), wep:EntIndex(), wep:GetOwner():WaterLevel() > 2, true, blades )

		end



	end



	if ( !bladesFound ) then

		local pos, dir = wep:GetSaberSecPosAng( nil, nil, model )

		rb655_RenderBlade( pos, dir, wep:GetSecBladeLength(), wep:GetSecMaxLength(), wep:GetSecBladeWidth(), clr, wep:GetSecDarkInner(), wep:EntIndex(), wep:GetOwner():WaterLevel() > 2 )

	end

	



end )
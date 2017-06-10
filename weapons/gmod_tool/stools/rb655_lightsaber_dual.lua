-- Config by LCR

TOOL.Category = "lBf Lightsaber"
TOOL.Name = "Dual Lightsaber"

TOOL.ClientConVar["model"] = "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl"
TOOL.ClientConVar["red"] = "0"
TOOL.ClientConVar["green"] = "127"
TOOL.ClientConVar["blue"] = "255"
TOOL.ClientConVar["bladew"] = "2"
TOOL.ClientConVar["bladel"] = "42"

TOOL.ClientConVar["model_single"] = "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl"
TOOL.ClientConVar["red_single"] = "0"
TOOL.ClientConVar["green_single"] = "127"
TOOL.ClientConVar["blue_single"] = "255"
TOOL.ClientConVar["dark_single"] = "0"
TOOL.ClientConVar["bladew_single"] = "2"
TOOL.ClientConVar["bladel_single"] = "42"


TOOL.ClientConVar["dark"] = "0"
TOOL.ClientConVar["starton"] = "1"

TOOL.ClientConVar["humsound"] = "lightsaber/saber_loop1.wav"
TOOL.ClientConVar["swingsound"] = "lightsaber/saber_swing1.wav"
TOOL.ClientConVar["onsound"] = "lightsaber/saber_on1.wav"
TOOL.ClientConVar["offsound"] = "lightsaber/saber_off1.wav"

cleanup.Register( "ent_lightsabers" )

if ( SERVER ) then
	CreateConVar( "sbox_maxent_lightsabers", 2 )

	function MakeLightsaber( ply, model, pos, ang, LoopSound, SwingSound, OnSound, OffSound )
		if ( IsValid( ply ) && !ply:CheckLimit( "ent_lightsabers" ) ) then return false end

		local ent_lightsaber = ents.Create( "ent_lightsaber" )
		if ( !IsValid( ent_lightsaber ) ) then return false end

		ent_lightsaber:SetModel( model )
		ent_lightsaber:SetAngles( ang )
		ent_lightsaber:SetPos( pos )
		--ent_lightsaber:SetCrystalColor( clr )
		--ent_lightsaber:SetColor( clr )
		--ent_lightsaber:SetEnabled( tobool( Enabled ) )

		table.Merge( ent_lightsaber:GetTable(), {
			Owner = ply,
			--clr = clr,
			--Enabled = tobool( Enabled ),
			LoopSound = LoopSound,
			SwingSound = SwingSound,
			OnSound = OnSound,
			OffSound = OffSound,
		} )

		ent_lightsaber:Spawn()
		ent_lightsaber:Activate()

		if ( IsValid( ply ) ) then
			ply:AddCount( "ent_lightsabers", ent_lightsaber )
			ply:AddCleanup( "ent_lightsabers", ent_lightsaber )
		end

		DoPropSpawnedEffect( ent_lightsaber )

		return ent_lightsaber
	end

	duplicator.RegisterEntityClass( "ent_lightsaber", MakeLightsaber, "model", "pos", "ang", "LoopSound", "SwingSound", "OnSound", "OffSound" )
end

function TOOL:LeftClick( trace )

	return true
end

function TOOL:RightClick( trace )
	if ( trace.HitSky || !trace.HitPos ) then return false end
	if ( IsValid( trace.Entity ) && ( trace.Entity:GetClass() == "ent_lightsaber" ) ) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()
	--[[if ( IsValid( ply:GetEyeTrace().Entity ) && ply:GetEyeTrace().Entity:IsPlayer() ) then
		ply = ply:GetEyeTrace().Entity
	end]]

	ply:StripWeapon( "lbf_dual_lightsaber" )
	local w = ply:Give( "lbf_dual_lightsaber" )

	w:SetMaxLength( math.Clamp( ply:GetInfoNum( "rb655_lightsaber_dual_bladel_single", 42 ), 32, 64 ) )
	w:SetSecMaxLength( math.Clamp( ply:GetInfoNum( "rb655_lightsaber_dual_bladel", 42 ), 32, 64 ) )
	w:SetCrystalColor( Vector( ply:GetInfo( "rb655_lightsaber_dual_red_single" ), ply:GetInfo( "rb655_lightsaber_dual_green_single" ), ply:GetInfo( "rb655_lightsaber_dual_blue_single" ) ) )
	w:SetDarkInner( ply:GetInfo( "rb655_lightsaber_dual_dark_single" ) == "1" )
	w:SetWorldModel( ply:GetInfo( "rb655_lightsaber_dual_model_single" ) )
	w:SetSecCrystalColor( Vector( ply:GetInfo( "rb655_lightsaber_dual_red" ), ply:GetInfo( "rb655_lightsaber_dual_green" ), ply:GetInfo( "rb655_lightsaber_dual_blue" ) ) )
	w:SetSecDarkInner( ply:GetInfo( "rb655_lightsaber_dual_dark" ) == "1" )
	w:SetSecWorldModel( ply:GetInfo( "rb655_lightsaber_dual_model" ) )
	w:SetBladeWidth( math.Clamp( ply:GetInfoNum( "rb655_lightsaber_dual_bladew_single", 2 ), 2, 4 ) )
	w:SetSecBladeWidth( math.Clamp( ply:GetInfoNum( "rb655_lightsaber_dual_bladew", 2 ), 2, 4 ) )
	
	w.LoopSound = ply:GetInfo( "rb655_lightsaber_dual_humsound" )
	w.SwingSound = ply:GetInfo( "rb655_lightsaber_dual_swingsound" )
	w:SetOnSound( ply:GetInfo( "rb655_lightsaber_dual_onsound" ) )
	w:SetOffSound( ply:GetInfo( "rb655_lightsaber_dual_offsound" ) )
	w:SetEnabled( tobool( ply:GetInfo( "rb655_lightsaber_dual_starton" ) ) )

	timer.Simple( 0.2, function() ply:SelectWeapon( "lbf_dual_lightsaber" ) end )

	return true
end

function TOOL:UpdateGhostEntity( ent, ply )
	if ( !IsValid( ent ) ) then return end

	local trace = ply:GetEyeTrace()

	if ( !trace.Hit ) then ent:SetNoDraw( true ) return end
	if ( IsValid( trace.Entity ) && trace.Entity:GetClass() == "ent_lightsaber" || trace.Entity:IsPlayer() || trace.Entity:IsNPC() ) then ent:SetNoDraw( true ) return end

	local ang = trace.HitNormal:Angle()
	ang.p = ang.p - 90

	if ( trace.HitNormal.z > 0.99 ) then ang.y = ply:GetAngles().y end

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )

	ent:SetAngles( ang )
	ent:SetNoDraw( false )
end

function TOOL:Think()
	if ( !IsValid( self.GhostEntity ) || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) )
	end

	self:UpdateGhostEntity( self.GhostEntity, self:GetOwner() )
end

list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.1", { rb655_lightsaber_humsound = "lightsaber/saber_loop1.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.2", { rb655_lightsaber_humsound = "lightsaber/saber_loop2.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.3", { rb655_lightsaber_humsound = "lightsaber/saber_loop3.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.4", { rb655_lightsaber_humsound = "lightsaber/saber_loop4.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.5", { rb655_lightsaber_humsound = "lightsaber/saber_loop5.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.6", { rb655_lightsaber_humsound = "lightsaber/saber_loop6.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.7", { rb655_lightsaber_humsound = "lightsaber/saber_loop7.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.hum.8", { rb655_lightsaber_humsound = "lightsaber/saber_loop8.wav" } )
list.Set( "rb655_LightsaberHumSounds", "#tool.rb655_lightsaber.dark", { rb655_lightsaber_humsound = "lightsaber/darksaber_loop.wav" } )

list.Set( "rb655_LightsaberSwingSounds", "#tool.rb655_lightsaber.jedi", { rb655_lightsaber_swingsound = "lightsaber/saber_swing1.wav" } )
list.Set( "rb655_LightsaberSwingSounds", "#tool.rb655_lightsaber.sith", { rb655_lightsaber_swingsound = "lightsaber/saber_swing2.wav" } )
list.Set( "rb655_LightsaberSwingSounds", "#tool.rb655_lightsaber.dark", { rb655_lightsaber_swingsound = "lightsaber/darksaber_swing.wav" } )

list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.jedi", { rb655_lightsaber_onsound = "lightsaber/saber_on1.wav", rb655_lightsaber_offsound = "lightsaber/saber_off1.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.jedi_fast", { rb655_lightsaber_onsound = "lightsaber/saber_on1_fast.wav", rb655_lightsaber_offsound = "lightsaber/saber_off1_fast.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.sith", { rb655_lightsaber_onsound = "lightsaber/saber_on2.wav", rb655_lightsaber_offsound = "lightsaber/saber_off2.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.sith_fast", { rb655_lightsaber_onsound = "lightsaber/saber_on2_fast.wav", rb655_lightsaber_offsound = "lightsaber/saber_off2_fast.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.heavy", { rb655_lightsaber_onsound = "lightsaber/saber_on3.wav", rb655_lightsaber_offsound = "lightsaber/saber_off3.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.heavy_fast", { rb655_lightsaber_onsound = "lightsaber/saber_on3_fast.wav", rb655_lightsaber_offsound = "lightsaber/saber_off3_fast.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.jedi2", { rb655_lightsaber_onsound = "lightsaber/saber_on4.wav", rb655_lightsaber_offsound = "lightsaber/saber_off4.mp3" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.jedi2_fast", { rb655_lightsaber_onsound = "lightsaber/saber_on4_fast.wav", rb655_lightsaber_offsound = "lightsaber/saber_off4_fast.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.dark", { rb655_lightsaber_onsound = "lightsaber/darksaber_on.wav", rb655_lightsaber_offsound = "lightsaber/darksaber_off.wav" } )
list.Set( "rb655_LightsaberIgniteSounds", "#tool.rb655_lightsaber.kylo", { rb655_lightsaber_onsound = "lightsaber/saber_on_kylo.wav", rb655_lightsaber_offsound = "lightsaber/saber_off_kylo.wav" } )

list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_anakin_ep3_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_common_jedi_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_luke_ep6_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_mace_windu_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_maul_saber_half_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_obiwan_ep1_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_obiwan_ep3_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_quigon_gin_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_sidious_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_vader_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_yoda_saber_hilt.mdl", {} )
list.Set( "LightsaberModels", "models/weapons/starwars/w_kr_hilt.mdl", {} )

list.Set( "LightsaberModels", "models/weapons/starwars/w_maul_saber_staff_hilt.mdl", {} )
--list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_maul_saber_hilt.mdl", {} )

list.Set( "LightsaberModels", "models/weapons/starwars/w_dooku_saber_hilt.mdl", {} )
--list.Set( "LightsaberModels", "models/sgg/starwars/weapons/w_dooku_saber_hilt.mdl", {} )

if ( SERVER ) then return end

TOOL.Information = {
	{ name = "left" },
	{ name = "right" }
}

language.Add( "tool.rb655_lightsaber_dual", "Lightsabers" )
language.Add( "tool.rb655_lightsaber_dual.name", "Lightsabers" )
language.Add( "tool.rb655_lightsaber_dual.desc", "Spawn customized lightsabers" )
language.Add( "tool.rb655_lightsaber_dual.left", "Spawn a Lightsaber Weapon" )
language.Add( "tool.rb655_lightsaber_dual.right", "Give yourself a Lightsaber Weapon" )

language.Add( "tool.rb655_lightsaber_dual.model", "Hilt" )
language.Add( "tool.rb655_lightsaber_dual.color", "Crystal Color" )
language.Add( "tool.rb655_lightsaber_dual.take", "Take this lightsaber" )

language.Add( "tool.rb655_lightsaber_dual.DarkInner", "Dark inner blade" )
language.Add( "tool.rb655_lightsaber_dual.StartEnabled", "Enabled on spawn" )

language.Add( "tool.rb655_lightsaber_dual.HumSound", "Hum Sound" )
language.Add( "tool.rb655_lightsaber_dual.SwingSound", "Swing Sound" )
language.Add( "tool.rb655_lightsaber_dual.IgniteSound", "Ignition Sound" )

language.Add( "tool.rb655_lightsaber_dual.HudBlur", "Enable HUD Blur ( may reduce performance )" )

language.Add( "tool.rb655_lightsaber_dual.bladew", "Blade Width" )
language.Add( "tool.rb655_lightsaber_dual.bladel", "Blade Length" )

language.Add( "tool.rb655_lightsaber_dual.jedi", "Jedi" )
language.Add( "tool.rb655_lightsaber_dual.jedi_fast", "Jedi - Fast" )
language.Add( "tool.rb655_lightsaber_dual.sith", "Sith" )
language.Add( "tool.rb655_lightsaber_dual.sith_fast", "Sith - Fast" )
language.Add( "tool.rb655_lightsaber_dual.heavy", "Heavy" )
language.Add( "tool.rb655_lightsaber_dual.heavy_fast", "Heavy - Fast" )
language.Add( "tool.rb655_lightsaber_dual.jedi2", "Jedi - Original" )
language.Add( "tool.rb655_lightsaber_dual.jedi2_fast", "Jedi - Original Fast" )
language.Add( "tool.rb655_lightsaber_dual.dark", "Dark Saber" )
language.Add( "tool.rb655_lightsaber_dual.kylo", "Kylo Ren" )

language.Add( "tool.rb655_lightsaber_dual.hum.1", "Default" )
language.Add( "tool.rb655_lightsaber_dual.hum.2", "Sith Heavy" )
language.Add( "tool.rb655_lightsaber_dual.hum.3", "Medium" )
language.Add( "tool.rb655_lightsaber_dual.hum.4", "Heavish" )
language.Add( "tool.rb655_lightsaber_dual.hum.5", "Sith Assassin Light" )
language.Add( "tool.rb655_lightsaber_dual.hum.6", "Darth Vader" )
language.Add( "tool.rb655_lightsaber_dual.hum.7", "Heavy" )
language.Add( "tool.rb655_lightsaber_dual.hum.8", "Dooku" )

language.Add( "Cleanup_ent_lightsabers", "Lightsabers" )
language.Add( "Cleaned_ent_lightsabers", "Cleaned up all Lightsabers" )
language.Add( "SBoxLimit_ent_lightsabers", "You've hit the Lightsaber limit!" )
language.Add( "Undone_ent_lightsaber", "Lightsaber undone" )
language.Add( "max_ent_lightsabers", "Max Lightsabers" )

language.Add( "tool.rb655_lightsaber_dual.preset1", "Darth Maul's Saberstaff" )
language.Add( "tool.rb655_lightsaber_dual.preset2", "Darth Maul's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset3", "Darth Tyrannus's Lightsaber (Count Dooku)" )
language.Add( "tool.rb655_lightsaber_dual.preset4", "Darth Sidious's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset5", "Darth Vader's Lightsaber" )

language.Add( "tool.rb655_lightsaber_dual.preset6", "Master Yoda's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset7", "Qui-Gon Jinn's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset8", "Mace Windu's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset9", "[EP3] Obi-Wan Kenobi's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset10", "[EP1] Obi-Wan Kenobi's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset11", "[EP6] Luke Skywalker's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset12", "[EP2] Anakin Skywalker's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset13", "[EP3] Anakin Skywalker's Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset14", "Common Jedi Lightsaber" )
language.Add( "tool.rb655_lightsaber_dual.preset15", "Dark Saber" )
language.Add( "tool.rb655_lightsaber_dual.preset_kylo", "Kylo Ren's Crossguard Lightsaber" )

local ConVarsDefault = TOOL:BuildConVarList()

local PresetPresets = {
	[ "#preset.default" ] = ConVarsDefault,

	-- Sith
	[ "#tool.rb655_lightsaber_dual.preset1" ] = {
		rb655_lightsaber_dual_model = "models/weapons/starwars/w_maul_saber_staff_hilt.mdl",
		rb655_lightsaber_dual_red = "255",
		rb655_lightsaber_dual_green = "0",
		rb655_lightsaber_dual_blue = "0",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.4",
		rb655_lightsaber_dual_bladel = "45",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop7.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing2.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on2.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off2.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset2" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_maul_saber_half_hilt.mdl",
		rb655_lightsaber_dual_red = "255",
		rb655_lightsaber_dual_green = "0",
		rb655_lightsaber_dual_blue = "0",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.4",
		rb655_lightsaber_dual_bladel = "45",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop7.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing2.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on2.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off2.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset3" ] = {
		rb655_lightsaber_dual_model = "models/weapons/starwars/w_dooku_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "255",
		rb655_lightsaber_dual_green = "0",
		rb655_lightsaber_dual_blue = "0",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop8.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing2.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on2.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off2.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset4" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_sidious_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "255",
		rb655_lightsaber_dual_green = "0",
		rb655_lightsaber_dual_blue = "0",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.2",
		rb655_lightsaber_dual_bladel = "43",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop5.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing2.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on2.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off2.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset5" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_vader_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "255",
		rb655_lightsaber_dual_green = "0",
		rb655_lightsaber_dual_blue = "0",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.25",
		rb655_lightsaber_dual_bladel = "43",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop6.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing2.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on2.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off2.wav"
	},

	-- Jedi
	[ "#tool.rb655_lightsaber_dual.preset6" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_yoda_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "64",
		rb655_lightsaber_dual_green = "255",
		rb655_lightsaber_dual_blue = "64",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.3",
		rb655_lightsaber_dual_bladel = "40",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop3.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset7" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_quigon_gin_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "32",
		rb655_lightsaber_dual_green = "255",
		rb655_lightsaber_dual_blue = "32",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.2",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset8" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_mace_windu_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "127",
		rb655_lightsaber_dual_green = "0",
		rb655_lightsaber_dual_blue = "255",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset9" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_obiwan_ep3_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "48",
		rb655_lightsaber_dual_green = "48",
		rb655_lightsaber_dual_blue = "255",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.1",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset10" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_obiwan_ep1_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "48",
		rb655_lightsaber_dual_green = "48",
		rb655_lightsaber_dual_blue = "255",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.1",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset11" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_luke_ep6_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "32",
		rb655_lightsaber_dual_green = "255",
		rb655_lightsaber_dual_blue = "32",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.1",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset12" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "0",
		rb655_lightsaber_dual_green = "100",
		rb655_lightsaber_dual_blue = "255",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.1",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset13" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_anakin_ep3_saber_hilt.mdl",
		rb655_lightsaber_dual_red = "0",
		rb655_lightsaber_dual_green = "100",
		rb655_lightsaber_dual_blue = "255",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.1",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},
	[ "#tool.rb655_lightsaber_dual.preset14" ] = {
		rb655_lightsaber_dual_model = "models/sgg/starwars/weapons/w_common_jedi_saber_hilt.mdl",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.2",
		rb655_lightsaber_dual_bladel = "42",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on1.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off1.wav"
	},

	[ "#tool.rb655_lightsaber_dual.preset_kylo" ] = {
		rb655_lightsaber_dual_model = "models/weapons/starwars/w_kr_hilt.mdl",
		rb655_lightsaber_dual_red = "255",
		rb655_lightsaber_dual_green = "0",
		rb655_lightsaber_dual_blue = "0",
		rb655_lightsaber_dual_dark = "0",
		rb655_lightsaber_dual_bladew = "2.1",
		rb655_lightsaber_dual_bladel = "40",
		rb655_lightsaber_dual_humsound = "lightsaber/saber_loop1.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/saber_swing1.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/saber_on_kylo.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/saber_off_kylo.wav"
	},

	-- The Pre Vizsla's darksaber from clone wars, I LOVE IT
	[ "#tool.rb655_lightsaber_dual.preset15" ] = {
		rb655_lightsaber_dual_red = "255",
		rb655_lightsaber_dual_green = "255",
		rb655_lightsaber_dual_blue = "255",
		rb655_lightsaber_dual_dark = "1",
		rb655_lightsaber_dual_humsound = "lightsaber/darksaber_loop.wav",
		rb655_lightsaber_dual_swingsound = "lightsaber/darksaber_swing.wav",
		rb655_lightsaber_dual_onsound = "lightsaber/darksaber_on.wav",
		rb655_lightsaber_dual_offsound = "lightsaber/darksaber_off.wav"
	},
}

function TOOL.BuildCPanel( panel )
	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "rb655_lightsabers", Options = PresetPresets, CVars = table.GetKeys( ConVarsDefault ) } )

	panel:AddControl( "PropSelect", {Label = "#tool.rb655_lightsaber_dual.model", Height = 4, ConVar = "rb655_lightsaber_dual_model_single", Models = list.Get( "LightsaberModels" )} )
	panel:AddControl( "PropSelect", {Label = "Second Saber Hilt", Height = 4, ConVar = "rb655_lightsaber_dual_model", Models = list.Get( "LightsaberModels" )} )
	
	panel:AddControl( "Color", { Label = "#tool.rb655_lightsaber_dual.color", Red = "rb655_lightsaber_dual_red_single", Green = "rb655_lightsaber_dual_green_single", Blue = "rb655_lightsaber_dual_blue_single", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1" } )
	panel:AddControl( "Color", { Label = "Second Saber Color", Red = "rb655_lightsaber_dual_red", Green = "rb655_lightsaber_dual_green", Blue = "rb655_lightsaber_dual_blue", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1" } )

	panel:AddControl( "Checkbox", { Label = "#tool.rb655_lightsaber_dual.DarkInner", Command = "rb655_lightsaber_dual_dark_single" } )
	panel:AddControl( "Checkbox", { Label = "Second Dark Inner", Command = "rb655_lightsaber_dual_dark" } )
	
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_lightsaber_dual.StartEnabled", Command = "rb655_lightsaber_dual_starton" } )

	panel:AddControl( "Slider", {Label = "#tool.rb655_lightsaber_dual.bladeW", Type = "Float", Min = 2, Max = 4, Command = "rb655_lightsaber_dual_bladew_single"} )
	panel:AddControl( "Slider", {Label = "#tool.rb655_lightsaber_dual.bladeL", Type = "Float", Min = 32, Max = 64, Command = "rb655_lightsaber_dual_bladel_single"} )

	panel:AddControl( "Slider", {Label = "Second Blade Width", Type = "Float", Min = 2, Max = 4, Command = "rb655_lightsaber_dual_bladew"} )
	panel:AddControl( "Slider", {Label = "Second Blade Length", Type = "Float", Min = 32, Max = 64, Command = "rb655_lightsaber_dual_bladel"} )

	panel:AddControl( "ListBox", { Label = "#tool.rb655_lightsaber_dual.HumSound", Options = list.Get( "rb655_LightsaberHumSounds" ) } )
	panel:AddControl( "ListBox", { Label = "#tool.rb655_lightsaber_dual.SwingSound", Options = list.Get( "rb655_LightsaberSwingSounds" ) } )
	panel:AddControl( "ListBox", { Label = "#tool.rb655_lightsaber_dual.IgniteSound", Options = list.Get( "rb655_LightsaberIgniteSounds" ) } )

	panel:AddControl( "Checkbox", { Label = "#tool.rb655_lightsaber_dual.HudBlur", Command = "rb655_lightsaber_hud_blur" } )
end

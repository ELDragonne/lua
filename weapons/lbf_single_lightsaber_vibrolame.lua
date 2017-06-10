-- Config by La Bataille Finale

AddCSLuaFile()

if ( SERVER ) then
	util.AddNetworkString( "rb655_holdtype" )
	resource.AddWorkshop( "111412589" )
	CreateConVar( "rb655_lightsaber_infinite", "0" )
end

SWEP.PrintName = "Vibrolame d'Initié"
SWEP.Author = "Robotboy655 edit Watcher"
SWEP.Category = "Watcher's Weapons"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = "Pour vous entraîner au combat !"
SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.Slot = 4
SWEP.SlotPos = 4

SWEP.Spawnable = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawWeaponInfoBox = false

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl"
SWEP.ViewModelFOV = 55

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.IsLightsaber = true
SWEP.SaberDamage = 10
SWEP.MaxForce = 0
SWEP.RegenSpeed = 1
SWEP.CanKnockback = false

// We have NPC support, but it SUCKS
list.Add( "NPCUsableWeapons", { class = "lbf_single_lightsaber_base", title = SWEP.PrintName } )

/* --------------------------------------------------------- Helper functions --------------------------------------------------------- */
function SWEP:PlayWeaponSound( snd )
	if ( CLIENT ) then return end
	self.Owner:EmitSound( snd )
end

function SWEP:SelectTargets( num, dist )
	local t = {}
	if not dist then
		dist = 300
	end

	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * dist,
		filter = self.Owner
	} )

	local p = {}
	for id, ply in pairs( ents.GetAll() ) do
		if ( !ply:GetModel() || ply:GetModel() == "" || ply == self.Owner || ply:Health() < 1 ) then continue end
		if ( string.StartWith( ply:GetModel() || "", "models/gibs/" ) ) then continue end
		if ( string.find( ply:GetModel() || "", "chunk" ) ) then continue end
		if ( string.find( ply:GetModel() || "", "_shard" ) ) then continue end
		if ( string.find( ply:GetModel() || "", "_splinters" ) ) then continue end

		local tr = util.TraceLine( {
			start = self.Owner:GetShootPos(),
			endpos = (ply.GetShootPos && ply:GetShootPos() || ply:GetPos()),
			filter = self.Owner,
		} )

		if ( tr.Entity != ply && IsValid( tr.Entity ) || tr.Entity == game.GetWorld() ) then continue end

		local pos1 = self.Owner:GetPos() + self.Owner:GetAimVector() * dist
		local pos2 = ply:GetPos()
		local dot = self.Owner:GetAimVector():Dot( ( self.Owner:GetPos() - pos2 ):GetNormalized() )

		if ( pos1:Distance( pos2 ) <= dist && ply:EntIndex() > 0 && ply:GetModel() && ply:GetModel() != "" ) then
			table.insert( p, { ply = ply, dist = tr.HitPos:Distance( pos2 ), dot = dot, score = -dot + ( ( dist - pos1:Distance( pos2 ) ) / dist ) * 50 } )
		end
	end

	local d = {}
	for id, ply in SortedPairsByMemberValue( p, "dist" ) do
		table.insert( t, ply.ply )
		if ( #t >= num ) then return t end
	end

	return t
end

/* --------------------------------------------------------- Force Powers --------------------------------------------------------- */

function SWEP:OnRestore()
	self.Owner:SetNWFloat( "SWL_FeatherFall", 0 )
end

function SWEP:SetNextAttack( delay )
	self:SetNextPrimaryFire( CurTime() + delay )
	self:SetNextSecondaryFire( CurTime() + delay )
end


function SWEP:ForceJumpAnim()
	self.Owner.m_bJumping = true

	self.Owner.m_bFirstJumpFrame = true
	self.Owner.m_flJumpStartTime = CurTime()

	self.Owner:AnimRestartMainSequence()
end

SWEP.ForcePowers = {

 {
		name = "Meditation",
		icon = "M",
		description = "Relaxez-vous et recharger votre energie et votre santé .",
		think = function( self )
			if ( self.Owner:KeyDown( IN_ATTACK2 ) ) and !self:GetEnabled() and self.Owner:OnGround() then
				self._ForceMeditating = true
			else
				self._ForceMeditating = false
				self._NextMeditateHeal = 0
			end
			if self._ForceMeditating then
				if SERVER then
					self.Owner:SetNWBool("IsMeditating", true)
					if self._NextMeditateHeal < CurTime() then
						self.Owner:SetHealth( math.min( self.Owner:Health() + ( 200*0.05 ), 200 ) )
						self._NextMeditateHeal = CurTime() + 1
					end
					self.Owner:SetLocalVelocity(Vector(0, 0, 0))
					self.Owner:SetMoveType(MOVETYPE_NONE)
				end
			else
				if SERVER then
					self.Owner:SetNWBool("IsMeditating", false)
					self.Owner:SetMoveType(MOVETYPE_WALK)
				end
			end
			
		end
	},

}

/* --------------------------------------------------------- Initialize --------------------------------------------------------- */

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "BladeLength" )
	self:NetworkVar( "Float", 1, "MaxLength" )
	self:NetworkVar( "Float", 2, "BladeWidth" )
	self:NetworkVar( "Float", 3, "Force" )

	self:NetworkVar( "Bool", 0, "DarkInner" )
	self:NetworkVar( "Bool", 1, "Enabled" )
	self:NetworkVar( "Bool", 2, "WorksUnderwater" )
	self:NetworkVar( "Int", 0, "ForceType" )
	self:NetworkVar( "Int", 1, "IncorrectPlayerModel" )

	self:NetworkVar( "Vector", 0, "CrystalColor" )
	self:NetworkVar( "String", 0, "WorldModel" )
	self:NetworkVar( "String", 1, "OnSound" )
	self:NetworkVar( "String", 2, "OffSound" )

	if ( SERVER ) then
		self:SetBladeLength( 0 )
		self:SetBladeWidth( 2 )
		self:SetMaxLength( 42 )
		self:SetDarkInner( false )
		self:SetWorksUnderwater( true )
		self:SetEnabled( true )

		self:SetOnSound( "lightsaber/saber_on" .. math.random( 1, 4 ) .. ".wav" )
		self:SetOffSound( "lightsaber/saber_off" .. math.random( 1, 4 ) .. ".wav" )
		self:SetWorldModel( "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl" )
		self:SetCrystalColor( Vector( math.random( 0, 255 ), math.random( 0, 255 ), math.random( 0, 255 ) ) )
		self:SetForceType( 1 )
		self:SetForce( self.MaxForce )

		self:NetworkVarNotify( "Force", self.OnForceChanged )
	end
end

function SWEP:Initialize()
	self.IsLightsaber = true
	self.LoopSound = self.LoopSound || "lightsaber/saber_loop" .. math.random( 1, 8 ) .. ".wav"
	self.SwingSound = self.SwingSound || "lightsaber/saber_swing" .. math.random( 1, 2 ) .. ".wav"

	self:SetHoldType( self:GetTargetHoldType() )
	
	if ( self.Owner && self.Owner:IsNPC() && SERVER ) then // NPC Weapons
		self.Owner:Fire( "GagEnable" )

		if self.Owner:GetClass() == "npc_citizen" then
			self.Owner:Fire( "DisableWeaponPickup" )
		end

		self.Owner:SetKeyValue( "spawnflags", "256" )

		hook.Add( "Think", self, self.NPCThink )

		timer.Simple( 0.5, function()
			if ( !IsValid( self ) || !IsValid( self.Owner ) ) then return end
			self.Owner:SetCurrentWeaponProficiency( 4 )
			self.Owner:CapabilitiesAdd( CAP_FRIENDLY_DMG_IMMUNE )
			self.Owner:CapabilitiesRemove( CAP_WEAPON_MELEE_ATTACK1 )
			self.Owner:CapabilitiesRemove( CAP_INNATE_MELEE_ATTACK1 )
		end )
	end
end

/* --------------------------------------------------------- NPC Weapons --------------------------------------------------------- */

function SWEP:SetupWeaponHoldTypeForAI( t )
	if ( !self.Owner:IsNPC() ) then return end

	self.ActivityTranslateAI = {}

	self.ActivityTranslateAI[ ACT_IDLE ]					= ACT_IDLE
	self.ActivityTranslateAI[ ACT_IDLE_ANGRY ]				= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_RELAXED ]			= ACT_IDLE
	self.ActivityTranslateAI[ ACT_IDLE_STIMULATED ]			= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AGITATED ]			= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AIM_RELAXED ]		= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AIM_STIMULATED ]		= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AIM_AGITATED ]		= ACT_IDLE_ANGRY_MELEE

	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]			= ACT_RANGE_ATTACK_THROW
	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1_LOW ]		= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_MELEE_ATTACK1 ]			= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_MELEE_ATTACK2 ]			= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_SPECIAL_ATTACK1 ]			= ACT_RANGE_ATTACK_THROW

	self.ActivityTranslateAI[ ACT_RANGE_AIM_LOW ]			= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_COVER_LOW ]				= ACT_IDLE_ANGRY_MELEE

	self.ActivityTranslateAI[ ACT_WALK ]					= ACT_WALK
	self.ActivityTranslateAI[ ACT_WALK_RELAXED ]			= ACT_WALK
	self.ActivityTranslateAI[ ACT_WALK_STIMULATED ]			= ACT_WALK
	self.ActivityTranslateAI[ ACT_WALK_AGITATED ]			= ACT_WALK

	self.ActivityTranslateAI[ ACT_RUN_CROUCH ]				= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_CROUCH_AIM ]			= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN ]						= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_RELAXED ]			= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_STIMULATED ]		= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_AGITATED ]		= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM ]					= ACT_RUN
	self.ActivityTranslateAI[ ACT_SMALL_FLINCH ]			= ACT_RANGE_ATTACK_PISTOL
	self.ActivityTranslateAI[ ACT_BIG_FLINCH ]				= ACT_RANGE_ATTACK_PISTOL

	if ( self.Owner:GetClass() == "npc_metropolice" ) then

	self.ActivityTranslateAI[ ACT_IDLE ]					= ACT_IDLE
	self.ActivityTranslateAI[ ACT_IDLE_ANGRY ]				= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_RELAXED ]			= ACT_IDLE
	self.ActivityTranslateAI[ ACT_IDLE_STIMULATED ]			= ACT_IDLE
	self.ActivityTranslateAI[ ACT_IDLE_AGITATED ]			= ACT_IDLE_ANGRY_MELEE

	self.ActivityTranslateAI[ ACT_MP_RUN ]					= ACT_HL2MP_RUN_SUITCASE
	self.ActivityTranslateAI[ ACT_WALK ]					= ACT_WALK_SUITCASE
	self.ActivityTranslateAI[ ACT_MELEE_ATTACK1 ]			= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]			= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_SPECIAL_ATTACK1 ]			= ACT_RANGE_ATTACK_THROW
	self.ActivityTranslateAI[ ACT_SMALL_FLINCH ]			= ACT_RANGE_ATTACK_PISTOL
	self.ActivityTranslateAI[ ACT_BIG_FLINCH ]				= ACT_RANGE_ATTACK_PISTOL

	return end

	if ( self.Owner:GetClass() == "npc_combine_s2" ) then

	self.ActivityTranslateAI[ ACT_IDLE ]					= ACT_IDLE
	self.ActivityTranslateAI[ ACT_IDLE_ANGRY ]				= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_RELAXED ]			= ACT_IDLE
	self.ActivityTranslateAI[ ACT_IDLE_STIMULATED ]			= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AGITATED ]			= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AIM_RELAXED ]		= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AIM_STIMULATED ]		= ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_IDLE_AIM_AGITATED ]		= ACT_IDLE_ANGRY_MELEE

	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]			= ACT_RANGE_ATTACK_THROW
	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1_LOW ]		= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_MELEE_ATTACK1 ]			= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_MELEE_ATTACK2 ]			= ACT_MELEE_ATTACK_SWING
	self.ActivityTranslateAI[ ACT_SPECIAL_ATTACK1 ]			= ACT_RANGE_ATTACK_THROW


	self.ActivityTranslateAI[ ACT_RANGE_AIM_LOW ]			 = ACT_IDLE_ANGRY_MELEE
	self.ActivityTranslateAI[ ACT_COVER_LOW ]				= ACT_IDLE_ANGRY_MELEE

	self.ActivityTranslateAI[ ACT_WALK ]					= ACT_WALK
	self.ActivityTranslateAI[ ACT_WALK_RELAXED ]			= ACT_WALK
	self.ActivityTranslateAI[ ACT_WALK_STIMULATED ]			= ACT_WALK
	self.ActivityTranslateAI[ ACT_WALK_AGITATED ]			= ACT_WALK

	self.ActivityTranslateAI[ ACT_RUN ]						= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_RELAXED ]			= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_STIMULATED ]		= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_AGITATED ]		= ACT_RUN
	self.ActivityTranslateAI[ ACT_RUN_AIM ]					= ACT_RUN
	self.ActivityTranslateAI[ ACT_SMALL_FLINCH ]			= ACT_RANGE_ATTACK_PISTOL
	self.ActivityTranslateAI[ ACT_BIG_FLINCH ]				= ACT_RANGE_ATTACK_PISTOL

	return end

	if ( self.Owner:GetClass() == "npc_combine_s" ) then

	self.ActivityTranslateAI[ ACT_IDLE ]					= ACT_IDLE_UNARMED
	self.ActivityTranslateAI[ ACT_IDLE_ANGRY ]				= ACT_IDLE_SHOTGUN
	self.ActivityTranslateAI[ ACT_IDLE_RELAXED ]			= ACT_IDLE_SHOTGUN
	self.ActivityTranslateAI[ ACT_IDLE_STIMULATED ]			= ACT_IDLE_SHOTGUN
	self.ActivityTranslateAI[ ACT_IDLE_AGITATED ]			= ACT_IDLE_SHOTGUN
	self.ActivityTranslateAI[ ACT_IDLE_AIM_RELAXED ]		= ACT_IDLE_SHOTGUN
	self.ActivityTranslateAI[ ACT_IDLE_AIM_STIMULATED ]		= ACT_IDLE_SHOTGUN
	self.ActivityTranslateAI[ ACT_IDLE_AIM_AGITATED ]		= ACT_IDLE_SHOTGUN

	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]			= ACT_MELEE_ATTACK1
	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1_LOW ]		= ACT_MELEE_ATTACK1
	self.ActivityTranslateAI[ ACT_MELEE_ATTACK1 ]			= ACT_MELEE_ATTACK1
	self.ActivityTranslateAI[ ACT_MELEE_ATTACK2 ]			= ACT_MELEE_ATTACK1
	self.ActivityTranslateAI[ ACT_SPECIAL_ATTACK1 ]			= ACT_MELEE_ATTACK1

	self.ActivityTranslateAI[ ACT_RANGE_AIM_LOW ]			 = ACT_IDLE_SHOTGUN
	self.ActivityTranslateAI[ ACT_COVER_LOW ]				= ACT_IDLE_SHOTGUN

	self.ActivityTranslateAI[ ACT_WALK ]					= ACT_WALK_UNARMED
	self.ActivityTranslateAI[ ACT_WALK_RELAXED ]			= ACT_WALK_UNARMED
	self.ActivityTranslateAI[ ACT_WALK_STIMULATED ]			= ACT_WALK_UNARMED
	self.ActivityTranslateAI[ ACT_WALK_AGITATED ]			= ACT_WALK_UNARMED

	self.ActivityTranslateAI[ ACT_RUN ]						= ACT_RUN_AIM_SHOTGUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_RELAXED ]			= ACT_RUN_AIM_SHOTGUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_STIMULATED ]		= ACT_RUN_AIM_SHOTGUN
	self.ActivityTranslateAI[ ACT_RUN_AIM_AGITATED ]		= ACT_RUN_AIM_SHOTGUN
	self.ActivityTranslateAI[ ACT_RUN_AIM ]					= ACT_RUN_AIM_SHOTGUN

	return end
end

function SWEP:GetCapabilities()
	return bit.bor( CAP_WEAPON_MELEE_ATTACK1 )
end

function SWEP:NextFire()
	if ( !IsValid( self ) || !IsValid( self.Owner ) ) then return end
	if ( self.Owner:IsCurrentSchedule( SCHED_CHASE_ENEMY ) ) then return end
	self.NextFireTimer = true
	self:Chase_Enemy()

	timer.Simple( math.Rand( 0.6, 1 ), function()
		self.NextFireTimer = false
	end )
end

function SWEP:Chase_Enemy()
	if ( !IsValid( self ) || !IsValid( self.Owner ) ) then return end
	if ( self.Owner:GetEnemy():GetPos():Distance( self:GetPos() ) > 70 ) then
		self.Owner:SetSchedule( SCHED_CHASE_ENEMY )
	end

	if ( self.Owner:GetEnemy() == self.Owner ) then self.Owner:SetEnemy( NULL ) return end
	if ( !self.CooldownTimer && self.Owner:GetEnemy():GetPos():Distance( self:GetPos() ) <= 70 ) then
		self.Owner:SetSchedule( SCHED_MELEE_ATTACK1 )
		self:NPCShoot_Primary( ShootPos, ShootDir )
	end
end

function SWEP:NPCThink()
	if ( !IsValid( self.Owner ) || !IsValid( self ) || !self.Owner:IsNPC() ) then return end

	//self.Owner:RemoveAllDecals()
	self.Owner:ClearCondition( 13 )
	self.Owner:ClearCondition( 17 )
	self.Owner:ClearCondition( 18 )
	self.Owner:ClearCondition( 20 )
	self.Owner:ClearCondition( 48 )
	self.Owner:ClearCondition( 42 )
	self.Owner:ClearCondition( 45 )

	if ( !self.NextFireTimer && IsValid( self.Owner:GetEnemy() ) ) then
		self:NextFire()
	end

	self:Think()
end

function SWEP:NPCShoot_Primary( ShootPos, ShootDir )
	if ( !IsValid( self ) || !IsValid( self.Owner ) ) then return end
	if ( !self.Owner:GetEnemy() ) then return end

	self.CooldownTimer = true
	local seqtimer = 0.4
	if self.Owner:GetClass() == "npc_alyx" then
		seqtimer = 0.8
	end

	timer.Simple( seqtimer, function()
		if ( !IsValid( self ) || !IsValid( self.Owner ) ) then return end
		if ( self.Owner:IsCurrentSchedule( SCHED_MELEE_ATTACK1 ) ) then
			//self:PrimaryAttack()
		end
		self.CooldownTimer = false
	end )
end

/* --------------------------------------------------------- Attacks --------------------------------------------------------- */

function SWEP:PrimaryAttack()
	if ( !IsValid( self.Owner ) ) then return end

	self:SetNextAttack( 0.5 )
	if ( !self.Owner:IsNPC() && self:GetEnabled() ) then
		self.Owner:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
	end
end

function SWEP:SecondaryAttack()
	if ( !IsValid( self.Owner ) || !self.ForcePowers[ self:GetForceType() ] ) then return end
	if ( game.SinglePlayer() && SERVER ) then self:CallOnClient( "SecondaryAttack", "" ) end

	local ret = hook.Run( "CanUseLightsaberForcePower", self.Owner, self.ForcePowers[ self:GetForceType() ].name )
	if ( ret == false ) then return end

	if ( self.ForcePowers[ self:GetForceType() ].action ) then
		self.ForcePowers[ self:GetForceType() ].action( self )
		if ( GetConVarNumber( "rb655_lightsaber_infinite" ) != 0 ) then self:SetForce( self.MaxForce ) end
	end
end

function SWEP:Reload()
	if ( !self.Owner:KeyPressed( IN_RELOAD ) ) then return end
	if ( self.Owner:WaterLevel() > 2 && !self:GetWorksUnderwater() ) then return end

	if ( self:GetEnabled() ) then
		self:PlayWeaponSound( self:GetOffSound() )

		-- Fancy extinguish animations?
		if ( self.Owner:WaterLevel() > 1 ) then self:SetHoldType( "knife" ) end
		timer.Create( "rb655_ls_ht", 0.4, 1, function() if ( IsValid( self ) ) then self:SetHoldType( "normal" ) end end )

		if ( CLIENT ) then return end

		if ( self.SoundLoop ) then self.SoundLoop:Stop() self.SoundLoop = nil end
		if ( self.SoundSwing ) then self.SoundSwing:Stop() self.SoundSwing = nil end
		if ( self.SoundHit ) then self.SoundHit:Stop() self.SoundHit = nil end
	else
		self:PlayWeaponSound( self:GetOnSound() )
		self:SetHoldType( self:GetTargetHoldType() )
		timer.Destroy( "rb655_ls_ht" )

		if ( CLIENT ) then return end

		self.SoundLoop = CreateSound( self.Owner, Sound( self.LoopSound ) )
		if ( self.SoundLoop ) then self.SoundLoop:Play() end

		self.SoundSwing = CreateSound( self.Owner, Sound( self.SwingSound ) )
		if ( self.SoundSwing ) then self.SoundSwing:Play() self.SoundSwing:ChangeVolume( 0, 0 ) end

		self.SoundHit = CreateSound( self.Owner, Sound( "lightsaber/saber_hit.wav" ) )
		if ( self.SoundHit ) then self.SoundHit:Play() self.SoundHit:ChangeVolume( 0, 0 ) end
	end

	self:SetEnabled( !self:GetEnabled() )
end

/* --------------------------------------------------------- Hold Types --------------------------------------------------------- */

function SWEP:GetTargetHoldType()
	//print( self:LookupAttachment( "blade2" ), self:GetAttachment( 1 ), self:GetModel() )
	//PrintTable( self:GetAttachments() )

	//if ( !self:GetEnabled() ) then return "normal" end
	//if ( self:GetWorldModel() == "models/sgg/starwars/weapons/w_maul_saber_hilt.mdl" ) then return "knife" end
	if ( self:GetWorldModel() == "models/weapons/starwars/w_maul_saber_staff_hilt.mdl" ) then return "knife" end
	if ( self:LookupAttachment( "blade2" ) && self:LookupAttachment( "blade2" ) > 0 ) then return "knife" end

	return "melee2"
end

/* --------------------------------------------------------- Drop / Deploy / Holster --------------------------------------------------------- */

function SWEP:OnDrop()
	if ( CLIENT ) then rb655_SaberClean( self:EntIndex() ) return end

	if ( self.SoundLoop ) then self.SoundLoop:Stop() self.SoundLoop = nil end
	if ( self.SoundSwing ) then self.SoundSwing:Stop() self.SoundSwing = nil end
	if ( self.SoundHit ) then self.SoundHit:Stop() self.SoundHit = nil end
end

function SWEP:OnRemove()
	if ( CLIENT ) then rb655_SaberClean( self:EntIndex() ) return end

	if ( self.SoundLoop ) then self.SoundLoop:Stop() self.SoundLoop = nil end
	if ( self.SoundSwing ) then self.SoundSwing:Stop() self.SoundSwing = nil end
	if ( self.SoundHit ) then self.SoundHit:Stop() self.SoundHit = nil end
end

function SWEP:Deploy()

	local ply = self.Owner

	self:SetMaxLength( 34 )
	self:SetCrystalColor( Vector( 255 , 191 , 0 ) )
	self:SetDarkInner( "1" == "1" )
	self:SetWorldModel( "models/training/training.mdl" )
	self:SetBladeWidth( 2 )

	self.LoopSound = ply:GetInfo( "rb655_lightsaber_humsound" )
	self.SwingSound = ply:GetInfo( "rb655_lightsaber_swingsound" )
	self:SetOnSound( ply:GetInfo( "rb655_lightsaber_onsound" ) )
	self:SetOffSound( ply:GetInfo( "rb655_lightsaber_offsound" ) )
	
	self:SetForceType( 1 )
	
	if ( self:GetEnabled() ) then self:PlayWeaponSound( self:GetOnSound() ) end

	if ( CLIENT ) then return end

	if ( ply:FlashlightIsOn() ) then ply:Flashlight( false ) end

	self:SetBladeLength( 0 )

	if ( self:GetEnabled() ) then
		self.SoundLoop = CreateSound( ply, Sound( self.LoopSound ) )
		if ( self.SoundLoop ) then self.SoundLoop:Play() end

		self.SoundSwing = CreateSound( ply, Sound( self.SwingSound ) )
		if ( self.SoundSwing ) then self.SoundSwing:Play() self.SoundSwing:ChangeVolume( 0, 0 ) end

		self.SoundHit = CreateSound( ply, Sound( "lightsaber/saber_hit.wav" ) )
		if ( self.SoundHit ) then self.SoundHit:Play() self.SoundHit:ChangeVolume( 0, 0 ) end
	end

	if ( !self:GetEnabled() ) then
		self:SetHoldType( "normal" )
	else
		self:SetHoldType( self:GetTargetHoldType() )
	end

	return true
end

function SWEP:Holster()
	if ( self:GetEnabled() ) then self:PlayWeaponSound( self:GetOffSound() ) end

	if ( CLIENT ) then rb655_SaberClean( self:EntIndex() ) return true end

	if ( self.SoundLoop ) then self.SoundLoop:Stop() self.SoundLoop = nil end
	if ( self.SoundSwing ) then self.SoundSwing:Stop() self.SoundSwing = nil end
	if ( self.SoundHit ) then self.SoundHit:Stop() self.SoundHit = nil end

	return true
end

/* --------------------------------------------------------- Think --------------------------------------------------------- */

function SWEP:GetSaberPosAng( num, side )
	num = num or 1

	if ( SERVER ) then self:SetIncorrectPlayerModel( 0 ) end

	if ( IsValid( self.Owner ) ) then
		local bone = self.Owner:LookupBone( "ValveBiped.Bip01_R_Hand" )
		local attachment = self:LookupAttachment( "blade" .. num )
		if ( side ) then
			attachment = self:LookupAttachment( "quillon" .. num )
		end

		if ( !bone && SERVER ) then
			self:SetIncorrectPlayerModel( 1 )
		end

		if ( attachment && attachment > 0 ) then
			local PosAng = self:GetAttachment( attachment )

			if ( !bone && SERVER ) then
				PosAng.Pos = PosAng.Pos + Vector( 0, 0, 36 )
				if ( SERVER && IsValid( self.Owner ) && self.Owner:IsPlayer() && self.Owner:Crouching() ) then PosAng.Pos = PosAng.Pos - Vector( 0, 0, 18 ) end
				PosAng.Ang.p = 0
			end

			return PosAng.Pos, PosAng.Ang:Forward()
		end

		if ( bone ) then
			local pos, ang = self.Owner:GetBonePosition( bone )
			if ( pos == self.Owner:GetPos() ) then
				local matrix = self.Owner:GetBoneMatrix( bone )
				if ( matrix ) then
					pos = matrix:GetTranslation()
					ang = matrix:GetAngles()
				else
					self:SetIncorrectPlayerModel( 1 )
				end
			end

			ang:RotateAroundAxis( ang:Forward(), 180 )
			ang:RotateAroundAxis( ang:Up(), 30 )
			ang:RotateAroundAxis( ang:Forward(), -5.7 )
			ang:RotateAroundAxis( ang:Right(), 92 )

			pos = pos + ang:Up() * -3.3 + ang:Right() * 0.8 + ang:Forward() * 5.6

			return pos, ang:Forward()
		end

		self:SetIncorrectPlayerModel( 1 )
	else
		self:SetIncorrectPlayerModel( 2 )
	end

	if ( self:GetIncorrectPlayerModel() == 0 ) then self:SetIncorrectPlayerModel( 1 ) end

	local defAng = self:GetAngles()
	defAng.p = 0

	local defPos = self:GetPos() + defAng:Right() * 0.6 - defAng:Up() * 0.2 + defAng:Forward() * 0.8
	if ( SERVER ) then defPos = defPos + Vector( 0, 0, 36 ) end
	if ( SERVER && IsValid( self.Owner ) && self.Owner:Crouching() ) then defPos = defPos - Vector( 0, 0, 18 ) end

	return defPos, -defAng:Forward()
end

function SWEP:OnForceChanged( name, old, new )
	if ( old > new ) then
		self.NextForce = CurTime() + 2
	end
end
	
function SWEP:Think()
	self.WorldModel = self:GetWorldModel()
	self:SetModel( self:GetWorldModel() )
	
	if ( self.ForcePowers[ self:GetForceType() ]&& self.ForcePowers[ self:GetForceType() ].think && !self.Owner:KeyDown( IN_USE ) ) then
		self.ForcePowers[ self:GetForceType() ].think( self )
	end

	if ( CLIENT ) then return true end

	if ( ( self.NextForce || 0 ) < CurTime() ) then
		self:SetForce( math.min( self:GetForce() + ( 1.5*self.RegenSpeed ), self.MaxForce ) )
	end

	if ( !self:GetEnabled() && self:GetBladeLength() != 0 ) then
		self:SetBladeLength( math.Approach( self:GetBladeLength(), 0, 2 ) )
	elseif ( self:GetEnabled() && self:GetBladeLength() != self:GetMaxLength() ) then
		self:SetBladeLength( math.Approach( self:GetBladeLength(), self:GetMaxLength(), 8 ) )
	end

	if ( self:GetBladeLength() <= 0 ) then return end

	// ------------------------------------------------- DAMAGE ------------------------------------------------- //

	-- Up
	local isTrace1Hit = false
	local pos, ang = self:GetSaberPosAng()
	local trace = util.TraceHull( {
		start = pos,
		endpos = pos + ang * self:GetBladeLength(),
		filter = { self, self.Owner },
		mins = Vector( -2, -2, -2 ),
		maxs = Vector( 2, 2, 2 )
	} )
	local traceBack = util.TraceHull( {
		start = pos + ang * self:GetBladeLength(),
		endpos = pos,
		filter = { self, self.Owner },
		mins = Vector( -2, -2, -2 ),
		maxs = Vector( 2, 2, 2 )
	} )

	self.LastEndPos = trace.endpos
	if ( SERVER ) then debugoverlay.Line( trace.StartPos, trace.HitPos, .1, Color( 255, 0, 0 ), false ) end

	if ( trace.HitSky || trace.StartSolid ) then trace.Hit = false end
	if ( traceBack.HitSky || traceBack.StartSolid ) then traceBack.Hit = false end

	self:DrawHitEffects( trace, traceBack )
	isTrace1Hit = trace.Hit || traceBack.Hit

	-- Don't deal the damage twice to the same entity
	if ( traceBack.Entity == trace.Entity && IsValid( trace.Entity ) ) then traceBack.Hit = false end

	local ent = trace.Hit and IsValid(trace.Entity) and trace.Entity
	if not IsValid(ent) and traceBack.Hit then
		ent = IsValid(traceBack.Entity) and traceBack.Entity
	end
	
	if ( trace.Hit ) then rb655_LS_DoDamage( trace, self ) end
	if ( traceBack.Hit ) then rb655_LS_DoDamage( traceBack, self ) end

	if self.LastEndPos then
		local traceTo = util.TraceHull({
			start = pos + ang * self:GetBladeLength(),
			endpos = self.LastEndPos,
			filter = { self, self.Owner },
			mins = Vector( -2, -2, -2 ),
			maxs = Vector( 2, 2, 2 )
		})

		if ( traceTo.Hit ) and (IsValid(traceTo.Entity) and (not IsValid(ent) or traceTo.Entity != ent)) then 
			rb655_LS_DoDamage( traceTo, self ) 
			ent = traceTo.Entity 
		end

		util.TraceHull({
			start = pos,
			endpos = self.LastEndPos,
			filter = { self, self.Owner },
			mins = Vector( -2, -2, -2 ),
			maxs = Vector( 2, 2, 2 ),
			output = traceTo
		})

		if ( traceTo.Hit ) and (IsValid(traceTo.Entity) and (not IsValid(ent) or traceTo.Entity != ent)) then rb655_LS_DoDamage( traceTo, self ) end
	end

	-- Down
	local isTrace2Hit = false
	if ( self:LookupAttachment( "blade2" ) > 0 ) then -- TEST ME
		local pos2, dir2 = self:GetSaberPosAng( 2 )
		local trace2 = util.TraceLine( {
			start = pos2,
			endpos = pos2 + dir2 * self:GetBladeLength(),
			filter = { self, self.Owner },
			//mins = Vector( -1, -1, -1 ) * self:GetBladeWidth() / 8,
			//maxs = Vector( 1, 1, 1 ) * self:GetBladeWidth() / 8
		} )
		local traceBack2 = util.TraceLine( {
			start = pos2 + dir2 * self:GetBladeLength(),
			endpos = pos2,
			filter = { self, self.Owner },
			//mins = Vector( -1, -1, -1 ) * self:GetBladeWidth() / 8,
			//maxs = Vector( 1, 1, 1 ) * self:GetBladeWidth() / 8
		} )

		if ( trace2.HitSky || trace2.StartSolid ) then trace2.Hit = false end
		if ( traceBack2.HitSky || traceBack2.StartSolid ) then traceBack2.Hit = false end

		self:DrawHitEffects( trace2, traceBack2 )
		isTrace2Hit = trace2.Hit || traceBack2.Hit

		if ( traceBack2.Entity == trace2.Entity && IsValid( trace2.Entity ) ) then traceBack2.Hit = false end

		if ( trace2.Hit ) then rb655_LS_DoDamage( trace2, self ) end
		if ( traceBack2.Hit ) then rb655_LS_DoDamage( traceBack2, self ) end

	end

	if ( ( isTrace1Hit || isTrace2Hit ) && self.SoundHit ) then
		self.SoundHit:ChangeVolume( math.Rand( 0.1, 0.5 ), 0 )
	elseif ( self.SoundHit ) then
		self.SoundHit:ChangeVolume( 0, 0 )
	end

	// ------------------------------------------------- SOUNDS ------------------------------------------------- //

	if ( self.SoundSwing ) then

		if ( self.LastAng != ang ) then
			self.LastAng = self.LastAng || ang
			self.SoundSwing:ChangeVolume( math.Clamp( ang:Distance( self.LastAng ) / 2, 0, 1 ), 0 )
		end

		self.LastAng = ang
	end

	if ( self.SoundLoop ) then
		pos = pos + ang * self:GetBladeLength()

		if ( self.LastPos != pos ) then
			self.LastPos = self.LastPos || pos
			self.SoundLoop:ChangeVolume( 0.1 + math.Clamp( pos:Distance( self.LastPos ) / 128, 0, 0.2 ), 0 )
		end
		self.LastPos = pos
	end
end

function SWEP:DrawHitEffects( trace, traceBack )
	if ( self:GetBladeLength() <= 0 ) then return end

	if ( trace.Hit ) then
		rb655_DrawHit( trace.HitPos, trace.HitNormal )
	end

	if ( traceBack && traceBack.Hit ) then
		rb655_DrawHit( traceBack.HitPos, traceBack.HitNormal )
	end
end

/* ------------------------------------------------------------- NPC STUFF ----------------------------------------------------------------- */

local index = ACT_HL2MP_IDLE_KNIFE
local KnifeHoldType = {}
KnifeHoldType[ ACT_MP_STAND_IDLE ] = index
KnifeHoldType[ ACT_MP_WALK ] = index + 1
KnifeHoldType[ ACT_MP_RUN ] = index + 2
KnifeHoldType[ ACT_MP_CROUCH_IDLE ] = index + 3
KnifeHoldType[ ACT_MP_CROUCHWALK ] = index + 4
KnifeHoldType[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = index + 5
KnifeHoldType[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = index + 5
KnifeHoldType[ ACT_MP_RELOAD_STAND ] = index + 6
KnifeHoldType[ ACT_MP_RELOAD_CROUCH ] = index + 6
KnifeHoldType[ ACT_MP_JUMP ] = index + 7
KnifeHoldType[ ACT_RANGE_ATTACK1 ] = index + 8
KnifeHoldType[ ACT_MP_SWIM ] = index + 9

function SWEP:TranslateActivity( act )

	if ( self.Owner:IsNPC() ) then
		if ( self.ActivityTranslateAI[ act ] ) then return self.ActivityTranslateAI[ act ] end
		return -1
	end

	if ( self.Owner:Crouching() ) then
		local tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + Vector( 0, 0, 20 ),
			mins = self.Owner:OBBMins(),
			maxs = self.Owner:OBBMaxs(),
			filter = self.Owner
		} )

		if ( self:GetEnabled() && tr.Hit && act == ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ) then return ACT_HL2MP_IDLE_KNIFE + 5 end

		if ( ( !self:GetEnabled() && self:GetHoldType() == "normal" ) && self.Owner:Crouching() && act == ACT_MP_CROUCH_IDLE ) then return ACT_HL2MP_IDLE_KNIFE + 3 end
		if ( ( ( !self:GetEnabled() && self:GetHoldType() == "normal" ) || ( self:GetEnabled() && tr.Hit ) ) && act == ACT_MP_CROUCH_IDLE ) then return ACT_HL2MP_IDLE_KNIFE + 3 end
		if ( ( ( !self:GetEnabled() && self:GetHoldType() == "normal" ) || ( self:GetEnabled() && tr.Hit ) ) && act == ACT_MP_CROUCHWALK ) then return ACT_HL2MP_IDLE_KNIFE + 4 end

	end

	if ( self.Owner:WaterLevel() > 1 && self:GetEnabled() ) then
		return KnifeHoldType[ act ]
	end

	if ( self.ActivityTranslate[ act ] != nil ) then return self.ActivityTranslate[ act ]end
	return -1
end

/* ------------------------------------------------------------- Clientside stuff ----------------------------------------------------------------- */

if ( SERVER ) then return end

killicon.Add( "lbf_lightsaber_base", "lightsaber/lightsaber_killicon", color_white )

local WepSelectIcon = Material( "lightsaber/selection.png" )
local Size = 96

function SWEP:DrawWeaponSelection( x, y, w, h, a )
	surface.SetDrawColor( 255, 255, 255, a )
	surface.SetMaterial( WepSelectIcon )

	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	surface.DrawTexturedRect( x + ( ( w - Size ) / 2 ), y + ( ( h - Size ) / 2.5 ), Size, Size )

	render.PopFilterMag()
	render.PopFilterMin()
end

function SWEP:DrawWorldModel()
	self:DrawWorldModelTranslucent()
end

function SWEP:DrawWorldModelTranslucent()
	self.WorldModel = self:GetWorldModel()
	self:SetModel( self:GetWorldModel() )
	
	self:DrawModel()
	if ( !IsValid( self:GetOwner() ) or halo.RenderedEntity() == self ) then return end

	if self.Owner:GetNWFloat( "CloakTime", 0 ) >= CurTime() then return end
	
	local clr = self:GetCrystalColor()
	clr = Color( clr.x, clr.y, clr.z )

	local bladesFound = false -- true if the model is OLD and does not have blade attachments
	local blades = 0
	for id, t in pairs( self:GetAttachments() ) do
		if ( !string.match( t.name, "blade(%d+)" ) && !string.match( t.name, "quillon(%d+)" ) ) then continue end

		local bladeNum = string.match( t.name, "blade(%d+)" )
		local quillonNum = string.match( t.name, "quillon(%d+)" )

		if ( bladeNum && self:LookupAttachment( "blade" .. bladeNum ) > 0 ) then
			blades = blades + 1
			local pos, dir = self:GetSaberPosAng( bladeNum )
			rb655_RenderBlade( pos, dir, self:GetBladeLength(), self:GetMaxLength(), self:GetBladeWidth(), clr, self:GetDarkInner(), self:EntIndex(), self:GetOwner():WaterLevel() > 2, false, blades )
			bladesFound = true
		end

		if ( quillonNum && self:LookupAttachment( "quillon" .. quillonNum ) > 0 ) then
			blades = blades + 1
			local pos, dir = self:GetSaberPosAng( quillonNum, true )
			rb655_RenderBlade( pos, dir, self:GetBladeLength(), self:GetMaxLength(), self:GetBladeWidth(), clr, self:GetDarkInner(), self:EntIndex(), self:GetOwner():WaterLevel() > 2, true, blades )
		end

	end

	if ( !bladesFound ) then
		local pos, dir = self:GetSaberPosAng()
		rb655_RenderBlade( pos, dir, self:GetBladeLength(), self:GetMaxLength(), self:GetBladeWidth(), clr, self:GetDarkInner(), self:EntIndex(), self:GetOwner():WaterLevel() > 2 )
	end
end

/* --------------------------------------------------------- 3rd Person Camera --------------------------------------------------------- */

/*
hook.Add( "ShouldDrawLocalPlayer", "rb655_lightsaber_weapon_draw", function()
	if ( IsValid( LocalPlayer() ) && LocalPlayer().GetActiveWeapon && IsValid( LocalPlayer():GetActiveWeapon() ) && LocalPlayer():GetActiveWeapon():GetClass() == "weapon_lightsaber" && !LocalPlayer():InVehicle() && LocalPlayer():Alive() && LocalPlayer():GetViewEntity() == LocalPlayer() ) then return true end
end )

function SWEP:CalcView( ply, pos, ang, fov )
	if ( !IsValid( ply ) || !ply:Alive() || ply:InVehicle() || ply:GetViewEntity() != ply ) then return end

	local trace = util.TraceHull( {
		start = pos,
		endpos = pos - ang:Forward() * 100,
		filter = { ply:GetActiveWeapon(), ply },
		mins = Vector( -4, -4, -4 ),
		maxs = Vector( 4, 4, 4 ),
	} )

	if ( trace.Hit ) then pos = trace.HitPos else pos = pos - ang:Forward() * 100 end

	return pos, ang, fov
end*/

/* --------------------------------------------------------- HUD --------------------------------------------------------- */

surface.CreateFont( "SelectedForceType", {
	font	= "Roboto Cn",
	size	= ScreenScale( 16 ),
	weight	= 600
} )

surface.CreateFont( "SelectedForceHUD", {
	font	= "Roboto Cn",
	size	= ScreenScale( 6 )
} )

SWEP.ForceSelectEnabled = false

local rb655_lightsaber_hud_blur = CreateClientConVar( "rb655_lightsaber_hud_blur", "0" )

local grad = Material( "gui/gradient_up" )
local matBlurScreen = Material( "pp/blurscreen" )
matBlurScreen:SetFloat( "$blur", 3 )
matBlurScreen:Recompute()
local function DrawHUDBox( x, y, w, h, b )

	x = math.floor( x )
	y = math.floor( y )
	w = math.floor( w )
	h = math.floor( h )

	surface.SetMaterial( matBlurScreen )
	surface.SetDrawColor( 255, 255, 255, 255 )

	if ( rb655_lightsaber_hud_blur:GetBool() ) then
		render.SetScissorRect( x, y, w + x, h + y, true )
			for i = 0.33, 1, 0.33 do
				matBlurScreen:SetFloat( "$blur", 5 * i )
				matBlurScreen:Recompute()
				render.UpdateScreenEffectTexture()
				surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
			end
		render.SetScissorRect( 0, 0, 0, 0, false )
	else
		draw.NoTexture()
		surface.SetDrawColor( Color( 0, 0, 0, 128 ) )
		surface.DrawTexturedRect( x, y, w, h )
	end

	surface.SetDrawColor( Color( 0, 0, 0, 128 ) )
	surface.DrawRect( x, y, w, h )

	if ( b ) then
		surface.SetMaterial( grad )
		surface.SetDrawColor( Color( 0, 128, 255, 4 ) )
		surface.DrawTexturedRect( x, y, w, h )
	end

end

local isCalcViewFuckedUp = false
function SWEP:ViewModelDrawn()
	isCalcViewFuckedUp = true -- Clever girl!
end

local isCalcViewFuckedUp2 = false

local boneInfo = {}
net.Receive( "hax", function()
boneInfo = net.ReadTable()
end )


local ForceBar = 100
function SWEP:DrawHUD()
	if ( !IsValid( self.Owner ) || self.Owner:GetViewEntity() != self.Owner || self.Owner:InVehicle() ) then return end

	-----------------------------------

	local icon = 52
	local gap = 5

	local bar = 4
	local bar2 = 16

	if ( self.ForceSelectEnabled ) then
		icon = 128
		bar = 8
		bar2 = 24
	end

	----------------------------------- Force Bar -----------------------------------

	ForceBar = math.min( 100, Lerp( 0.1, ForceBar, math.floor( self:GetForce() ) ) )

	local w = #self.ForcePowers * icon + ( #self.ForcePowers - 1 ) * gap
	local h = bar2
	local x = math.floor( ScrW() / 2 - w / 2 )
	local y = ScrH() - gap - bar2

	DrawHUDBox( x, y, w, h )

	local barW = math.ceil( w * ( ForceBar / 100 ) )
	if ( self:GetForce() <= 1 && barW <= 1 ) then barW = 0 end
	draw.RoundedBox( 0, x, y, barW, h, Color( 0, 128, 255, 255 ) )

	draw.SimpleText( math.floor( self:GetForce() ) .. "%", "SelectedForceHUD", x + w / 2, y + h / 2, Color( 255, 255, 255 ), 1, 1 )
	
	----------------------------------- Force Icons -----------------------------------

	local y = y - icon - gap
	local h = icon

	for id, t in pairs( self.ForcePowers ) do
		local x = x + ( id - 1 ) * ( h + gap )
		local x2 = math.floor( x + icon / 2 )

		local image = lBf.ForceIcons[ self.ForcePowers[ id ].name ]
		DrawHUDBox( x, y, h, h, self:GetForceType() == id )
		if image then
			surface.SetMaterial( image )
			   surface.SetDrawColor( Color(255, 255, 255, 255) );
			surface.DrawTexturedRect( x, y, h, h )
		end
		local time = self:GetNWFloat( t.name, 0 )
		if time >= CurTime() then
			local rat = math.Clamp( time - CurTime(), 0, 1 ) 
			surface.SetDrawColor( 255, 0, 0, 125 )
			surface.DrawRect( x, y + h*( 1 - rat ), h, h*rat )
		end
		draw.SimpleText( self.ForcePowers[ id ].icon || "", "SelectedForceType", x2, math.floor( y + icon / 2 ), Color( 255, 255, 255 ), 1, 1 )
		if ( self.ForceSelectEnabled ) then
			draw.SimpleText( ( input.LookupBinding( "slot" .. id ) || "<NOT BOUND>" ):upper(), "SelectedForceHUD", x + gap, y + gap, Color( 255, 255, 255 ) )
		end
		if ( self:GetForceType() == id ) then
			local y = y + ( icon - bar )
			surface.SetDrawColor( 0, 128, 255, 255 )
			draw.NoTexture()
			surface.DrawPoly( {
				{ x = x2 - bar, y = y },
				{ x = x2, y = y - bar },
				{ x = x2 + bar, y = y }
			} )
			draw.RoundedBox( 0, x, y, h, bar, Color( 0, 128, 255, 255 ) )
		end
	end

	----------------------------------- Force Description -----------------------------------

	if ( self.ForceSelectEnabled ) then

		surface.SetFont( "SelectedForceHUD" )
		local tW, tH = surface.GetTextSize( self.ForcePowers[ self:GetForceType() ].description || "" )

		/*local x = x + w + gap
		local y = y*/
		local x = ScrW() / 2 + gap// - tW / 2
		local y = y - tH - gap * 3

		DrawHUDBox( x, y, tW + gap * 2, tH + gap * 2 )

		for id, txt in pairs( string.Explode( "\n", self.ForcePowers[ self:GetForceType() ].description || "" ) ) do
			draw.SimpleText( txt, "SelectedForceHUD", x + gap, y + ( id - 1 ) * ScreenScale( 6 ) + gap, Color( 255, 255, 255 ) )
		end

	end

	----------------------------------- Force Label -----------------------------------

	if ( !self.ForceSelectEnabled ) then
		surface.SetFont( "SelectedForceHUD" )
		local txt = "Press " .. ( input.LookupBinding( "impulse 100" ) || "<NOT BOUND>" ):upper() .. " to toggle Force selection"
		local tW, tH = surface.GetTextSize( txt )

		local x = x + w / 2
		local y = y - tH - gap

		DrawHUDBox( x - tW / 2 - 5, y, tW + 10, tH )
		draw.SimpleText( txt, "SelectedForceHUD", x, y, Color( 255, 255, 255 ), 1 )
	end

	if ( self.ForceSelectEnabled ) then
		surface.SetFont( "SelectedForceType" )
		local txt = self.ForcePowers[ self:GetForceType() ].name or ""
		local tW2, tH2 = surface.GetTextSize( txt )

		local x = x + w / 2 - tW2 - gap * 2//+ w / 2
		local y = y + gap - tH2 - gap * 2

		DrawHUDBox( x, y, tW2 + 10, tH2 )
		draw.SimpleText( txt, "SelectedForceType", x + gap, y, Color( 255, 255, 255 ) )
	end

	----------------------------------- Force Target -----------------------------------

	local isTarget = self.ForcePowers[ self:GetForceType() ].target
	local DistTarget = self.ForcePowers[ self:GetForceType() ].distance or 300

	if ( isTarget ) then
		for id, ent in pairs( self:SelectTargets( isTarget, DistTarget ) ) do
			if ( !IsValid( ent ) ) then continue end
			local maxs = ent:OBBMaxs()
			local p = ent:GetPos()
			p.z = p.z + maxs.z

			local pos = p:ToScreen()
			local x, y = pos.x, pos.y
			local size = 16

			surface.SetDrawColor( 255, 0, 0, 255 )
			draw.NoTexture()
			surface.DrawPoly( {
				{ x = x - size, y = y - size },
				{ x = x + size, y = y - size },
				{ x = x, y = y }
			} )
		end
	end

end

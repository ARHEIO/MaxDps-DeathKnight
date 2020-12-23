local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
	return
end

local DeathKnight = addonTable.DeathKnight;
local MaxDps = MaxDps;
local frameData = MaxDps.FrameData;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local RunicPower = Enum.PowerType.RunicPower;

local FSCost = 25;

-- Actions
local _RemorselessWinter  = 196770;
local _DeathAndDecay	  = 0000000000000;
local _SacrificialPact    = 327574;
local _RaiseDead          = 46585;
local _HowlingBlast       = 49184;
local _Obliterate         = 49020;
local _EmpowerRuneWeapon  = 47568;
local _HornOfWinter       = 0000000000000;
local _ChainsOfIce        = 45524;
local _PillarOfFrost      = 51271;
local _FrostStrike        = 49143;
local _BreathOfSindragosa = 152279;
local _Frostscythe        = 0000000000000;
local _FrostwyrmsFury     = 279302;
local _GlacialAdvance     = 0000000000000;
local _MasteryFrozenHeart = 77514;

-- Covenant
local _DeathsDue          = 324128;

-- Passives
local _IcyTalonsTalent      = 194878;
local _ColdHeartTalent      = 281208;
local _GatheringStormTalent = 194912;
local _FrozenPulse          = 194909;
local _ObliterationTalent   = 281238;

-- Buffs
local _Rime               = 59052;
local _KillingMachine     = 51124;
local _IcyTalons          = 0000000000000;
local _ColdHeart          = 281209;

-- Debuffs
local _FrostFever         = 55095;
local _Razorice           = 51714;

-- Core function
-- function MaxDps:PrepareFrameData()
-- 	if not self.FrameData then
-- 		self.FrameData = {
-- 			cooldown  = self.PlayerCooldowns,
-- 			activeDot = self.ActiveDots
-- 		};
-- 	end

-- 	self.FrameData.timeShift, self.FrameData.currentSpell, self.FrameData.gcdRemains = MaxDps:EndCast();
-- 	self.FrameData.gcd = self:GlobalCooldown();
-- 	self.FrameData.buff, self.FrameData.debuff = MaxDps:CollectAuras();
-- 	self.FrameData.talents = self.PlayerTalents;
-- 	self.FrameData.azerite = self.AzeriteTraits;
-- 	self.FrameData.essences = self.AzeriteEssences;
-- 	self.FrameData.covenant = self.CovenantInfo;
-- 	self.FrameData.spellHistory = self.spellHistory;
-- 	self.FrameData.timeToDie = self:GetTimeToDie();
-- end

function HasTalent(name)
	local frameData = MaxDps.FrameData;
	return frameData.talents[name] == 1;
end

-- Buff / Debuff Interface:
-- output[id] = {
-- 	name           = name,
-- 	up             = remains > 0,
-- 	upMath		   = remains > 0 and 1 or 0,
-- 	count          = count, -- number of stacks
-- 	expirationTime = expirationTime,
-- 	remains        = remains,
-- 	duration       = duration,
-- 	refreshable    = remains < 0.3 * duration,
-- };
function PlayerBuff(name)
	local frameData = MaxDps.FrameData;
	local buff = frameData.buff[name];
	return buff
end

function TargetHasDebuff(name)
	local frameData = MaxDps.FrameData;
	local debuff = frameData.debuff[name];
	return debuff.up, debuff.remains;
end

-- return {
-- 	duration        = GetSpellBaseCooldown(spellId) / 1000,
-- 	ready           = remains <= 0,
-- 	remains         = remains,
-- 	fullRecharge    = fullRecharge,
-- 	partialRecharge = partialRecharge,
-- 	charges         = charges,
-- 	maxCharges      = maxCharges
-- };
function SpellAvailable(name)
	local frameData = MaxDps.FrameData;
	local cd = frameData.cooldown[name];
	return cd.ready, cd.remains;
end

function canCastSpell(name)
	local ready, cd = SpellAvailable(name)
	return ready;
end

function spellCooldown(name)
	local ready, cd = SpellAvailable(name)
	return cd;
end

function DeathKnight:FrostAoe()
	local runic = UnitPower('player', RunicPower);
	local frameData = MaxDps.FrameData;
	local runes, runeCd = DeathKnight:Runes(frameData.timeShift);
	local runic = UnitPower('player', RunicPower);
	
	local remorselessWinterReady, remorselessWinterCD = SpellAvailable(_RemorselessWinter);

	-- actions.aoe=remorseless_winter
	if remorselessWinterReady then return _RemorselessWinter end

	-- actions.aoe+=/glacial_advance,if=talent.frostscythe
	if HasTalent(_Frostscythe) and HasTalent(_GlacialAdvance) then
		if canCastSpell(_GlacialAdvance) then return _GlacialAdvance end
	end

	-- actions.aoe+=/frost_strike,target_if=RAZORICE_CALC,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm
	if HasTalent(_GatheringStorm) and remorselessWinterCD <= 2 * frameData.gcd then
		if runic >= FSCost then return _FrostStrike end
	end

	-- actions.aoe+=/howling_blast,if=buff.rime.up
	if PlayerBuff(_Rime).up then
		if runes >= 1 then return _HowlingBlast end
	end

	-- actions.aoe+=/frostscythe,if=buff.killing_machine.react&(!death_and_decay.ticking&covenant.night_fae|!covenant.night_fae)
	-- actions.aoe+=/glacial_advance,if=runic_power.deficit<(15+talent.runic_attenuation*3)
	if runic > 82 then
		if HasTalent(_GlacialAdvance) and canCastSpell(_GlacialAdvance) then return _GlacialAdvance end
	end

	-- actions.aoe+=/frost_strike,target_if=RAZORICE_CALC,if=runic_power.deficit<(15+talent.runic_attenuation*3)
	if runic > 82 then return _FrostStrike end

	-- actions.aoe+=/remorseless_winter
	if remorselessWinterReady and runes >= 1 then return _RemorselessWinter end

	-- actions.aoe+=/frostscythe,if=!death_and_decay.ticking&covenant.night_fae|!covenant.night_fae
	-- actions.aoe+=/obliterate,target_if=RAZORICE_CALC,if=runic_power.deficit>(25+talent.runic_attenuation*3)
	if runic < 72 and runes >= 2 then return _Obliterate end
	
	-- actions.aoe+=/glacial_advance
	if HasTalent(_GlacialAdvance) and canCastSpell(_GlacialAdvance) then return _GlacialAdvance end
	
	-- actions.aoe+=/frost_strike,target_if=RAZORICE_CALC
	if runic >= FSCost then return _FrostStrike end

	return nil;
end

function DeathKnight:FrostSingleTarget()
	local frameData = MaxDps.FrameData;
	local runic = UnitPower('player', RunicPower);
	local runes, runeCd = DeathKnight:Runes(frameData.timeShift);
	local runic = UnitPower('player', RunicPower);

	-- actions.standard=remorseless_winter,if=talent.gathering_storm|conduit.everfrost|runeforge.biting_cold
	-- actions.standard+=/glacial_advance,if=!death_knight.runeforge.razorice&(debuff.razorice.stack<5|debuff.razorice.remains<7)
	-- actions.standard+=/frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm
	-- actions.standard+=/frost_strike,if=conduit.eradicating_blow&buff.eradicating_blow.stack=2|conduit.unleashed_frenzy&buff.unleashed_frenzy.remains<3&buff.unleashed_frenzy.up
	-- actions.standard+=/howling_blast,if=buff.rime.up
	-- actions.standard+=/obliterate,if=!buff.frozen_pulse.up&talent.frozen_pulse
	-- actions.standard+=/frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation*3)
	-- actions.standard+=/obliterate,if=runic_power.deficit>(25+talent.runic_attenuation*3)
	-- actions.standard+=/frost_strike
	-- actions.standard+=/horn_of_winter
	-- actions.standard+=/arcane_torrent

	-- if HasTalent(_GatheringStorm) then
		if runes >= 1 and canCastSpell(_RemorselessWinter) then return _RemorselessWinter end
	-- end

	if HasTalent(_IcyTalonsTalent) and PlayerBuff(_IcyTalons).remains < 2 and runic >= 25 then
		return _FrostStrike
	end

	if PlayerBuff(_Rime).up then
		if runes >= 1 then return _HowlingBlast end
	end

	if HasTalent(_FrozenPulse) and runes >= 2 then return _Obliterate end

	if runic >= 73 then return _FrostStrike end

	if PlayerBuff(_KillingMachine).up and runes >= 4 then
		return _Obliterate
	end

	if runes >= 2 then return _Obliterate end

	if runic >= 25 then return _FrostStrike end
end

function DeathKnight:FrostBosTicking()
	local targets = MaxDps:SmartAoe();
	local fd = MaxDps.FrameData;
	local timeShift = fd.timeShift;

	local runes, runeCd = DeathKnight:Runes(timeShift);
	local runic = UnitPower('player', RunicPower);

	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
	fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	if runic < 30 then
		return _Obliterate
	end

	if (targets >= 2 or HasTalent(_GatheringStorm)) and canCastSpell(_RemorselessWinter).ready then
		return _RemorselessWinter
	end

	if runes >= 1 and (buff[_Rime].up or not fever) then
		return _HowlingBlast;
	end

	return _Obliterate
end

function DeathKnight:Frost()
	local targets = MaxDps:SmartAoe();
	local fd = MaxDps.FrameData;
	local timeShift = fd.timeShift;

	local runes, runeCd = DeathKnight:Runes(timeShift);
	local runic = UnitPower('player', RunicPower);

	local hasFever, feverRemains = TargetHasDebuff(_FrostFever)
	local bosReady, bosCd = SpellAvailable(_BreathOfSindragosa);

	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
	fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local runic = UnitPower('player', RunicPower);
	local runicMax = UnitPowerMax('player', RunicPower);
	local runes, runeCd = DeathKnight:Runes(timeShift);
	local targets = MaxDps:SmartAoe();

	local fever = debuff[_FrostFever].remains > 6;
	local FSCost = 25;

	fd.targets = targets;

	MaxDps:GlowEssences();
	--BoS only glows when it is at its most efficient point of being used...above 60 runic power
	MaxDps:GlowCooldown(_BreathOfSindragosa, talents[_BreathOfSindragosa] and cooldown[_BreathOfSindragosa].ready and runic >= 60 and runes <= 1);

	-- MaxDps:GlowCooldown(_FrostwyrmsFury, cooldown[_FrostwyrmsFury].ready);
	MaxDps:GlowCooldown(_PillarOfFrost, canCastSpell(_PillarOfFrost));
	MaxDps:GlowCooldown(_RaiseDead, canCastSpell(_RaiseDead));
	MaxDps:GlowCooldown(_SacrificialPact, spellCooldown(_RaiseDead) > 60 and spellCooldown(_RaiseDead) < 50);

	-- Basic On CD Abilities to cast throughout all talent specs
	if not hasFever and bosCd > 15 then
		if runes >= 1 then return _HowlingBlast end
	end

	if canCastSpell(_DeathsDue) and targets > 1 then
		if runes >= 1 then return _DeathsDue end
	end

	if (targets >= 2 or HasTalent(_GatheringStorm)) and canCastSpell(_RemorselessWinter) then
		return _RemorselessWinter
	end

	if HasTalent(_ColdHeartTalent) and PlayerBuff(_ColdHeart).count > 10 and PlayerBuff(_PillarOfFrost).up and PlayerBuff(_PillarOfFrost).remains < 4 then
		return _ChainsOfIce;
	end

	if HasTalent(_ColdHeartTalent) and spellCooldown(_PillarOfFrost) > 20 and spellCooldown(_PillarOfFrost) > 30 then
		MaxDps:GlowCooldown(_ChainsOfIce);
	end

	-- Prevent Cold Heart overcapping during pillar
	-- actions.cold_heart+=/chains_of_ice,if=talent.obliteration&!buff.pillar_of_frost.up&(buff.cold_heart.stack>=16&buff.unholy_strength.up|buff.cold_heart.stack>=19|cooldown.pillar_of_frost.remains<3&buff.cold_heart.stack>=14

	if (PlayerBuff(_BreathOfSindragosa).up) then
		return DeathKnight:FrostBosTicking()
	elseif targets < 2 then
		return DeathKnight:FrostSingleTarget()
	else
		return DeathKnight:FrostAoe()
	end
end

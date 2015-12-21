#!/usr/bin/env python
# -*- coding: utf8 -*-

import re
import sys
import time

import monster
import plistlib

SIZES = [ "tiny", "small", "medium", "large", "huge", "gargantuan" ]
MONSTER_TYPES = [ "aberration", "beast", "celestial", "construct", "dragon", "elemental", "fey",
				  "fiend", "giant", "humanoid", "monstrosity", "ooze", "plant", "undead" ]
ALIGNMENTS = [ "unaligned", "lawful good", "lawful neutral", "lawful evil",
			   "neutral good", "neutral", "neutral evil",
			   "chaotic good", "chaotic neutral", "chaotic evil" ]

ALIGNMENT_OPTIONS = {
	"any alignment": ALIGNMENTS[1:],
	"any chaotic alignment": [ "chaotic good", "chaotic neutral", "chaotic evil" ],
	"any evil alignment": [ "lawful evil", "neutral evil", "chaotic evil" ],
	"any non-good alignment": [ "lawful neutral", "lawful evil", "neutral", "neutral evil", "chaotic neutral", "chaotic evil" ],
	"any non-lawful alignment": [ "neutral good", "neutral", "neutral evil", "chaotic good", "chaotic neutral", "chaotic evil" ],
}

size_expr = "|".join(size.title() for size in SIZES)
monster_type_expr = "|".join(MONSTER_TYPES)
alignment_expr = "|".join(ALIGNMENTS)
alignment_option_expr = "|".join(ALIGNMENT_OPTIONS.keys())

SIZE_TYPE_TAG_ALIGNMENT_RE  = re.compile(
	r'^(?:(' + size_expr + r') (' + monster_type_expr + r')'
	r'|(' + size_expr + r') (?:swarm of (' + size_expr + r') (' + monster_type_expr + r')s))' +
	r'(?: \(([^)]+)\))?, ' +
	r'(?:(' + alignment_expr + r')|(' + alignment_option_expr + r')'
	r'|(' + alignment_expr + r') \((\d+)%\) or (' + alignment_expr + r') \((\d+)%\))$')

ARMOR_TYPES = [ None, "natural", "padded", "leather", "studded leather", "hide", "chain shirt",
                "scale mail", "breastplate", "half plate", "ring mail", "chain mail",
                "splint", "plate", "armor scraps", "barding scraps", "patchwork" ]
DAMAGE_TYPES = [ "acid", "bludgeoning", "cold", "fire", "force", "lightning", "necrotic", "piercing",
                 "poison", "psychic", "radiant", "slashing", "thunder" ]
CONDITIONS = [ "blinded", "charmed", "deafened", "exhaustion", "frightened", "grappled",
			   "incapacitated", "invisible", "paralyzed", "petrified", "poisoned", "prone",
			   "restrained", "stunned", "unconscious" ]

armor_expr = "|".join(armor for armor in ARMOR_TYPES if armor is not None)
damage_expr = "|".join(DAMAGE_TYPES)
condition_expr = "|".join(CONDITIONS)

ARMOR_CLASS_RE = re.compile(
	r'^(\d+)(?: \((?:([+-]\d+) )?(' + armor_expr + r')(?: armor)?(?:, (shield))?\))?' +
	r'(?: \((\d+) with ([^)]+)\))?' +
	r'(?:, (\d+) while (' + condition_expr + r'))?$')
#	r'| (in [^,]+ form), (\d+) \((' + armor_expr + r')(?: armor)?\) (in .+ form))?$')
HIT_POINTS_RE = re.compile(r'^(\d+) \(([^)]*)\)$')

SPEED_RE = re.compile(
	r'^(\d+) ft\.(?:, burrow (\d+) ft\.)?(?:, climb (\d+) ft\.)?' +
	r'(?:, fly (\d+) ft\.(?: \((hover)\))?)?(?:, swim (\d+) ft\.)?$')

ABILITY_RE = re.compile(r'^(\d+) \(([+-]\d+)\)$')

SAVING_THROW_SKILLS_RE = re.compile(r'^([A-Za-z ]+) ([+-]\d+)$')

DAMAGE_VULNERABILITIES_RE = re.compile(
	r'^(?:((?:(?:' + damage_expr + ')(?:, |$))+)' +
	r'|(' + damage_expr + r') from magic weapons wielded by good creatures)$' # Rakshasa
	)

DAMAGE_RESISTANCES_RE = re.compile(
	r'^(?=.)' +
	r'(?:' +
		r'((?:(?:' + damage_expr + ')(?:, |(?=; )|$))+)' +
		r'(?:; |$))?' +
	r'(?:' +
		r'(?:(' + damage_expr + ')' +
		r'|(' + damage_expr + ') and (' + damage_expr + ')' +
		r'|((?:(?:' + damage_expr + '), )+)and (' + damage_expr + '))' +
		r'(?: from nonmagical attacks' +
		r'(?: not made with (adamantine|silvered) weapons)?' +
		r'| from (magic) weapons' + # Demilich
		r'| from nonmagical weapons that aren\'t (silvered)' + # Old-style nonmagical non-silvered
		r'))?' +
	r'$'
	)

DAMAGE_RESISTANCE_OPTIONS_RE = re.compile(
	r'^one of the following: ((?:(?:' + damage_expr + ')(?:, ))+)or (' + damage_expr + ')$')

ARCHMAGE_DAMAGE_RESISTANCE_RE = re.compile(
	r'^damage from spells; nonmagical ' +
	r'((?:(?:' + damage_expr + ')(?:, ))+)and (' + damage_expr + ')' +
	r' \(from ([^)]+)\)$')

# This is basically the same as above, so keep the two roughly in sync except for the special-cases.
DAMAGE_IMMUNITIES_RE = re.compile(
	r'^(?=.)' +
	r'(?:' +
		r'((?:(?:' + damage_expr + ')(?:, |(?=; )|$))+)' +
		r'(?:; |$))?' +
	r'(?:' +
		r'(?:(' + damage_expr + ')' +
		r'|(' + damage_expr + ') and (' + damage_expr + ')' +
		r'|((?:(?:' + damage_expr + '), )+)and (' + damage_expr + '))' +
		r'(?: from nonmagical attacks' +
		r'(?: not made with (adamantine|silvered) weapons)?' +
		r'| from nonmagical weapons' + # Old-style nonmagical
		r'))?' +
	r'$'
	)

CONDITION_IMMUNITIES_RE = re.compile(r'^(?:(?:' + condition_expr + ')(?:, |$))+$')

SENSES_RE = re.compile(
	r'^(?:blindsight (\d+) ft\.(?: \((blind beyond this radius)\))?(?:, |$))?'
	r'(?:darkvision (\d+) ft\.(?:, |$))?'
	r'(?:tremorsense (\d+) ft\.(?:, |$))?'
	r'(?:truesight (\d+) ft\.(?:, |$))?'
	r'passive Perception (\d+)$')

DICE_RE = re.compile(r'^(?:[1-9][0-9]*(?:d(?:2|4|6|8|10|12|20|100))?(?: *[+-] *(?=[^ ]))?)+$')
DICE_ANYWHERE_RE = re.compile(r'(?:[1-9][0-9]*(?:d(?:2|4|6|8|10|12|20|100))?(?: *[+-] *(?=[^ ]))?)+')
SPELL_RE = re.compile(r'/([a-z ]+)/')

CHALLENGE_RE = re.compile(r'^([0-9/]+) \(([0-9,]+)(?: XP)?\)$')

XP = {
	"0": "10",
	"1/8": "25",
	"1/4": "50",
	"1/2": "100",
	"1": "200",
	"2": "450",
	"3": "700",
	"4": "1,100",
	"5": "1,800",
	"6": "2,300",
	"7": "2,900",
	"8": "3,900",
	"9": "5,000",
	"10": "5,900",
	"11": "7,200",
	"12": "8,400",
	"13": "10,000",
	"14": "11,500",
	"15": "13,000",
	"16": "15,000",
	"17": "18,000",
	"18": "20,000",
	"19": "22,000",
	"20": "25,000",
	"21": "33,000",
	"22": "41,000",
	"23": "50,000",
	"24": "62,000",
	"25": "75,000",
	"26": "90,000",
	"27": "105,000",
	"28": "120,000",
	"29": "135,000",
	"30": "155,000",
}

class Exporter(monster.MonsterParser):

	def __init__(self, filename, bookTags):
		super(Exporter, self).__init__(filename)
		self.bookTags = bookTags

		self.name = None
		self.sources = []
		self.tags = []
		self.alignment_options = []
		self.armor = []
		self.damage_vulnerabilities = []
		self.damage_resistances = []
		self.damage_resistance_options = []
		self.damage_immunities = []
		self.condition_immunities = []
		self.info = {}
		self.traits = []
		self.actions = []
		self.reactions = []
		self.legendary_actions = []
		self.lair = None

	def check_line(self, line):
		if " ," in line:
			raise self.error("Space before comma: %s" % line)
		if " ." in line:
			raise self.error("Space before period: %s" % line)
		if "·" in line:
			raise self.error("Bad space marker: %s" % line)
		if "’" in line:
			raise self.error("Bad quote: %s" % line)
		if " o f " in line or "ofthe" in line or "ofit" in line or "ofa" in line:
			raise self.error("Spotted o f, ofthe, ofit, or ofa: %s" % line)
		if "e ects" in line:
			raise self.error("Spotted missing ff: %s" % line)
		if " y " in line or " ies " in line or "amo uage" in line:
			raise self.error("Spotted missing fl: %s" % line)
		if "igni cant" in line or " ist " in line or " re " in line:
			raise self.error("Spotted missing fi: %s" % line)
		if "i cult" in line:
			raise self.error("Spotted missing ffi: %s" % line)

		if re.search(r'[0-9]-[0-9]', line):
			raise self.error("Spotted dash that should be en-dash: %s" % line)

		if re.search('r[0-9][lIJSO]|[lIJSO][0-9]|[lJSO][JSO]+|[lI]d[0-9]', line):
			raise self.error("Suspicious number-like form: %s" % line)

		for part in DICE_ANYWHERE_RE.split(line):
			if "- " in part:
				raise self.error("Probable bad hyphenation: %s" % line)

	def object(self):
		object = {
			"name": unicode(self.name, 'utf8'),
			"sources": self.sources,
			"tags": self.tags,
			"alignmentOptions": self.alignment_options,
			"armor": self.armor,
			"damageVulnerabilities": self.damage_vulnerabilities,
			"damageResistances": self.damage_resistances,
			"damageResistanceOptions": self.damage_resistance_options,
			"damageImmunities": self.damage_immunities,
			"conditionImmunities": self.condition_immunities,
			"info": self.info,
			"traits": self.traits,
			"actions": self.actions,
			"reactions": self.reactions,
			"legendaryActions": self.legendary_actions,
		}
		if self.lair is not None:
			object['lair'] = self.lair

		return object

	def handle_name(self, name):
		self.name = name
		self.info['name'] = unicode(name, 'utf8')

	def handle_source(self, source, page, section):
		try:
			index = self.bookTags.index(source)
		except ValueError:
			raise self.error("Unknown book tag: %s" % source)

		source = {
			"book": index,
			"page": int(page),
		}

		if section is not None:
			source["section"] = section

		self.sources.append(source)

	def handle_npc(self):
		self.info['isNPC'] = True

	def handle_size_type_alignment(self, line):
		match = SIZE_TYPE_TAG_ALIGNMENT_RE.match(line)
		if match is None:
			raise self.error("Size/Type/Alignment didn't match expected format: %s" % line)

		(size, type, swarm_size, swarm_monster_size, swarm_type, tags, alignment, alignment_option,
			alignment1, alignment1_weight, alignment2, alignment2_weight) = match.groups()
		if swarm_size is not None:
			self.info['rawSwarmSize'] = SIZES.index(swarm_size.lower())

			size = swarm_monster_size
			type = swarm_type

		self.info['rawSize'] = SIZES.index(size.lower())
		self.info['rawType'] = MONSTER_TYPES.index(type)

		if tags is not None:
			tags = tags.split(", ")
			if "any race" in tags:
				tags.remove("any race")
				self.info['requiresRace'] = True
			self.tags.extend(tags)

		if alignment is not None:
			self.info['rawAlignment'] = ALIGNMENTS.index(alignment)
		elif alignment_option is not None:
			for alignment in ALIGNMENT_OPTIONS[alignment_option]:
				self.alignment_options.append([ ALIGNMENTS.index(alignment) ])
		elif alignment1 is not None:
			self.alignment_options.append([
				ALIGNMENTS.index(alignment1), float(alignment1_weight) / 100.0 ])
			self.alignment_options.append([
				ALIGNMENTS.index(alignment2), float(alignment2_weight) / 100.0 ])

	def handle_armor_class(self, line):
		match = ARMOR_CLASS_RE.match(line)
		if match is None:
			raise self.error("Armor Class didn't match expected format: %s" % line)

		(armor_class, magic_armor_modifier, armor_type, shield,
		 armor_spell_class, armor_spell,
		 armor_condition_class, armor_condition) = match.groups()
		#armor_original_form, armor_form_class, armor_form_type, armor_form) = match.groups()

		armor = {
			'rawArmorClass': int(armor_class),
			'rawType': ARMOR_TYPES.index(armor_type),
			'includesShield': (shield is not None),
		}
		if magic_armor_modifier is not None:
			armor['rawMagicModifier'] = int(magic_armor_modifier)
		#if armor_original_form is not None:
		#	armor['form'] = armor_original_form

		self.armor.append(armor)

		# FIXME This is a hack right now to ensure they're displayed.
		# Really we want to handle spells and magic items in their own right.
		if armor_spell_class is not None:
			armor = {
				'rawArmorClass': int(armor_spell_class),
				'rawType': 0,
				'spellName': armor_spell,
			}

			self.armor.append(armor)

		# Condition-specific armor.
		if armor_condition_class is not None:
			armor = {
				'rawArmorClass': int(armor_condition_class),
				'rawType': 0,
				'rawCondition': CONDITIONS.index(armor_condition),
			}

			self.armor.append(armor)

		# FIXME this is also a hack right now to ensure they're displayed.
		# Really we want to handle forms in their own right too.
		#if armor_form_class is not None:
		#	armor = {
		#		'rawArmorClass': int(armor_form_class),
		#		'rawType': ARMOR_TYPES.index(armor_form_type),
		#		'form': armor_form
		#	}
		#
		#	self.armor.append(armor)

	def handle_hit_points(self, line):
		match = HIT_POINTS_RE.match(line)
		if match is None:
			raise self.error("Hit Points didn't match expected format: %s" % line)

		(hp, dice) = match.groups()

		match = DICE_RE.match(dice)
		if match is None:
			raise self.error("Hit Points dice expression didn't match expected format: %s" % dice)

		self.info['rawHitPoints'] = int(hp)
		self.info['rawHitDice'] = dice

	def handle_speed(self, line):
		match = SPEED_RE.match(line)
		if match is None:
			raise self.error("Speed didn't match expected format: %s" % line)

		(speed, burrow_speed, climb_speed, fly_speed, fly_hover, swim_speed) = match.groups()

		self.info['rawSpeed'] = int(speed)
		if burrow_speed is not None:
			self.info['rawBurrowSpeed'] = int(burrow_speed)
		if climb_speed is not None:
			self.info['rawClimbSpeed'] = int(climb_speed)
		if fly_speed is not None:
			self.info['rawFlySpeed'] = int(fly_speed)
			if fly_hover is not None:
				self.info['canHover'] = True
		if swim_speed is not None:
			self.info['rawSwimSpeed'] = int(swim_speed)

	def handle_str(self, line):
		self.handle_ability_score(line, 'strength')

	def handle_dex(self, line):
		self.handle_ability_score(line, 'dexterity')

	def handle_con(self, line):
		self.handle_ability_score(line, 'constitution')

	def handle_int(self, line):
		self.handle_ability_score(line, 'intelligence')

	def handle_wis(self, line):
		self.handle_ability_score(line, 'wisdom')

	def handle_cha(self, line):
		self.handle_ability_score(line, 'charisma')

	def handle_ability_score(self, line, name):
		match = ABILITY_RE.match(line)
		if match is None:
			raise self.error("%s ability score doesn't match expected formated: %s" % (name.title(), line))

		(score, modifier) = match.groups()
		calculated = (int(score) - 10) / 2

		if int(modifier) != calculated:
			raise self.error("%s ability score modifier (%s) didn't match that calculated from score %s (%d)" % (
				name.title(), modifier, score, calculated))

		self.info['raw' + name.title() + 'Score'] = int(score)

	def handle_saving_throws(self, line):
		saving_throws = line.split(", ")
		for saving_throw in saving_throws:
			match = SAVING_THROW_SKILLS_RE.match(saving_throw)
			if match is None:
				raise self.error("Saving throw doesn't match expected format: %s" % saving_throw)

			(name, modifier) = match.groups()
			if name == "Str" or name == "Strength":
				self.info['rawStrengthSavingThrow'] = int(modifier)
			elif name == "Dex" or name == "Dexterity":
				self.info['rawDexteritySavingThrow'] = int(modifier)
			elif name == "Con" or name == "Constitution":
				self.info['rawConstitutionSavingThrow'] = int(modifier)
			elif name == "Int" or name == "Intelligence":
				self.info['rawIntelligenceSavingThrow'] = int(modifier)
			elif name == "Wis" or name == "Wisdom":
				self.info['rawWisdomSavingThrow'] = int(modifier)
			elif name == "Cha" or name == "Charisma":
				self.info['rawCharismaSavingThrow'] = int(modifier)
			else:
				raise self.error("Unknown ability in saving throw: %s" % saving_throw)

	def handle_skills(self, line):
		skills = line.split(", ")
		for skill in skills:
			match = SAVING_THROW_SKILLS_RE.match(skill)
			if match is None:
				raise self.error("Skill doesn't match expected format: %s" % skill)

			(name, modifier) = match.groups()
			if name == "Acrobatics":
				self.info['rawAcrobaticsSkill'] = int(modifier)
			elif name == "Animal Handling":
				self.info['rawAnimalHandlingSkill'] = int(modifier)
			elif name == "Arcana":
				self.info['rawArcanaSkill'] = int(modifier)
			elif name == "Athletics":
				self.info['rawAthleticsSkill'] = int(modifier)
			elif name == "Deception":
				self.info['rawDeceptionSkill'] = int(modifier)
			elif name == "History":
				self.info['rawHistorySkill'] = int(modifier)
			elif name == "Insight":
				self.info['rawInsightSkill'] = int(modifier)
			elif name == "Intimidation":
				self.info['rawIntimidationSkill'] = int(modifier)
			elif name == "Investigation":
				self.info['rawInvestigationSkill'] = int(modifier)
			elif name == "Medicine":
				self.info['rawMedicineSkill'] = int(modifier)
			elif name == "Nature":
				self.info['rawNatureSkill'] = int(modifier)
			elif name == "Perception":
				self.info['rawPerceptionSkill'] = int(modifier)
			elif name == "Performance":
				self.info['rawPerformanceSkill'] = int(modifier)
			elif name == "Persuasion":
				self.info['rawPersuasionSkill'] = int(modifier)
			elif name == "Religion":
				self.info['rawReligionSkill'] = int(modifier)
			elif name == "Sleight of Hand":
				self.info['rawSleightOfHandSkill'] = int(modifier)
			elif name == "Stealth":
				self.info['rawStealthSkill'] = int(modifier)
			elif name == "Survival":
				self.info['rawSurvivalSkill'] = int(modifier)
			else:
				raise self.error("Unknown skill: %s" % skill)

	def handle_damage_vulnerabilities(self, line):
		match = DAMAGE_VULNERABILITIES_RE.match(line)
		if match is None:
			raise self.error("Damage Vulnerabilities line didn't match expected format: %s" % line)

		(damage_list, good_damage) = match.groups()
		if damage_list is not None:
			damage_types = [ DAMAGE_TYPES.index(x) for x in damage_list.split(", ") ]

			for damage_type in damage_types:
				self.damage_vulnerabilities.append({
					'rawDamageType': damage_type,
					'rawAttackType': 0,
				})

		elif good_damage is not None:
			self.damage_vulnerabilities.append({
				'rawDamageType': DAMAGE_TYPES.index(good_damage),
				'rawAttackType': 5,
			})

	def handle_damage_resistances(self, line):
		match = DAMAGE_RESISTANCES_RE.match(line)
		if match is None:
			match = DAMAGE_RESISTANCE_OPTIONS_RE.match(line)
			if match is not None:
				return self.handle_damage_resistance_options(match)

			raise self.error("Damage Resistances line didn't match expected format: %s" % line)

		(damage_list, nonmagical_damage0, nonmagical_damage1, nonmagical_damage2,
		 nonmagical_damage_list, nonmagical_damage3,
		 special_weapon_type, magic_not_nonmagic, oldstyle_nonmagical_special) = match.groups()

		if damage_list is not None:
			damage_types = [ DAMAGE_TYPES.index(x) for x in damage_list.split(", ") ]

			for damage_type in damage_types:
				self.damage_resistances.append({
					'rawDamageType': damage_type,
					'rawAttackType': 0,
				})

		nonmagical_damage_types = None
		if nonmagical_damage_list is not None:
			nonmagical_damage_types = nonmagical_damage_list.split(", ")[:-1]
			nonmagical_damage_types.append(nonmagical_damage3)
		elif nonmagical_damage1 is not None:
			nonmagical_damage_types = [ nonmagical_damage1, nonmagical_damage2 ]
		elif nonmagical_damage0 is not None:
			nonmagical_damage_types = [ nonmagical_damage0 ]

		if nonmagical_damage_types is not None:
			damage_types = [ DAMAGE_TYPES.index(x) for x in nonmagical_damage_types ]

			if special_weapon_type == "adamantine" or oldstyle_nonmagical_special == "adamantine":
				attack_type = 2
			elif special_weapon_type == "silvered" or oldstyle_nonmagical_special == "silvered":
				attack_type = 3
			elif magic_not_nonmagic is not None:
				attack_type = 4
			else:
				attack_type = 1

			for damage_type in damage_types:
				self.damage_resistances.append({
					'rawDamageType': damage_type,
					'rawAttackType': attack_type,
				})

	def handle_damage_resistance_options(self, match):
		(damage_list, last_damage) = match.groups()
		damage_types = [ DAMAGE_TYPES.index(x) for x in damage_list.split(", ")[:-1] ]
		damage_types.append(DAMAGE_TYPES.index(last_damage))

		for damage_type in damage_types:
			self.damage_resistance_options.append({
				'rawDamageType': damage_type,
			})

	def handle_archmage_damage_resistance(self, line):
		match = ARCHMAGE_DAMAGE_RESISTANCE_RE.match(line)
		if match is None:
			raise self.error("Archmage Damage Reistance line didn't match expected format: %s" % line)

		(damage_list, last_damage, spell_name) = match.groups()
		damage_types = [ DAMAGE_TYPES.index(x) for x in damage_list.split(", ")[:-1] ]
		damage_types.append(DAMAGE_TYPES.index(last_damage))

		for damage_type in damage_types:
			self.damage_resistances.append({
				'rawDamageType': damage_type,
				'rawAttackType': 1,
				'spellName': spell_name,
			})

		self.info['isResistantToSpellDamage'] = True

	def handle_damage_immunities(self, line):
		match = DAMAGE_IMMUNITIES_RE.match(line)
		if match is None:
			raise self.error("Damage Immunities line didn't match expected format: %s" % line)

		(damage_list, nonmagical_damage0, nonmagical_damage1, nonmagical_damage2,
		 nonmagical_damage_list, nonmagical_damage3, special_weapon_type) = match.groups()

		if damage_list is not None:
			damage_types = [ DAMAGE_TYPES.index(x) for x in damage_list.split(", ") ]

			for damage_type in damage_types:
				self.damage_immunities.append({
					'rawDamageType': damage_type,
					'rawAttackType': 0,
				})

		nonmagical_damage_types = None
		if nonmagical_damage_list is not None:
			nonmagical_damage_types = nonmagical_damage_list.split(", ")[:-1]
			nonmagical_damage_types.append(nonmagical_damage3)
		elif nonmagical_damage1 is not None:
			nonmagical_damage_types = [ nonmagical_damage1, nonmagical_damage2 ]
		elif nonmagical_damage0 is not None:
			nonmagical_damage_types = [ nonmagical_damage0 ]

		if nonmagical_damage_types is not None:
			damage_types = [ DAMAGE_TYPES.index(x) for x in nonmagical_damage_types ]

			if special_weapon_type == "adamantine":
				attack_type = 2
			elif special_weapon_type == "silvered":
				attack_type = 3
			else:
				attack_type = 1

			for damage_type in damage_types:
				self.damage_immunities.append({
					'rawDamageType': damage_type,
					'rawAttackType': attack_type,
				})

	def handle_condition_immunities(self, line):
		match = CONDITION_IMMUNITIES_RE.match(line)
		if match is None:
			raise self.error("Condition Immunities line didn't match expected format: %s" % line)

		conditions = [ CONDITIONS.index(x) for x in line.split(", ") ]
		for condition in conditions:
			self.condition_immunities.append({
				'rawCondition': condition
			})

	def handle_senses(self, line):
		match = SENSES_RE.match(line)
		if match is None:
			raise self.error("Senses line didn't match expected format: %s" % line)

		(blindsight, blinded, darkvision, tremorsense, truesight, passive) = match.groups()

		if blindsight is not None:
			self.info['rawBlindsight'] = int(blindsight)
		if blinded is not None:
			self.info['isBlind'] = True
		if darkvision is not None:
			self.info['rawDarkvision'] = int(darkvision)
		if tremorsense is not None:
			self.info['rawTremorsense'] = int(tremorsense)
		if truesight is not None:
			self.info['rawTruesight'] = int(truesight)

		# Don't store passive perception, just verify it matches the calculated value.
		expectedPassive = 10
		if 'rawPerceptionSkill' in self.info:
			expectedPassive = 10 + int(self.info['rawPerceptionSkill'])
		else:
			score = int(self.info['rawWisdomScore'])
			expectedPassive = 10 + (int(score) - 10) / 2

		if int(passive) != expectedPassive:
			raise self.error("Passive Perception didn't match expected value (%d): %d" % (expectedPassive, passive))

	def handle_languages(self, line):
		# TODO: easy to parse
		if line != "-":
			self.info['languages'] = line

	def handle_challenge(self, line):
		match = CHALLENGE_RE.match(line)
		if match is None:
			raise self.error("Challenge didn't match expected format: %s" % line)

		(cr, xp) = match.groups()
		if XP[cr] != xp:
			if cr != "0" or xp != "0":
				raise self.error("XP didn't match expected for challenge: %s" % xp)

		if cr == '1/8':
			cr = 1.0/8
		elif cr == '1/4':
			cr = 1.0/4
		elif cr == '1/2':
			cr = 1.0/2
		else:
			cr = float(cr)

		self.info['challenge'] = cr

	def add_action(self, list, name, lines):
		name = name.rstrip('.')
		text = "\n".join(SPELL_RE.sub(r'\1', line) for line in lines)

		list.append({
			"name": unicode(name, 'utf8'),
			"text": unicode(text, 'utf8'),
		})

	def handle_traits(self, traits):
		for name, lines in traits:
			self.add_action(self.traits, name, lines)

	def handle_actions(self, actions):
		for name, lines in actions:
			self.add_action(self.actions, name, lines)

	def handle_yuan_ti_actions(self, section, actions):
		for name, lines in actions:
			self.add_action(self.actions, section + '—' + name, lines)

	def handle_reactions(self, reactions):
		for name, lines in reactions:
			self.add_action(self.reactions, name, lines)

	def handle_legendary_actions(self, lines, actions):
		for name, lines in actions:
			self.add_action(self.legendary_actions, name, lines)

	def handle_lair(self, lines):
		text = "\n".join(SPELL_RE.sub(r'\1', line) for line in lines)

		self.lair_info = {
			"text": unicode(text, 'utf8'),
		}
		self.lair_actions = []
		self.lair_traits = []
		self.regional_effects = []

		self.lair = {
			"info": self.lair_info,
			"lairActions": self.lair_actions,
			"lairTraits": self.lair_traits,
			"regionalEffects": self.regional_effects,
		}

	def handle_lair_actions(self, intro_lines, lair_actions, limiting_lines):
		intro_text = "\n".join(SPELL_RE.sub(r'\1', line) for line in intro_lines)
		self.lair_info["lairActionsText"] = unicode(intro_text, 'utf8')

		for lines in lair_actions:
			text = "\n".join(SPELL_RE.sub(r'\1', line) for line in lines)
			self.lair_actions.append(unicode(text, 'utf8'))

		if limiting_lines is not None:
			limiting_text = "\n".join(SPELL_RE.sub(r'\1', line) for line in limiting_lines)
			self.lair_info["lairActionsLimit"] = unicode(limiting_text, 'utf8')

	def handle_lair_traits(self, intro_lines, lair_traits, duration_lines):
		intro_text = "\n".join(SPELL_RE.sub(r'\1', line) for line in intro_lines)
		self.lair_info["lairTraitsText"] = unicode(intro_text, 'utf8')

		for lines in lair_traits:
			text = "\n".join(SPELL_RE.sub(r'\1', line) for line in lines)
			self.lair_traits.append(unicode(text, 'utf8'))

		duration_text = "\n".join(SPELL_RE.sub(r'\1', line) for line in duration_lines)
		self.lair_info["lairTraitsDuration"] = unicode(duration_text, 'utf8')

	def handle_regional_effects(self, intro_lines, regional_effects, duration_lines):
		intro_text = "\n".join(SPELL_RE.sub(r'\1', line) for line in intro_lines)
		self.lair_info["regionalEffectsText"] = unicode(intro_text, 'utf8')

		for lines in regional_effects:
			text = "\n".join(SPELL_RE.sub(r'\1', line) for line in lines)
			self.regional_effects.append(unicode(text, 'utf8'))

		duration_text = "\n".join(SPELL_RE.sub(r'\1', line) for line in duration_lines)
		self.lair_info["regionalEffectsDuration"] = unicode(duration_text, 'utf8')


def main():
	books = [
		{
			"name": "Player's Handbook",
			"type": 0,
		},
		{
			"name": "Monster Manual",
			"type": 0,
		},
		{
			"name": "Dungeon Master's Guide",
			"type": 0,
		},
		{
			"name": "Dungeon Master's Basic Rules",
			"type": 2,
		},
		{
			"name": "Lost Mine of Phandelver",
			"type": 1,
		},
		{
			"name": "Hoard of the Dragon Queen",
			"type": 1,
		},
		{
			"name": "Hoard of the Dragon Queen Online Supplement",
			"type": 2,
		},
		{
			"name": "The Rise of Tiamat",
			"type": 1,
		},
		{
			"name": "The Rise of Tiamat Online Supplement",
			"type": 2,
		},
		{
			"name": "Princes of the Apocalypse",
			"type": 1,
		},
		{
			"name": "Princes of the Apocalypse Online Supplement",
			"type": 2,
		},
		{
			"name": "Out of the Abyss",
			"type": 1,
		}
	]
	bookTags = [
		"phb", "mm", "dmg", "dmbr",
		"lmop", "hotdq", "hotdqs", "trot", "trots", "pota", "potas", ]

	monsters = []
	for filename in monster.local_files():
		parser = Exporter(filename, bookTags=bookTags)
		try:
			try:
				parser.parse()
				monsters.append(parser.object())
			except monster.ParseException, e:
				print >>sys.stderr, "%s:%d:%s" % (e.filename, e.lineno, e.message)
		finally:
			parser.close()

	rootObject = {
		"books": books,
		"monsters": monsters,
		"version": int(time.mktime(time.gmtime())),
	}

	print plistlib.writePlistToString(rootObject)

if __name__ == "__main__":
	main()

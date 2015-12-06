#!/usr/bin/env python
# -*- coding: utf8 -*-

import re
import sys
import time

import monster
import plistlib

size_expr = r'Tiny|Small|Medium|Large|Huge|Gargantuan'
type_expr = r'aberration|beast|celestial|construct|dragon|elemental|fey|fiend|giant|humanoid|monstrosity|ooze|plant|undead'

SIZE_TYPE_TAG_RE  = re.compile(
	r'^(?:(' + size_expr + r') (' + type_expr + r')'
	r'|(' + size_expr + r') (swarm of (?:' + size_expr + r') (?:' + type_expr + r')s))' +
	r'(?: \(([^)]+)\))?, (.*)')

ALIGNMENT_RE = re.compile(
	r'^(?:unaligned|neutral' +
	r'|neutral (?:good|evil)|(?:lawful|chaotic) (?:good|neutral|evil))$')


HIT_POINTS_RE = re.compile(r'^(\d+) \(([^)]*)\)$')
ABILITY_RE = re.compile(r'^(\d+) \(([+-]\d+)\)$')
SENSES_RE = re.compile(r'^(?:.*, )?passive Perception (\d+)$')

DICE_RE = re.compile(r'^(?:[1-9][0-9]*(?:d(?:2|4|6|8|10|12|20|100))(?: *[+-] *?(?=[^ ]))?)+$')
SPELL_RE = re.compile(r'/([a-z ]+)/')

class Exporter(monster.MonsterParser):

	def __init__(self, filename, bookTags):
		super(Exporter, self).__init__(filename)
		self.bookTags = bookTags

		self.name = None
		self.sources = []
		self.tags = []
		self.info = {}
		self.traits = []
		self.actions = []
		self.reactions = []
		self.legendary_actions = []
		self.lair = None

	def object(self):
		object = {
			"name": unicode(self.name, 'utf8'),
			"sources": self.sources,
			"tags": self.tags,
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
			self.error("Unknown book tag: %s" % bookTag)

		source = {
			"book": index,
			"page": int(page),
		}

		if section is not None:
			source["section"] = section

		self.sources.append(source)

	def handle_size_type_alignment(self, line):
		self.info['sizeTypeAlignment'] = line

		match = SIZE_TYPE_TAG_RE.match(line)
		if match is None:
			self.error("Size/Type/Alignment didn't match expected format: %s", line)

		(size, type, swarm_size, swarm_type, tags, alignment_text) = match.groups()
		if swarm_size is not None or swarm_type is not None:
			size = swarm_size
			type = swarm_type

		self.info['sizeValue'] = size
		self.info['type'] = type

		if tags is not None:
			self.tags.extend(tags.split(", "))

		match = ALIGNMENT_RE.match(alignment_text)
		if match is None:
			# TODO: Handle "any alignment", "any X alignment" with a set of alignments.
			# Can handle the Empyrean & Cloud Giant %age case with a set and weights.
			self.warning("Alignment didn't match expected format: %s" % alignment_text)
		else:
			self.info['alignmentValue'] = alignment_text

	def handle_armor_class(self, line):
		# TODO: should be able to parse into an AC, and a list of armor types
		# Remember to explode (X with SPELL).
		# Will still need to handle ", X while prone" and ", X (Y) in X or hybrid form"
		self.info['armorClass'] = line

	def handle_hit_points(self, line):
		self.info['hitPoints'] = line

		match = HIT_POINTS_RE.match(line)
		if match is None:
			self.error("Hit Points didn't match expected format: %s" % line)

		(hp, dice) = match.groups()

		match = DICE_RE.match(dice)
		if match is None:
			self.error("Hit Points dice expression didn't match expected format: %s" % dice)

		self.info['hp'] = int(hp)
		self.info['hpDice'] = dice.replace(" ", "")

	def handle_speed(self, line):
		# TODO: should be largely parseable
		self.info['speed'] = line

	def handle_str(self, line):
		self.handle_ability_score(line, 'strength', 'str')

	def handle_dex(self, line):
		self.handle_ability_score(line, 'dexterity', 'dex')

	def handle_con(self, line):
		self.handle_ability_score(line, 'constitution', 'con')

	def handle_int(self, line):
		self.handle_ability_score(line, 'intelligence', 'int')

	def handle_wis(self, line):
		self.handle_ability_score(line, 'wisdom', 'wis')

	def handle_cha(self, line):
		self.handle_ability_score(line, 'charisma', 'cha')

	def handle_ability_score(self, line, textKey, scoreKey):
		match = ABILITY_RE.match(line)
		if match is None:
			self.error("%s ability score doesn't match expected formated: %s" % (name.title(), line))

		(score, modifier) = match.groups()
		calculated = (int(score) - 10) / 2

		if int(modifier) != calculated:
			self.error("%s ability score modifier (%s) didn't match that calculated from score %s (%d)" % (
				name.title(), modifier, score, calculated))

		self.info[textKey] = line
		self.info[scoreKey] = int(score)

	def handle_saving_throws(self, line):
		# TODO: Should be easy to parse
		self.info['savingThrows'] = line

	def handle_skills(self, line):
		# TODO: easy to parse, except for the stealth/blindness case.
		self.info['skills'] = line

	def handle_damage_vulnerabilities(self, line):
		self.info['damageVulnerabilities'] = line

	def handle_damage_resistances(self, line):
		self.info['damageResistances'] = line

	def handle_damage_immunities(self, line):
		self.info['damageImmunities'] = line

	def handle_condition_immunities(self, line):
		self.info['conditionImmunities'] = line

	def handle_senses(self, line):
		# TODO: easy to parse
		self.info['senses'] = line

		match = SENSES_RE.match(line)
		if match is None:
			raise self.error("Senses line didn't have passive Perception")

		(passive,) = match.groups()
		self.info['passivePerception'] = int(passive)

	def handle_languages(self, line):
		# TODO: easy to parse
		if line != "-":
			self.info['languages'] = line

	def handle_challenge(self, line):
		# TODO: easy to parse
		self.info['challenge'] = line

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
			"name": "Monster Manual",
		},
		{
			"name": "Dungeon Master's Basic Rules"
		},
	]
	bookTags = [ "mm", "dmbr" ]

	monsters = []
	for filename in monster.local_files():
		parser = Exporter(filename, bookTags=bookTags)
		try:
			try:
				parser.parse()
				monsters.append(parser.object())
			except monster.ParseException, e:
				print >>sys.stderr, "%s:%d:%s" % (e.filename, e.lineno, e.message)
				sys.exit(1)
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

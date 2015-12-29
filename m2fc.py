#!/usr/bin/env python
# -*- coding: utf8 -*-

import re
import sys

import monster

from xml.sax.saxutils import escape

class FightClubConverter(monster.MonsterParser):
	SOURCES = {
		"mm": "monster manual",
		"dmbr": None,
	}

	SIZES = {
		"Tiny": "T",
		"Small": "S",
		"Medium": "M",
		"Large": "L",
		"Huge": "H",
		"Gargantuan": "G",
	}

	PP_RE = re.compile(r'^(?:(.*)(?:, ))?passive Perception (\d+)$')

	CR_RE = re.compile(r'^([\d/]+)')

	HIT_RE = re.compile('\+(\d+) to hit')
	DICE_RE = re.compile(r'\((\d+d\d+(?: [+-] \d+)?(?: plus \d+d\d+)?)\)')
	PLUS_DICE_RE = re.compile(r'plus \d+ \((\d+d\d+(?: [+-] \d+)?)\)')

	SPELL_RE = re.compile(r'/([a-z ]+)/')

	def __init__(self, filename):
		super(FightClubConverter, self).__init__(filename)
		self.sources = []
		self.name = None
		self.xml = ''

	def add_tag(self, tag, value):
		self.xml += '\t\t<%s>%s</%s>\n' % (tag, escape(value), tag)

	def handle_name(self, name):
		self.name = name
		self.add_tag('name', name)

	def handle_source(self, source, page, section):
		source_name = self.SOURCES[source]
		if source_name is not None:
			self.sources.append(source_name)

	def handle_size_type_alignment(self, line):
		(size_type, alignment) = line.split(", ", 1)

		for size_name, size_value in self.SIZES.items():
			if size_type.startswith(size_name + " "):
				self.add_tag('size', size_value)
				size_type = size_type[len(size_name) + 1:]
				break

		self.add_tag('type', ", ".join([size_type] + self.sources))
		self.add_tag('alignment', alignment)

	def handle_armor_class(self, line):
		self.add_tag('ac', line)

	def handle_hit_points(self, line):
		self.add_tag('hp', line.replace(" + ", "+").replace(" - ", "-"))

	def handle_speed(self, line):
		self.add_tag('speed', line)

	def handle_str(self, line):
		(score, modifier) = line.split(' ', 1)
		self.add_tag('str', score)

	def handle_dex(self, line):
		(score, modifier) = line.split(' ', 1)
		self.add_tag('dex', score)

	def handle_con(self, line):
		(score, modifier) = line.split(' ', 1)
		self.add_tag('con', score)

	def handle_int(self, line):
		(score, modifier) = line.split(' ', 1)
		self.add_tag('int', score)

	def handle_wis(self, line):
		(score, modifier) = line.split(' ', 1)
		self.add_tag('wis', score)

	def handle_cha(self, line):
		(score, modifier) = line.split(' ', 1)
		self.add_tag('cha', score)

	def handle_saving_throws(self, line):
		self.add_tag('save', line)

	def handle_skills(self, line):
		self.add_tag('skill', line)

	def handle_damage_vulnerabilities(self, line):
		self.add_tag('vulnerable', line)

	def handle_damage_resistances(self, line):
		self.add_tag('resist', line)

	def handle_damage_immunities(self, line):
		self.add_tag('immune', line)

	def handle_condition_immunities(self, line):
		self.add_tag('conditionImmune', line)

	def handle_senses(self, line):
		match = self.PP_RE.match(line)
		if match is None:
			raise self.error("Senses line didn't have passive Perception")

		(senses, passive) = match.groups()
		if senses is not None:
			self.add_tag('senses', senses)
		self.add_tag('passive', passive)

	def handle_languages(self, line):
		if line != "-":
			self.add_tag('languages', line)

	def handle_challenge(self, line):
		match = self.CR_RE.match(line)
		if match is None:
			raise self.error("Challenge line didn't have CR")

		(cr,) = match.groups()
		self.add_tag('cr', cr)

	def add_action(self, tag, name, lines, with_attack=True):
		attack_hit = None
		attack_dice = None
		attack_plus_dice = None

		name = name.rstrip('.')
		name = name.replace('–', '-')

		self.xml += '\t\t<%s>\n' % escape(tag)
		self.xml += '\t\t\t<name>%s</name>\n' % escape(name)
		for line in lines:
			line = self.SPELL_RE.sub(r'\1', line)
			self.xml += '\t\t\t<text>%s</text>\n' % escape(line)

			if attack_hit is None:
				match = self.HIT_RE.search(line)
				if match is not None:
					attack_hit = match.groups()[0]
			if attack_dice is None:
				match = self.DICE_RE.search(line)
				if match is not None:
					attack_dice = match.groups()[0].replace(" plus ", "+").replace(" ", "")
			if attack_plus_dice is None:
				match = self.PLUS_DICE_RE.search(line)
				if match is not None:
					attack_plus_dice = match.groups()[0].replace(" ", "")

		if with_attack and (attack_hit is not None or attack_dice is not None):
			attack_name = name
			if " (" in attack_name:
				attack_name = attack_name[:attack_name.index(" (")]

			if attack_dice is not None and attack_plus_dice is not None:
				attack_dice += '+%s' % attack_plus_dice

			self.xml += '\t\t\t<attack>%s|%s|%s</attack>\n' % (escape(attack_name), escape(attack_hit or ''), escape(attack_dice or ''))
		self.xml += '\t\t</%s>\n' % escape(tag)

	def handle_traits(self, traits):
		for name, lines in traits:
			self.add_action('trait', name, lines)

	def handle_actions(self, actions):
		for name, lines in actions:
			self.add_action('action', name, lines)

	def handle_reactions(self, reactions):
		for name, lines in reactions:
			self.add_action('reaction', name, lines, with_attack=False)

	def handle_legendary_actions(self, lines, actions):
		for name, lines in actions:
			self.add_action('legendary', name, lines, with_attack=False)

def main():
	monsters = []
	for filename in monster.local_files():
		parser = FightClubConverter(filename)
		try:
			try:
				parser.parse()
				monsters.append((parser.name, parser.xml))
			except monster.ParseException, e:
				print >>sys.stderr, "%s:%d:%s" % (e.filename, e.lineno, e.message)
				sys.exit(1)
		finally:
			parser.close()

	print '<?xml version="1.0" encoding="UTF-8"?>'
	print '<compendium version="5">'
	for name, xml in sorted(monsters):
		print '\t<monster>'
		print xml,
		print '\t</monster>'
	print '</compendium>'


if __name__ == "__main__":
	main()

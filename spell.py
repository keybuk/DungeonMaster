#!/usr/bin/env python
# -*- coding: utf8 -*-

import re

import base

SOURCE_RE = re.compile(r'^([a-z]+) (\d+)(?:; (.*))?$')
CLASSES = [ "barbarian", "bard", "cleric", "druid", "fighter", "monk", "paladin", "ranger",
			"rogue", "sorcerer", "warlock", "wizard" ]

class SpellParser(base.Parser):
	def parse(self):
		line = self.next_line(error_message="Expected name")
		self.handle_name(line)

		while True:
			line = self.next_line(error_message="Expected source, or other metadata")

			match = SOURCE_RE.match(line)
			if line.startswith("was "):
				self.handle_old_name(line[4:])
			elif line in CLASSES:
				self.handle_class(line)
			elif match is not None:
				(source, page, section) = match.groups()
				self.handle_source(source, int(page), section)
			else:
				break

		self.handle_level_school(line)

		self.blank_line(error_message="Expected blank line after header")

		lines = {
			"Casting Time:": self.handle_casting_time,
			"Range:": self.handle_range,
			"Components:": self.handle_components,
			"Duration:": self.handle_duration,
		}
		self.label_block(lines, all=True)

		lines = self.parse_all_lines()
		self.handle_description(lines)

	def handle_name(self, name):
		pass

	def handle_old_name(self, name):
		pass

	def handle_source(self, source, page, section):
		pass

	def handle_class(self, character_class):
		pass

	def handle_level_school(self, line):
		pass

	def handle_casting_time(self, line):
		pass

	def handle_range(self, line):
		pass

	def handle_components(self, line):
		pass

	def handle_duration(self, line):
		pass

	def handle_description(self, lines):
		pass


SCHOOLS = [ "abjuration", "conjuration", "divination", "enchantment", "evocation", "illusion",
			"necromancy", "transmutation" ]

schools_expr = "|".join(SCHOOLS)
schools_title_expr = "|".join(school.title() for school in SCHOOLS)

LEVEL_SCHOOL_RE = re.compile(
	r'^(?:(\d+)(?:st|nd|rd|th)-level (' + schools_expr + r')(?: \((ritual)\))?' +
	r'|(' + schools_title_expr + r') cantrip)$'
	)

CASTING_TIME_RE = re.compile(
	r'^(?:1 (?:(action)(?: or (\d+) (minutes?|hours?))?|(bonus action)|(reaction), which you take (.*))' +
	r'|(\d+) (minutes?|hours?))$'
	)

RANGE_RE = re.compile(
	r'^(?:(\d+) (feet|miles?)' +
	r'|(Self)(?: \((\d+)-(foot|mile)( radius| line| cone| cube|-radius sphere|-radius hemisphere)\))?' +
	r'|(Special)|(Touch)|(Sight)|(Unlimited))$'
	)

COMPONENTS_RE = re.compile(
	r'^(?=.)(?:(V)(?:, |$))?(?:(S)(?:, |$))?(?:M \(([^\)]*)\))?$'
	)

DURATION_RE = re.compile(
	r'^(?:(?:(Concentration,? up to )|(Up to ))?(\d+|one) (rounds?|minutes?|hours?|days?)\.?' +
	r'|(Instantaneous)|(Special)|Until (dispelled)( or triggered)?)$'
	)

class SpellExporter(SpellParser):

	def __init__(self, filename, bookTags):
		super(SpellExporter, self).__init__(filename)
		self.bookTags = bookTags

		self.name = None
		self.names = []
		self.sources = []
		self.classes = []
		self.info = {}

	def object(self):
		if len(self.sources) == 0:
			raise self.error("No sources for this spell")

		object = {
			"name": unicode(self.name, 'utf8'),
			"names": self.names,
			"sources": self.sources,
			"classes": self.classes,
			"info": self.info,
		}

		return object

	def handle_name(self, name):
		self.name = name
		self.names.append(unicode(name, 'utf8'))

	def handle_old_name(self, name):
		self.names.append(unicode(name, 'utf8'))

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

	def handle_class(self, character_class):
		try:
			index = CLASSES.index(character_class)
		except ValueError:
			raise self.error("Unknown class: %s" % character_class)

		self.classes.append(index)

	def handle_level_school(self, line):
		match = LEVEL_SCHOOL_RE.match(line)
		if match is None:
			raise self.error("Level/School didn't match expected format: %s" % line)

		(level, school, ritual, cantrip_school) = match.groups()

		if level is not None:
			self.info['rawLevel'] = int(level)
			self.info['rawSchool'] = SCHOOLS.index(school)
		else:
			self.info['rawLevel'] = 0
			self.info['rawSchool'] = SCHOOLS.index(cantrip_school.lower())

		if ritual is not None:
			self.info['canCastAsRitual'] = True

	def handle_casting_time(self, line):
		match = CASTING_TIME_RE.match(line)
		if match is None:
			raise self.error("Casting Time didn't match expected format: %s" % line)

		(action, action_alt_time, action_alt_unit, bonus_action, reaction, reaction_clause,
		 time, unit) = match.groups()

		if action is not None:
			self.info['canCastAsAction'] = True

			if action_alt_unit == 'hour' or action_alt_unit == 'hours':
				self.info['rawCastingTime'] = int(action_alt_time) * 60
			elif action_alt_unit == 'minute' or action_alt_unit == 'minutes':
				self.info['rawCastingTime'] = int(action_alt_unit)

		elif bonus_action is not None:
			self.info['canCastAsBonusAction'] = True

		elif reaction is not None:
			self.info['canCastAsReaction'] = True
			self.info['reactionResponse'] = unicode(reaction_clause, 'utf8')

		elif unit == 'hour' or unit == 'hours':
			self.info['rawCastingTime'] = int(time) * 60

		elif unit == 'minute' or unit == 'minutes':
			self.info['rawCastingTime'] = int(time)

	def handle_range(self, line):
		match = RANGE_RE.match(line)
		if match is None:
			raise self.error("Range didn't match expected format: %s" % line)

		(distance, unit, range_self, self_distance, self_unit, self_shape,
		 special, touch, sight, unlimited) = match.groups()

		if range_self is not None:
			self.info['rawRange'] = 1

			if self_unit == 'mile':
				self.info['rawRangeDistance'] = int(self_distance) * 5280
			elif self_unit == 'foot':
				self.info['rawRangeDistance'] = int(self_distance)

			if self_shape == ' radius':
				self.info['rawRangeShape'] = 0
			elif self_shape == '-radius sphere':
				self.info['rawRangeShape'] = 1
			elif self_shape == '-radius hemisphere':
				self.info['rawRangeShape'] = 2
			elif self_shape == ' cube':
				self.info['rawRangeShape'] = 3
			elif self_shape == ' cone':
				self.info['rawRangeShape'] = 4
			elif self_shape == ' line':
				self.info['rawRangeShape'] = 5

		elif touch is not None:
			self.info['rawRange'] = 2
		elif sight is not None:
			self.info['rawRange'] = 3
		elif special is not None:
			self.info['rawRange'] = 4
		elif unlimited is not None:
			self.info['rawRange'] = 5
		else:
			self.info['rawRange'] = 0
			if unit == 'mile' or unit == 'miles':
				self.info['rawRangeDistance'] = int(distance) * 5280
			elif unit == 'feet':
				self.info['rawRangeDistance'] = int(distance)

	def handle_components(self, line):
		match = COMPONENTS_RE.match(line)
		if match is None:
			raise self.error("Components didn't match expected format: %s" % line)

		(verbal, somatic, materials) = match.groups()

		if verbal is not None:
			self.info['hasVerbalComponent'] = True
		if somatic is not None:
			self.info['hasSomaticComponent'] = True
		if materials is not None:
			self.info['hasMaterialComponent'] = True
			self.info['materialComponent'] = unicode(materials, 'utf8')

	def handle_duration(self, line):
		match = DURATION_RE.match(line)
		if match is None:
			raise self.error("Duration didn't match expected format: %s" % line)

		(concentration, max_time, time, unit,
		 instantaneous, special, dispelled, or_triggered) = match.groups()

		if special:
			self.info['rawDuration'] = 7
		elif or_triggered:
			self.info['rawDuration'] = 6
		elif dispelled:
			self.info['rawDuration'] = 5
		elif instantaneous:
			self.info['rawDuration'] = 0
		elif concentration or max_time:
			if concentration:
				self.info['requiresConcentration'] = True
			self.info['rawDuration'] = 2
		else:
			self.info['rawDuration'] = 1

		if time == "one":
			time = "1"

		if unit == 'round' or unit == 'rounds':
			if concentration or max_time:
				self.info['rawDuration'] = 4
			else:
				self.info['rawDuration'] = 3
			self.info['rawDurationTime'] = int(time)
		elif unit == 'day' or unit == 'days':
			self.info['rawDurationTime'] = int(time) * 60 * 24
		elif unit == 'hour' or unit == 'hours':
			self.info['rawDurationTime'] = int(time) * 60
		elif unit == 'minute' or unit == 'minutes':
			self.info['rawDurationTime'] = int(time)

	def handle_description(self, lines):
		text = "\n".join(lines)

		self.info['text'] = unicode(text, 'utf8')

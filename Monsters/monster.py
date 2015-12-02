#!/usr/bin/env python
# -*- coding: utf8 -*-

import os
import sys

class ParseException(Exception):
	def __init__(self, filename, lineno, *args):
		super(ParseException, self).__init__(*args)
		self.filename = filename
		self.lineno = lineno


class MonsterParser(object):
	def __init__(self, filename):
		self.filename = filename
		self.file = None
		self.file = open(filename)
		self.lineno = 0

	def __del__(self):
		if self.file is not None:
			self.close()

	def close(self):
		self.file.close()
		self.file = None

	def error(self, *args):
		return ParseException(self.filename, self.lineno, *args)

	def parse(self):
		line = self.next_line(error_message="Expected name")
		self.handle_name(line)

		line = self.next_line(error_message="Expected sources")
		self.handle_sources(line)

		line = self.next_line(error_message="Expected size, type, and alignment")
		self.handle_size_type_alignment(line)

		self.blank_line(error_message="Expected blank line after header")

		lines = {
			"Armor Class": self.handle_armor_class,
			"Hit Points": self.handle_hit_points,
			"Speed": self.handle_speed,
		}
		self.label_block(lines, all=True)

		lines = {
			"STR": self.handle_str,
			"DEX": self.handle_dex,
			"CON": self.handle_con,
			"INT": self.handle_int,
			"WIS": self.handle_wis,
			"CHA": self.handle_cha,
		}
		self.label_block(lines, all=True)

		lines = {
			"Saving Throws": self.handle_saving_throws,
			"Skills": self.handle_skills,
			"Damage Vulnerabilities": self.handle_damage_vulnerabilities,
			"Damage Resistances": self.handle_damage_resistances,
			"Damage Resistance": self.handle_damage_resistances, # Appears in Archmage
			"Damage Immunities": self.handle_damage_immunities,
			"Condition Immunities": self.handle_condition_immunities,
			"Senses": self.handle_senses,
			"Languages": self.handle_languages,
			"Challenge": self.handle_challenge,
		}
		self.label_block(lines, all=False)

		# Parse the common set of traits, actions, reactions, and legendary actions
		handler = self.handle_traits
		intro_lines = None
		entries = []
		while True:
			line = self.next_line()
			if line is not None and line.endswith("."):
				title = line
				lines = self.parse_lines()

				entries.append((title, lines))
				continue

			if intro_lines is not None:
				handler(intro_lines, entries)
			else:
				handler(entries)

			intro_lines = None
			entries = []

			if line is None or len(line) == 0:
				self.check_eof()
				return

			if line != line.upper():
				raise self.error("Expected trait, action, or reaction title, or section title")

			section = line
			self.blank_line(error_message="Expected blank line after section title")

			if section == "ACTIONS":
				handler = self.handle_actions
			elif section.startswith("ACTIONS FOR TYPE "): # Yuan-ti Malison
				def local_actions_handler(actions):
					self.handle_yuan_ti_actions(section, actions)
				handler = local_actions_handler
			elif section == "REACTIONS":
				handler = self.handle_reactions
			elif section == "LEGENDARY ACTIONS":
				handler = self.handle_legendary_actions
				intro_lines = self.parse_lines()
			elif section == "LAIR":
				break
			else:
				raise self.error("Unknown section title: %s" % section)

		# Parsing optional lair information.
		# The above block returns at EOF, so we only get here by being in a lair block.
		while True:
			if section == "LAIR":
				lines = self.parse_lines()
				self.handle_lair(lines)
			elif section == "LAIR ACTIONS":
				intro_lines = self.parse_lines()

				lair_actions = []
				while True:
					line = self.next_line()
					if line is not None and line.startswith("• "):
						lair_action = [ line ]
						lair_action += self.parse_lines()
						lair_actions.append(lair_action)
					else:
						break

				# This monster has limiting text to its lair actions:
				limiting_lines = None
				if line is not None and line != line.upper():
					limiting_lines = self.parse_lines()
					line = None

				self.handle_lair_actions(intro_lines, lair_actions, limiting_lines)

				# We may have just parsed the next section title, so skip the EOF checking.
				if line is not None:
					section = line
					self.blank_line(error_message="Expected blank line after section title")
					continue
			elif section == "LAIR TRAITS":
				intro_lines = self.parse_lines()

				lair_traits = []
				while True:
					line = self.next_line()
					if line is not None and line.startswith("• "):
						lair_trait = [ line ]
						lair_trait += self.parse_lines()
						lair_traits.append(lair_trait)
					else:
						break

				duration_lines = [ line ]
				duration_lines += self.parse_lines()

				self.handle_lair_traits(intro_lines, lair_traits, duration_lines)
			elif section == "REGIONAL EFFECTS":
				intro_lines = self.parse_lines()

				regional_effects = []
				while True:
					line = self.next_line()
					if line is not None and line.startswith("• "):
						regional_effect = [ line ]
						regional_effect += self.parse_lines()
						regional_effects.append(regional_effect)
					else:
						break

				duration_lines = [ line ]
				duration_lines += self.parse_lines()

				self.handle_regional_effects(intro_lines, regional_effects, duration_lines)
			else:
				raise self.error("Unknown section title: %s" % section)

			line = self.next_line()
			if line is None or len(line) == 0:
				self.check_eof()
				return

			section = line
			self.blank_line(error_message="Expected blank line after section title")


	def next_line(self, error_message=None):
		line = self.file.readline()
		if len(line):
			self.lineno += 1
			return line.rstrip("\r\n")
		elif error_message is not None:
			raise self.error(error)
		else:
			return None

	def blank_line(self, error_message=None):
		line = self.next_line()
		if line is None or len(line) > 0:
			raise self.error(error_message or "Expected blank line")

	def check_eof(self):
		while True:
			line = self.next_line()
			if line is not None and len(line) > 0:
				raise self.error("Expected no more text before EOF")
			elif line is None:
				break

	def parse_lines(self):
		lines = []
		while True:
			line = self.next_line()
			if line is None or len(line) == 0:
				break
			lines.append(line)

		return lines

	def label_block(self, lines, all=False):
		while True:
			line = self.next_line()
			if line is None or len(line) == 0:
				break

			for (prefix, handler) in lines.items():
				if line.startswith(prefix + " "):
					handler(line[len(prefix) + 1:])
					del lines[prefix]
					break
			else:
				raise self.error("Expected one of %s" % ", ".join(sorted(lines.keys())))

		if len(lines) and all:
			raise self.error("Expected each of %s in block" % ", ".join(sorted(lines.keys())))


	def handle_name(self, name):
		pass

	def handle_sources(self, line):
		for source_text in line.split("|"):
			section = None
			if "; " in source_text:
				(source_text, section) = source_text.split("; ", 1)
			(source, page) = source_text.split(" ", 1)
			page = int(page)

			self.handle_source(source, page, section)

	def handle_source(self, source, page, section):
		pass

	def handle_size_type_alignment(self, line):
		pass

	def handle_armor_class(self, line):
		pass

	def handle_hit_points(self, line):
		pass

	def handle_speed(self, line):
		pass

	def handle_str(self, line):
		pass

	def handle_dex(self, line):
		pass

	def handle_con(self, line):
		pass

	def handle_int(self, line):
		pass

	def handle_wis(self, line):
		pass

	def handle_cha(self, line):
		pass

	def handle_saving_throws(self, line):
		pass

	def handle_skills(self, line):
		pass

	def handle_damage_vulnerabilities(self, line):
		pass

	def handle_damage_resistances(self, line):
		pass

	def handle_damage_immunities(self, line):
		pass

	def handle_condition_immunities(self, line):
		pass

	def handle_senses(self, line):
		pass

	def handle_languages(self, line):
		pass

	def handle_challenge(self, line):
		pass

	def handle_traits(self, traits):
		pass

	def handle_actions(self, actions):
		pass

	def handle_yuan_ti_actions(self, section, actions):
		pass

	def handle_reactions(self, reactions):
		pass

	def handle_legendary_actions(self, lines, actions):
		pass

	def handle_lair(self, lines):
		pass

	def handle_lair_actions(self, intro_lines, lair_actions, limiting_lines):
		pass

	def handle_lair_traits(self, intro_lines, lair_traits, duration_lines):
		pass

	def handle_regional_effects(self, intro_lines, regional_effects, duration_lines):
		pass


def local_files():
	files = sys.argv[1:]
	if not len(files):
		basedir = os.path.dirname(sys.argv[0])
		for subdir in os.listdir(basedir):
			subdir = os.path.join(basedir, subdir)
			if not os.path.isdir(subdir):
				continue

			filenames = [ os.path.join(subdir, filename) for filename in os.listdir(subdir) ]
			files += filenames

	return files

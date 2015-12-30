#!/usr/bin/env python
# -*- coding: utf8 -*-

import re

import base

SOURCE_RE = re.compile(r'^([a-z]+) (\d+)(?:; (.*))?$')

class SpellParser(base.Parser):
	def parse(self):
		line = self.next_line(error_message="Expected name")
		self.handle_name(line)

		while True:
			line = self.next_line(error_message="Expected source, or other metadata")

			match = SOURCE_RE.match(line)
			if line.startswith("was "):
				self.handle_old_name(line[4:])
			elif match is not None:
				(source, page, section) = match.groups()
				self.handle_source(source, int(page), section)
			else:
				break

	def handle_name(self, name):
		pass

	def handle_old_name(self, name):
		pass

	def handle_source(self, source, page, section):
		pass


class SpellExporter(SpellParser):

	def __init__(self, filename, bookTags):
		super(SpellExporter, self).__init__(filename)
		self.bookTags = bookTags

		self.name = None
		self.names = []
		self.sources = []

	def object(self):
		object = {
			"name": unicode(self.name, 'utf8'),
			"names": self.names,
			"sources": self.sources,
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


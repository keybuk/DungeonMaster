#!/usr/bin/env python
# -*- coding: utf8 -*-

import os
import sys

class ParseException(Exception):
	def __init__(self, filename, lineno, *args):
		super(ParseException, self).__init__(*args)
		self.filename = filename
		self.lineno = lineno

class Parser(object):
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

	def next_line(self, error_message=None):
		line = self.file.readline()
		if len(line):
			self.lineno += 1
			line = line.rstrip("\r\n")
			# Any line beginning with // can be ignored as a comment.
			if line.startswith("//"):
				return self.next_line(error_message=error_message)
			self.check_line(line)
			return line
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

	def parse_all_lines(self):
		lines = []
		while True:
			line = self.next_line()
			if line is None:
				break
			lines.append(line)

		if lines[-1] == "":
			raise self.error("Blank line at end of file")

		return lines

	def check_line(self, line):
		pass

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


def local_files(file_type):
	files = sys.argv[1:]
	if not len(files):
		basedir = os.path.join(os.path.dirname(sys.argv[0]), file_type)
		for subdir in os.listdir(basedir):
			subdir = os.path.join(basedir, subdir)
			if not os.path.isdir(subdir):
				continue

			filenames = [ os.path.join(subdir, filename) for filename in os.listdir(subdir) ]
			files += filenames

	return files

#!/usr/bin/env python
# -*- coding: utf8 -*-

import plistlib
import re
import sys
import time

import base
import monster
import spell

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
			"name": "Player's Basic Rules",
			"type": 3,
		},
		{
			"name": "Dungeon Master's Basic Rules",
			"type": 3,
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
			"type": 3,
		},
		{
			"name": "The Rise of Tiamat",
			"type": 1,
		},
		{
			"name": "The Rise of Tiamat Online Supplement",
			"type": 3,
		},
		{
			"name": "Princes of the Apocalypse",
			"type": 1,
		},
		{
			"name": "Princes of the Apocalypse Online Supplement",
			"type": 3,
		},
		{
			"name": "Elemental Evil Player's Companion",
			"type": 3,
		},
		{
			"name": "Out of the Abyss",
			"type": 1,
		},
		{
			"name": "Sword Coast Adventurer's Guide",
			"type": 2,
		},
		{
			"name": "Personal",
			"type": 1
		}
	]
	bookTags = [
		"phb", "mm", "dmg", "pbr",  "dmbr",
		"lmop", "hotdq", "hotdqs", "trot", "trots", "pota", "potas", "eepc", "oota",
		"scag",
		"me" ]

	monsters = []
	for filename in base.local_files('Monsters'):
		parser = monster.MonsterExporter(filename, bookTags=bookTags)
		try:
			try:
				parser.parse()
				monsters.append(parser.object())
			except base.ParseException, e:
				print >>sys.stderr, "%s:%d:%s" % (e.filename, e.lineno, e.message)
		finally:
			parser.close()

	spells = []
	for filename in base.local_files('Spells'):
		parser = spell.SpellExporter(filename, bookTags=bookTags)
		try:
			try:
				parser.parse()
				spells.append(parser.object())
			except base.ParseException, e:
				print >>sys.stderr, "%s:%d:%s" % (e.filename, e.lineno, e.message)
		finally:
			parser.close()

	rootObject = {
		"books": books,
		"monsters": monsters,
		"spells": spells,
		"version": int(time.mktime(time.gmtime())),
	}

	print plistlib.writePlistToString(rootObject)

if __name__ == "__main__":
	main()

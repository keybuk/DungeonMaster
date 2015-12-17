//
//  Enums.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation

/// BookType categorises D&D source material into one of the following:
///  - **CoreRulebook**: the three core rulebooks: Player's Handbook, Monster Manual, and Dungeon Master's Guide.
///  - **OfficialAdventure**: an official adventure published by Wizards of the Coast, e.g. Princes of the Apocalypse.
///  - **OnlineSupplement**: freely published online supplements to core rulebooks and official adventures, including the basic rules.
enum BookType: Int {
    case CoreRulebook
    case OfficialAdventure
    case OnlineSupplement
    // TODO: category for Sword Coast Adventures? official expansion or core rulebook?
    // TODO: category for Unearthed Arcana?
}

/// Size categorises the different range of monster sizes.
enum Size: Int {
    case Tiny
    case Small
    case Medium
    case Large
    case Huge
    case Gargantuan
    
    /// Returns the string equivalent of the size.
    var stringValue: String {
        return sharedRules.sizes[rawValue]
    }
    
    /// Returns the space in feet occupied by creatures of this type.
    var space: Float {
        return sharedRules.sizeSpace[rawValue]
    }
    
    /// Returns the number of sides for the hit dice used to calculate hit points of creatures of this type.
    var hitDiceSides: Int {
        return sharedRules.sizeHitDiceSides[rawValue]
    }
}

/// MonsterType categorises the different types of monsters.
enum MonsterType: Int {
    case Aberration
    case Beast
    case Celestial
    case Construct
    case Dragon
    case Elemental
    case Fey
    case Fiend
    case Giant
    case Humanoid
    case Monstrosity
    case Ooze
    case Plant
    case Undead
    
    /// Returns the string equivalent of the monster type.
    var stringValue: String {
        return sharedRules.monsterTypes[rawValue]
    }
}

enum Environment {
    case Arctic
    case Coastal
    case Desert
    case Forest
    case Grassland
    case Hill
    case Mountain
    case Swamp
    case Underdark
    case Underwater
    case Urban
}

/// Alignment categorises the different alignments of monsters.
///
/// Only the specific alignments are contained within this enum, a creature with no alignment should have an optional alignment with a nil value.
enum Alignment: Int {
    case LawfulGood
    case LawfulNeutral
    case LawfulEvil
    case NeutralGood
    case Neutral
    case NeutralEvil
    case ChaoticGood
    case ChaoticNeutral
    case ChaoticEvil
    
    /// Returns the string equivalent of the alignment.
    var stringValue: String {
        return sharedRules.alignments[rawValue]
    }
    
    /// Returns a set of all alignments.
    static var allAlignments: Set<Alignment> {
        return [ .LawfulGood, .LawfulNeutral, .LawfulEvil, .NeutralGood, .Neutral, .NeutralEvil, .ChaoticGood, .ChaoticNeutral, .ChaoticEvil ]
    }
    
    /// Returns a set of all lawful alignments.
    static var lawfulAlignments: Set<Alignment> {
        return [ .LawfulGood, .LawfulNeutral, .LawfulEvil ]
    }

    /// Returns a set of all choatic alignments.
    static var chaoticAlignments: Set<Alignment> {
        return [ .ChaoticGood, .ChaoticNeutral, .ChaoticEvil ]
    }
    
    /// Returns a set of all good alignments.
    static var goodAlignments: Set<Alignment> {
        return [ .LawfulGood, .NeutralGood, .ChaoticGood ]
    }

    /// Returns a set of all evil alignments.
    static var evilAlignments: Set<Alignment> {
        return [ .LawfulEvil, .NeutralEvil, .ChaoticEvil ]
    }
}

enum Armor {
    // Light Armor
    case Padded
    case Leather
    case StuddedLeather
    
    // Medium Armor
    case Hide
    case ChainShirt
    case ScaleMail
    case Breastplate
    case HalfPlate
    
    // Heavy Armor
    case RingMail
    case ChainMail
    case Splint
    case Plate
    
    // Shield
    case Shield
}

enum DamageType: String {
    case Acid = "acid"
    case Bludgeoning = "bludgeoning"
    case Cold = "cold"
    case Fire = "fire"
    case Force = "force"
    case Lightning = "lightning"
    case Necrotic = "necrotic"
    case Piercing = "piercing"
    case Poison = "poison"
    case Psychic = "psychic"
    case Radiant = "radiant"
    case Slashing = "slashing"
    case Thunder = "thunder"
}

enum ConditionType: String {
    // TODO: deal with exhaustion, and its six levels
    case Blinded = "blinded"
    case Charmed = "charmed"
    case Deafened = "deafened"
    case Frightened = "frightened"
    case Grappled = "grappled"
    case Incapacitated = "incapacitated"
    case Invisible = "invisible"
    case Paralyzed = "paralyzed"
    case Petrified = "petrified"
    case Poisoned = "poisoned"
    case Prone = "prone"
    case Restrained = "restrained"
    case Stunned = "stunned"
    case Unconcious = "unconcious"
}

enum Language {
    // Standard Languages
    case Common
    case Dwarvish
    case Elvish
    case Giant
    case Gnomish
    case Goblin
    case Halfling
    case Orc
    
    // Exotic Languages
    case Abyssal
    case Celestial
    case Draconic
    case DeepSpeech
    case Infernal
    case Primordial
    case Sylvan
    case Undercommon
    
    // Primordial Dialects
    case Auran
    case Aquan
    case Ignan
    case Terran
}

enum MagicSchool {
    case Abjuration
    case Conjuration
    case Divination
    case Enchantment
    case Evocation
    case Illusion
    case Necromancy
    case Transmutation
}

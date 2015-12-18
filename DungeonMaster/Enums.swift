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
    
    /// Returns the string equivalent of the book type.
    var stringValue: String {
        return sharedRules.bookType[rawValue]
    }
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
        return sharedRules.size[rawValue]
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
        return sharedRules.monsterType[rawValue]
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
enum Alignment: Int {
    case Unaligned
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
        return sharedRules.alignment[rawValue]
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

/// Armor that can be worn by players and monsters.
enum ArmorType: Int {
    case None
    case Natural

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
    
    // Monster-specific Armor.
    case Scraps
    case BardingScraps
    case Patchwork
    
    /// Returns the string equivalent of the armor.
    var stringValue: String {
        return sharedRules.armorType[rawValue]
    }
    
    /// Returns the base armor class for the armor.
    ///
    /// When this returns nil, it's up to the monster designer to decide the base AC.
    var armorClass: Int? {
        return sharedRules.armorClass[rawValue]
    }
    
    /// Returns whether the monster should add its Dexterity modifier to the armor class. and maximum value for that if appropriate.
    var addDexterityModifier: (add: Bool, max: Int?) {
        return sharedRules.armorDexterityModifierMax[rawValue]
    }
    
    /// Returns the minimum strength requirement for the armor.
    ///
    /// When this is not nil, and the monster does not have a strength equal or greater to the returned score, the monster's speed is reduced by 10 feet.
    var minimumStrength: Int? {
        return sharedRules.armorMinimumStrength[rawValue]
    }
    
    /// Returns whether stealth checks for monsters wearing this armor should have disadvantage.
    var stealthDisadvantage: Bool {
        return sharedRules.armorStealthDisadvantage[rawValue]
    }
}

/// Types of damage that can be dealt by attacks.
enum DamageType: Int {
    case Acid
    case Bludgeoning
    case Cold
    case Fire
    case Force
    case Lightning
    case Necrotic
    case Piercing
    case Poison
    case Psychic
    case Radiant
    case Slashing
    case Thunder
    
    /// Returns the string equivalent of the damage type.
    var stringValue: String {
        return sharedRules.damageType[rawValue]
    }
}

enum ConditionType: Int {
    // TODO: deal with exhaustion, and its six levels
    case Blinded
    case Charmed
    case Deafened
    case Frightened
    case Grappled
    case Incapacitated
    case Invisible
    case Paralyzed
    case Petrified
    case Poisoned
    case Prone
    case Restrained
    case Stunned
    case Unconcious
    
    /// Returns the string equivalent of the condition.
    var stringValue: String {
        return sharedRules.conditionType[rawValue]
    }
    
    /// Returns an array of rules texts for the condition.
    var rulesDescription: [String] {
        return sharedRules.conditionDescription[rawValue]
    }
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

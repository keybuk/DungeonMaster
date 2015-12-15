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
enum BookType: Int16 {
    case CoreRulebook
    case OfficialAdventure
    case OnlineSupplement
    // TODO: category for Sword Coast Adventures? official expansion or core rulebook?
    // TODO: category for Unearthed Arcana?
}

enum Size: String {
    case Tiny
    case Small
    case Medium
    case Large
    case Huge
    case Gargantuan
}

enum Alignment: String {
    case Unaligned = "unaligned"
    case LawfulGood = "lawful good"
    case LawfulNeutral = "lawful neutral"
    case LawfulEvil = "lawful evil"
    case NeutralGood = "neutral good"
    case Neutral = "neutral"
    case NeutralEvil = "neutral evil"
    case ChaoticGood = "chaotic good"
    case ChaoticNeutral = "chaotic neutral"
    case ChaoticEvil = "chaotic evil"
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

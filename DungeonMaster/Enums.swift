//
//  Enums.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation

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

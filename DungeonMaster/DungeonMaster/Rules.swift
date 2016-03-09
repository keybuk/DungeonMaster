//
//  Rules.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/17/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation

/// Decodes the data from the Rules plist into useful forms for quick access.
struct Rules {
    
    let data: NSDictionary

    init() {
        let filename = NSBundle.mainBundle().pathForResource("Rules", ofType: "plist")!
        data = NSDictionary(contentsOfFile: filename)!
    }
    
    /// Array of book type names.
    var bookType: [String] {
        return data["bookType"]! as! [String]
    }
    
    /// Array of ability names.
    var ability: [String] {
        return data["ability"]! as! [String]
    }
    
    /// Array of skill names.
    var skill: [[String]] {
        return data["skill"]! as! [[String]]
    }

    /// Array of size names.
    var size: [String] {
        return data["size"]! as! [String]
    }
    
    /// Array, index matching sizes, of grid space required in feet.
    var sizeSpace: [Float] {
        return (data["sizeSpace"]! as! [NSNumber]).map { $0.floatValue }
    }
    
    /// Array, index matching sizes, of hit dice sides to calculate hit points.
    var sizeHitDiceSides: [Int] {
        return (data["sizeHitDiceSides"]! as! [NSNumber]).map { $0.integerValue }
    }
    
    /// Array of alignment names.
    var alignment: [String] {
        return data["alignment"]! as! [String]
    }
    
    /// Array of monster type names.
    var monsterType: [String] {
        return data["monsterType"]! as! [String]
    }
    
    /// Array of environments.
    var environment: [String] {
        return data["environment"]! as! [String]
    }
    
    /// Array of player race names.
    var race: [String] {
        return data["race"]! as! [String]
    }
    
    /// Array of player subrace names.
    var subrace: [[String]] {
        return data["subrace"]! as! [[String]]
    }
    
    /// Array mapping races to sizes.
    var raceSize: [Int] {
        return (data["raceSize"]! as! [NSNumber]).map { $0.integerValue }
    }
    
    /// Array of character class names.
    var characterClass: [String] {
        return data["characterClass"]! as! [String]
    }
    
    /// Array of character background names.
    var background: [String] {
        return data["background"]! as! [String]
    }

    /// Dictionary mapping level to XP threshold for obtaining that level.
    var levelXP: [Int: Int] {
        var result: [Int: Int] = [:]
        for (level, xp) in data["levelXP"]! as! [String: NSNumber] {
            result[Int(level)!] = xp.integerValue
        }
        return result
    }
    
    /// Dictionary mapping level for encounter difficulty thresholds.
    var levelXPThreshold: [Int: [Int]] {
        var result: [Int: [Int]] = [:]
        for (level, thresholds) in data["levelXPThreshold"]! as! [String: [NSNumber]] {
            
            result[Int(level)!] = thresholds.map({ $0.integerValue })
        }
        return result
    }

    /// Array of armor type names.
    var armorType: [String] {
        return data["armorType"]! as! [String]
    }
    
    /// Array of base armor class for each armor type.
    var armorClass: [Int?] {
        return (data["armorClass"]! as! [NSNumber]).map {
            $0.integerValue > 0 ? $0.integerValue : nil
        }
    }
    
    /// Array of dexterity modifiers for each armor type.
    ///
    /// The first value in the tuple, `add`, indicates whether the dexterity modifier should be applied; the second, `max` indicates a maximum value if appropriate.
    var armorDexterityModifierMax: [(add: Bool, max: Int?)] {
        return (data["armorDexterityModifierMax"]! as! [NSNumber]).map { 
            switch $0.integerValue {
            case 0:
                return (false, nil)
            case 10:
                return (true, nil)
            default:
                return (true, $0.integerValue)
            }
        }
    }
    
    /// Array of minimum strength requirements for each armor type.
    var armorMinimumStrength: [Int?] {
        return (data["armorMinimumStrength"]! as! [NSNumber]).map {
            $0.integerValue > 0 ? $0.integerValue : nil
        }
    }
    
    /// Array mapping whether each armor type confers a disadvantage to stealth checks.
    var armorStealthDisadvantage: [Bool] {
        return (data["armorStealthDisadvantage"]! as! [NSNumber]).map { $0.boolValue }
    }

    /// Array of damage type names.
    var damageType: [String] {
        return data["damageType"]! as! [String]
    }

    /// Array of condition names.
    var condition: [String] {
        return data["condition"]! as! [String]
    }

    /// Array of condition rules texts.
    var conditionDescription: [[String]] {
        return data["conditionDescription"]! as! [[String]]
    }
    
    /// Array of magic school names.
    var magicSchool: [String] {
        return data["magicSchool"]! as! [String]
    }
    
    /// Dictionary mapping challenge rating to XP earned for defeating a monster of that rating.
    var challengeXP: [NSDecimalNumber: Int] {
        var result: [NSDecimalNumber: Int] = [:]
        for (challenge, xp) in data["challengeXP"]! as! [String: NSNumber] {
            result[NSDecimalNumber(string: challenge)] = xp.integerValue
        }
        return result
    }
    
    /// Dictionary mapping challenge rating to monster's proficiency bonus in a given ability or skill.
    var challengeProficiencyBonus: [NSDecimalNumber: Int] {
        var result: [NSDecimalNumber: Int] = [:]
        for (challenge, proficiencyBonus) in data["challengeProficiencyBonus"]! as! [String: NSNumber] {
            result[NSDecimalNumber(string: challenge)] = proficiencyBonus.integerValue
        }
        return result
    }

    /// Reverse-sorted array of tuples mapping number of monsters to XP multiplier for at least that many.
    var monsterXPMultiplier: [(Int, Float)] {
        var result: [(Int, Float)] = []
        for (number, multiplier) in data["monsterXPMultiplier"]! as! [String: NSNumber] {
            result.append((Int(number)!, multiplier.floatValue))
        }
        return result.sort({ $0.0 > $1.0 })
    }

}

let sharedRules = Rules()
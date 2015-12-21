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
    
    // Array of book type names.
    var bookType: [String] {
        return data["bookType"]! as! [String]
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
    
    /// Array of monster type names.
    var monsterType: [String] {
        return data["monsterType"]! as! [String]
    }
    
    /// Array of alignment names.
    var alignment: [String] {
        return data["alignment"]! as! [String]
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
    var conditionType: [String] {
        return data["conditionType"]! as! [String]
    }

    /// Array of condition rules texts.
    var conditionDescription: [[String]] {
        return data["conditionDescription"]! as! [[String]]
    }
    
    /// Dictionary mapping challenge rating to XP earned for defeating a monster of that rating.
    var challengeXP: [NSDecimalNumber: Int] {
        var result = [NSDecimalNumber: Int]()
        for (challenge, xp) in data["challengeXP"]! as! [String: NSNumber] {
            result[NSDecimalNumber(string: challenge)] = xp.integerValue
        }
        return result
    }
    
    /// Dictionary mapping challenge rating to monster's proficiency bonus in a given ability or skill.
    var challengeProficiencyBonus: [NSDecimalNumber: Int] {
        var result = [NSDecimalNumber: Int]()
        for (challenge, proficiencyBonus) in data["challengeProficiencyBonus"]! as! [String: NSNumber] {
            result[NSDecimalNumber(string: challenge)] = proficiencyBonus.integerValue
        }
        return result
    }

}

let sharedRules = Rules()
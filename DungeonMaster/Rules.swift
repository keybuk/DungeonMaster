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
    
    /// Array of size names.
    var sizes: [String] {
        return data["sizes"]! as! [String]
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
    var monsterTypes: [String] {
        return data["monsterTypes"]! as! [String]
    }
    
    /// Array of alignment names.
    var alignments: [String] {
        return data["alignments"]! as! [String]
    }
    
    /// Dictionary mapping condition name to array of rules texts.
    var conditionDescriptions: [String: [String]] {
        return data["conditionDescriptions"]! as! [String: [String]]
    }

}

let sharedRules = Rules()
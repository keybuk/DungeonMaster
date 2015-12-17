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
    
    /// Dictionary mapping condition name to array of rules texts.
    var conditionDescriptions: [String: [String]] {
        return data["conditionDescriptions"]! as! [String: [String]]
    }

}

let sharedRules = Rules()
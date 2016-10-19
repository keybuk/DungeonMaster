//
//  PlayerSavingThrow.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// PlayerSavingThrow represents a saving throw that the player is proficient in.
final class PlayerSavingThrow : NSManagedObject {
    
    /// Player character that this proficiency applies to.
    @NSManaged var player: Player
    
    /// Saving throw that the player is proficient in.
    var savingThrow: Ability {
        get {
            return Ability(rawValue: rawSavingThrow.intValue)!
        }
        set(newSavingThrow) {
            rawSavingThrow = NSNumber(value: newSavingThrow.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawSavingThrow: NSNumber
    
    convenience init(player: Player, savingThrow: Ability, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.PlayerSavingThrow, inManagedObjectContext: context)
        self.init(entity: entity, insertInto: context)
        
        self.player = player
        self.savingThrow = savingThrow
    }
    
}

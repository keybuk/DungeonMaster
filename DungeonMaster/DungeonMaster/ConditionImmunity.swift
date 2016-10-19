//
//  ConditionImmunity.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// ConditionImmunity represents a condition that a monster is immune to.
final class ConditionImmunity : NSManagedObject {
    
    /// Monster that is immune.
    @NSManaged var monster: Monster
    
    /// Condition that the monster is immune to.
    var condition: Condition {
        get {
            return Condition(rawValue: rawCondition.intValue)!
        }
        set(newCondition) {
            rawCondition = NSNumber(value: newCondition.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawCondition: NSNumber
    
    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.ConditionImmunity, inManagedObjectContext: context)
        self.init(entity: entity, insertInto: context)
        
        self.monster = monster
    }
    
}

//
//  CombatantCondition.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class CombatantCondition: NSManagedObject {
    
    @NSManaged var target: Combatant
    
    var type: Condition {
        get {
            return Condition(rawValue: rawType.integerValue)!
        }
        set(newType) {
            rawType = NSNumber(integer: newType.rawValue)
        }
    }
    @NSManaged private var rawType: NSNumber

    convenience init(target: Combatant, type: Condition, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.CombatantCondition, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.target = target
        self.type = type
    }
    
}

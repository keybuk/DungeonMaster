//
//  CombatantCondition.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class CombatantCondition : NSManagedObject {
    
    @NSManaged var target: Combatant
    
    var type: Condition {
        get {
            return Condition(rawValue: rawType.intValue)!
        }
        set(newType) {
            rawType = NSNumber(value: newType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawType: NSNumber

    convenience init(target: Combatant, type: Condition, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.CombatantCondition, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.target = target
        self.type = type
    }
    
}

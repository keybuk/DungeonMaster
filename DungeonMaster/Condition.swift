//
//  Condition.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Condition: NSManagedObject {
    
    @NSManaged var target: Combatant
    
    @NSManaged var typeValue: String
    
    var type: ConditionType {
        get {
            return ConditionType(rawValue: typeValue)!
        }
        set(newType) {
            typeValue = newType.rawValue
        }
    }
    
    convenience init(target: Combatant, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Condition, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.target = target
    }
    
}

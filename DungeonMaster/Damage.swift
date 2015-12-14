//
//  Damage.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Damage: NSManagedObject {
    
    @NSManaged var target: Combatant

    @NSManaged var pointsValue: Int16
    @NSManaged var typeValue: String
    
    var points: Int {
        get {
            return Int(pointsValue)
        }
        set(newPoints) {
            pointsValue = Int16(newPoints)
        }
    }
    
    var type: DamageType {
        get {
            return DamageType(rawValue: typeValue)!
        }
        set(newType) {
            typeValue = newType.rawValue
        }
    }
    
    convenience init(target: Combatant, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Damage, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.target = target
    }
    
}

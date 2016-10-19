//
//  Damage.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class CombatantDamage : NSManagedObject {
    
    @NSManaged var target: Combatant
    
    var points: Int {
        get {
            return rawPoints.intValue
        }
        set(newPoints) {
            rawPoints = NSNumber(value: newPoints as Int)
        }
    }
    @NSManaged fileprivate var rawPoints: NSNumber

    var type: DamageType {
        get {
            return DamageType(rawValue: rawType.intValue)!
        }
        set(newType) {
            rawType = NSNumber(value: newType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawType: NSNumber

    convenience init(target: Combatant, points: Int, type: DamageType, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.CombatantDamage, inManagedObjectContext: context)
        self.init(entity: entity, insertInto: context)
        
        self.target = target
        self.points = points
        self.type = type
    }
    
}

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
            return rawPoints.integerValue
        }
        set(newPoints) {
            rawPoints = NSNumber(integer: newPoints)
        }
    }
    @NSManaged private var rawPoints: NSNumber

    var type: DamageType {
        get {
            return DamageType(rawValue: rawType.integerValue)!
        }
        set(newType) {
            rawType = NSNumber(integer: newType.rawValue)
        }
    }
    @NSManaged private var rawType: NSNumber

    convenience init(target: Combatant, points: Int, type: DamageType, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.CombatantDamage, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.target = target
        self.points = points
        self.type = type
    }
    
}

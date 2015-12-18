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
    
    var points: Int {
        get {
            return Int(rawPoints)
        }
        set(newPoints) {
            rawPoints = Int16(newPoints)
        }
    }
    @NSManaged private var rawPoints: Int16

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
        let entity = NSEntityDescription.entity(Model.Damage, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.target = target
        self.points = points
        self.type = type
    }
    
}

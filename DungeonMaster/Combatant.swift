//
//  Combatant.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Combatant: NSManagedObject {
    
    @NSManaged var encounter: Encounter
    @NSManaged var monster: Monster
    @NSManaged var damage: NSOrderedSet
    @NSManaged var conditions: NSOrderedSet

    @NSManaged var hitPointsValue: Int16
    @NSManaged var damagePointsValue: Int16
    @NSManaged var initiativeValue: NSNumber?
    @NSManaged var notes: String?

    var hitPoints: Int {
        get {
            return Int(hitPointsValue)
        }
        set(newHitPoints) {
            hitPointsValue = Int16(newHitPoints)
        }
    }
    
    var damagePoints: Int {
        get {
            return Int(damagePointsValue)
        }
        set(newDamagePoints) {
            damagePointsValue = Int16(newDamagePoints)
        }
    }
    
    var health: Float {
        return Float(max(hitPoints - damagePoints, 0)) / Float(hitPoints)
    }

    var initiative: Int? {
        get {
            return initiativeValue?.integerValue
        }
        set(newInitiative) {
            initiativeValue = newInitiative != nil ? NSNumber(integer: newInitiative!) : nil
        }
    }
    
    convenience init(encounter: Encounter, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Combatant, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.encounter = encounter
    }
    
}

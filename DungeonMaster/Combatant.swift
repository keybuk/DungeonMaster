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
    @NSManaged var dateCreated: NSDate

    @NSManaged var rawHitPoints: Int16
    @NSManaged var rawDamagePoints: Int16
    @NSManaged var rawInitiative: NSNumber?

    var hitPoints: Int {
        get {
            return Int(rawHitPoints)
        }
        set(newHitPoints) {
            rawHitPoints = Int16(newHitPoints)
        }
    }
    
    var damagePoints: Int {
        get {
            return Int(rawDamagePoints)
        }
        set(newDamagePoints) {
            rawDamagePoints = Int16(newDamagePoints)
        }
    }
    
    var initiative: Int? {
        get {
            return rawInitiative?.integerValue
        }
        set(newInitiative) {
            rawInitiative = newInitiative != nil ? NSNumber(integer: newInitiative!) : nil
        }
    }
    
    @NSManaged var notes: String?

    @NSManaged var damages: NSOrderedSet
    @NSManaged var conditions: NSOrderedSet
    
    var allDamages: [Damage] {
        return damages.array as! [Damage]
    }
    
    var allConditions: [Condition] {
        return conditions.array as! [Condition]
    }

    // MARK: Computed properties

    var health: Float {
        return Float(max(hitPoints - damagePoints, 0)) / Float(hitPoints)
    }

    convenience init(encounter: Encounter, monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Combatant, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.encounter = encounter
        self.monster = monster
        
        dateCreated = NSDate()
        hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
    }
    
}

//
//  DamageResistance.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

/// DamageResistance represents a class of damage and attack that a monster is resistant to.
final class DamageResistance: NSManagedObject {
    
    /// Monster that is resistant.
    @NSManaged var monster: Monster
    
    /// Type of damage that the monster is resistant to.
    var damageType: DamageType {
        get {
            return DamageType(rawValue: rawDamageType.integerValue)!
        }
        set(newDamageType) {
            rawDamageType = NSNumber(integer: newDamageType.rawValue)
        }
    }
    @NSManaged private var rawDamageType: NSNumber
    
    /// Type of attacks that this damage resistance applies to.
    var attackType: AttackType {
        get {
            return AttackType(rawValue: rawAttackType.integerValue)!
        }
        set(newAttackType) {
            rawAttackType = NSNumber(integer: newAttackType.rawValue)
        }
    }
    @NSManaged private var rawAttackType: NSNumber
    
    // HACK for the time being to parse Archmage
    @NSManaged var spellName: String?
    
    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.DamageResistance, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.monster = monster
    }
    
}

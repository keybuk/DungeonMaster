//
//  DamageImmunity.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// DamageImmunity represents a class of damage and attack that a monster is immune to.
final class DamageImmunity : NSManagedObject {
    
    /// Monster that is immune.
    @NSManaged var monster: Monster
    
    /// Type of damage that the monster is immune to.
    var damageType: DamageType {
        get {
            return DamageType(rawValue: rawDamageType.intValue)!
        }
        set(newDamageType) {
            rawDamageType = NSNumber(value: newDamageType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawDamageType: NSNumber
    
    /// Type of attacks that this damage immunity applies to.
    var attackType: AttackType {
        get {
            return AttackType(rawValue: rawAttackType.intValue)!
        }
        set(newAttackType) {
            rawAttackType = NSNumber(value: newAttackType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawAttackType: NSNumber
    
    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.DamageImmunity, inManagedObjectContext: context)
        self.init(entity: entity, insertInto: context)
        
        self.monster = monster
    }
    
}

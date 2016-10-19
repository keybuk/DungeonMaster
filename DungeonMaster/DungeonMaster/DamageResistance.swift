//
//  DamageResistance.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// DamageResistance represents a class of damage and attack that a monster is resistant to.
final class DamageResistance : NSManagedObject {
    
    /// Monster that is resistant.
    @NSManaged var monster: Monster
    
    /// Type of damage that the monster is resistant to.
    var damageType: DamageType {
        get {
            return DamageType(rawValue: rawDamageType.intValue)!
        }
        set(newDamageType) {
            rawDamageType = NSNumber(value: newDamageType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawDamageType: NSNumber
    
    /// Type of attacks that this damage resistance applies to.
    var attackType: AttackType {
        get {
            return AttackType(rawValue: rawAttackType.intValue)!
        }
        set(newAttackType) {
            rawAttackType = NSNumber(value: newAttackType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawAttackType: NSNumber
    
    // HACK for the time being to parse Archmage
    @NSManaged var spellName: String?
    
    convenience init(monster: Monster, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.DamageResistance, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.monster = monster
    }
    
}

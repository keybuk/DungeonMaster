//
//  DamageResistanceOption.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

/// DamageResistanceOption represents the set of possible damage resistances to be chosen for the monster.
final class DamageResistanceOption: NSManagedObject {
    
    /// Monster that can choose this restiance.
    @NSManaged var monster: Monster
    
    /// Type of damage that the monster can be resistant to.
    var damageType: DamageType {
        get {
            return DamageType(rawValue: rawDamageType.integerValue)!
        }
        set(newDamageType) {
            rawDamageType = NSNumber(integer: newDamageType.rawValue)
        }
    }
    @NSManaged private var rawDamageType: NSNumber
    
    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.DamageResistanceOption, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.monster = monster
    }
    
}

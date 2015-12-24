//
//  MonsterSavingThrow.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// MonsterSavingThrow represents a saving throw that a monster is proficient in.
///
/// Monster proficiencies don't always match the proficiency bonus for their level, or even the double for expertise rule, so this includes the specific modifier for that proficiency.
final class MonsterSavingThrow: NSManagedObject {
    
    /// Monster that this proficiency applies to.
    @NSManaged var monster: Monster
    
    /// Saving throw that the monster is proficient in.
    var savingThrow: Ability {
        get {
            return Ability(rawValue: rawSavingThrow.integerValue)!
        }
        set(newSavingThrow) {
            rawSavingThrow = NSNumber(integer: newSavingThrow.rawValue)
        }
    }
    @NSManaged private var rawSavingThrow: NSNumber
    
    /// Modifier for this saving throw.
    var modifier: Int {
        get {
            return rawModifier.integerValue
        }
        set(newModifier) {
            rawModifier = NSNumber(integer: newModifier)
        }
    }
    @NSManaged private var rawModifier: NSNumber

    convenience init(monster: Monster, savingThrow: Ability, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.MonsterSavingThrow, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.monster = monster
        self.savingThrow = savingThrow
    }
    
}

//
//  Armor.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/18/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Armor represents a set of armor that can be equipped by a monster.
///
/// A monster may have many options for its armor, and which it has equipped may be indicated by the condition or form the monster is in, or DM's choice.
final class Armor : NSManagedObject {
    
    /// Monster to which this armor applies.
    @NSManaged var monster: Monster
    
    /// Total armor class for the monster while it has this armor set equipped.
    var armorClass: Int {
        get {
            return rawArmorClass.intValue
        }
        set(newArmorClass) {
            rawArmorClass = NSNumber(value: newArmorClass as Int)
        }
    }
    @NSManaged fileprivate var rawArmorClass: NSNumber
    
    /// The principle type of this armor.
    var type: ArmorType {
        get {
            return ArmorType(rawValue: rawType.intValue)!
        }
        set(newType) {
            rawType = NSNumber(value: newType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawType: NSNumber
    
    /// Bonus modifier applied when the armor is magic.
    var magicModifier: Int? {
        get {
            return rawMagicModifier?.intValue
        }
        set(newMagicModifier) {
            rawMagicModifier = newMagicModifier.map({ NSNumber(value: $0 as Int) })
        }
    }
    @NSManaged fileprivate var rawMagicModifier: NSNumber?
    
    /// Whether or not this armor includes a shield and its +2 bonus.
    @NSManaged var includesShield: Bool
    
    /// Monster condition during which this armor is automatically equipped.
    var condition: Condition? {
        get {
            return rawCondition.map({ Condition(rawValue: $0.intValue)! })
        }
        set(newCondition) {
            rawCondition = newCondition.map({ NSNumber(value: $0.rawValue as Int) })
        }
    }
    @NSManaged fileprivate var rawCondition: NSNumber?
    
    // FIXME these are basically a hack
    @NSManaged var spellName: String?
    @NSManaged var form: String?
    
    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Armor, inManagedObjectContext: context)
        self.init(entity: entity, insertInto: context)
        
        self.monster = monster
    }
    
}

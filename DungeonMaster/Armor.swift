//
//  Armor.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/18/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

/// Armor represents a set of armor that can be equipped by a monster.
///
/// A monster may have many options for its armor, and which it has equipped may be indicated by the condition or form the monster is in, or DM's choice.
final class Armor: NSManagedObject {
    
    /// Monster to which this armor applies.
    @NSManaged var monster: Monster
    
    /// Total armor class for the monster while it has this armor set equipped.
    var armorClass: Int {
        get {
            return rawArmorClass.integerValue
        }
        set(newArmorClass) {
            rawArmorClass = NSNumber(integer: newArmorClass)
        }
    }
    @NSManaged private var rawArmorClass: NSNumber
    
    /// The principle type of this armor.
    var type: ArmorType {
        get {
            return ArmorType(rawValue: rawType.integerValue)!
        }
        set(newType) {
            rawType = NSNumber(integer: newType.rawValue)
        }
    }
    @NSManaged private var rawType: NSNumber
    
    /// Bonus modifier applied when the armor is magic.
    var magicModifier: Int? {
        get {
            return rawMagicModifier?.integerValue
        }
        set(newMagicModifier) {
            rawMagicModifier = newMagicModifier != nil ? NSNumber(integer: newMagicModifier!) : nil
        }
    }
    @NSManaged private var rawMagicModifier: NSNumber?
    
    /// Whether or not this armor includes a shield and its +2 bonus.
    @NSManaged var includesShield: Bool
    
    /// Monster condition during which this armor is automatically equipped.
    var condition: ConditionType? {
        get {
            return rawCondition != nil ? ConditionType(rawValue: rawCondition!.integerValue) : nil
        }
        set(newCondition) {
            rawCondition = newCondition != nil ? NSNumber(integer: newCondition!.rawValue) : nil
        }
    }
    @NSManaged private var rawCondition: NSNumber?
    
    // FIXME these are basically a hack
    @NSManaged var spellName: String?
    @NSManaged var form: String?
    
    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Armor, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.monster = monster
    }
    
}

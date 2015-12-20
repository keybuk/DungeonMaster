//
//  Combatant.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData
import UIKit

final class Combatant: NSManagedObject {
    
    @NSManaged var encounter: Encounter
    @NSManaged var monster: Monster
    @NSManaged var dateCreated: NSDate
    @NSManaged var notes: String?
    
    var equippedArmor: Armor {
        let basicArmorPredicate = NSPredicate(format: "rawCondition == nil")
        var armors = monster.armor.filteredSetUsingPredicate(basicArmorPredicate)
    
        if conditions.count > 0 {
            let conditionTypes: [NSNumber] = conditions.map({ NSNumber(integer: ($0 as! Condition).type.rawValue) })
            let conditionsPredicate = NSPredicate(format: "rawCondition IN %@", conditionTypes)
            
            let conditionArmors = monster.armor.filteredSetUsingPredicate(conditionsPredicate)
            if conditionArmors.count > 0 {
                armors = conditionArmors
            }
        }
        
        // Return the highest applicable AC.
        return armors.sort({ (armor1, armor2) -> Bool in
            (armor1 as! Armor).armorClass > (armor2 as! Armor).armorClass
        })[0] as! Armor
    }

    var hitPoints: Int {
        get {
            return rawHitPoints.integerValue
        }
        set(newHitPoints) {
            rawHitPoints = NSNumber(integer: newHitPoints)
        }
    }
    @NSManaged private var rawHitPoints: NSNumber

    var damagePoints: Int {
        get {
            return rawDamagePoints.integerValue
        }
        set(newDamagePoints) {
            rawDamagePoints = NSNumber(integer: newDamagePoints)
        }
    }
    @NSManaged private var rawDamagePoints: NSNumber

    var health: Float {
        return Float(max(hitPoints - damagePoints, 0)) / Float(hitPoints)
    }
    
    var initiative: Int? {
        get {
            return rawInitiative?.integerValue
        }
        set(newInitiative) {
            rawInitiative = newInitiative != nil ? NSNumber(integer: newInitiative!) : nil
        }
    }
    @NSManaged private var rawInitiative: NSNumber?

    var location: TabletopLocation? {
        get {
            return rawLocationX != nil && rawLocationY != nil ? TabletopLocation(x: CGFloat(rawLocationX!.floatValue), y: CGFloat(rawLocationY!.floatValue)) : nil
        }
        set(newLocation) {
            rawLocationX = newLocation != nil ? NSNumber(float: Float(newLocation!.x)) : nil
            rawLocationY = newLocation != nil ? NSNumber(float: Float(newLocation!.y)) : nil
        }
    }
    @NSManaged private var rawLocationX: NSNumber?
    @NSManaged private var rawLocationY: NSNumber?

    @NSManaged var damages: NSOrderedSet
    
    @NSManaged var conditions: NSOrderedSet

    convenience init(encounter: Encounter, monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Combatant, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.encounter = encounter
        self.monster = monster
        
        dateCreated = NSDate()
        hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
    }
    
}

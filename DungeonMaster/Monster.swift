//
//  Monster.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Monster: NSManagedObject {
    
    @NSManaged var name: String
    @NSManaged var sources: NSSet
    @NSManaged var tags: NSOrderedSet

    @NSManaged var rawSize: String
    @NSManaged var rawAlignment: String?
    @NSManaged var rawHitPoints: NSNumber?
    @NSManaged var rawHitDice: String
    @NSManaged var rawStrength: Int16
    @NSManaged var rawDexterity: Int16
    @NSManaged var rawConstitution: Int16
    @NSManaged var rawIntelligence: Int16
    @NSManaged var rawWisdom: Int16
    @NSManaged var rawCharisma: Int16
    @NSManaged var rawPassivePerception: Int16

    var size: Size {
        get {
            return Size(rawValue: rawSize)!
        }
        set(newSize) {
            rawSize = newSize.rawValue
        }
    }
    
    var alignment: Alignment? {
        get {
            return rawAlignment != nil ? Alignment(rawValue: rawAlignment!) : nil
        }
        set(newAlignment) {
            rawAlignment = newAlignment?.rawValue
        }
    }

    var hitPoints: Int? {
        get {
            return rawHitPoints?.integerValue
        }
        set(newHitPoints) {
            rawHitPoints = newHitPoints != nil ? NSNumber(integer: newHitPoints!) : nil
        }
    }
    
    var hitDice: DiceCombo {
        get {
            return try! DiceCombo(description: rawHitDice)
        }
        set(newHitDice) {
            rawHitDice = newHitDice.description
        }
    }

    var strength: Int {
        get {
            return Int(rawStrength)
        }
        set(newStrength) {
            rawStrength = Int16(newStrength)
        }
    }
    
    var dexterity: Int {
        get {
            return Int(rawDexterity)
        }
        set(newDexterity) {
            rawDexterity = Int16(newDexterity)
        }
    }
    
    var constitution: Int {
        get {
            return Int(rawConstitution)
        }
        set(newConstitution) {
            rawConstitution = Int16(newConstitution)
        }
    }

    var intelligence: Int {
        get {
            return Int(rawIntelligence)
        }
        set(newIntelligence) {
            rawIntelligence = Int16(newIntelligence)
        }
    }

    var wisdom: Int {
        get {
            return Int(rawWisdom)
        }
        set(newWisdom) {
            rawWisdom = Int16(newWisdom)
        }
    }

    var charisma: Int {
        get {
            return Int(rawCharisma)
        }
        set(newCharisma) {
            rawCharisma = Int16(newCharisma)
        }
    }

    var passivePerception: Int {
        get {
            return Int(rawPassivePerception)
        }
        set(newPassivePerception) {
            rawPassivePerception = Int16(newPassivePerception)
        }
    }

    @NSManaged var type: String
    @NSManaged var cr: Float
    @NSManaged var xp: Int32
    
    // Original un-parsed stat block text.
    @NSManaged var sizeTypeAlignment: String
    @NSManaged var armorClass: String
    @NSManaged var speed: String
    @NSManaged var savingThrows: String?
    @NSManaged var skills: String?
    @NSManaged var damageVulnerabilities: String?
    @NSManaged var damageResistances: String?
    @NSManaged var damageImmunities: String?
    @NSManaged var conditionImmunities: String?
    @NSManaged var senses: String
    @NSManaged var languages: String?
    @NSManaged var challenge: String
    
    @NSManaged var traits: NSOrderedSet
    @NSManaged var actions: NSOrderedSet
    @NSManaged var reactions: NSOrderedSet
    @NSManaged var legendaryActions: NSOrderedSet
    @NSManaged var lair: Lair?
    @NSManaged var combatants: NSSet

    // MARK: Computed properties
    
    var nameInitial: String {
        return String(name.characters.first!)
    }
    
    var strengthModifier: Int {
        return (strength - 10) / 2
    }
    
    var dexterityModifier: Int {
        return (dexterity - 10) / 2
    }

    var constitutionModifier: Int {
        return (constitution - 10) / 2
    }
    
    var intelligenceModifier: Int {
        return (intelligence - 10) / 2
    }
    
    var wisdomModifier: Int {
        return (wisdom - 10) / 2
    }
    
    var charismaModifier: Int {
        return (charisma - 10) / 2
    }

    var initiativeDice: DiceCombo {
        return try! DiceCombo(sides: 20, modifier: dexterityModifier)
    }

    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Monster, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }

}

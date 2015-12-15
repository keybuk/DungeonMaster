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

    // Type-wrapped members.
    @NSManaged var sizeValue: String
    @NSManaged var alignmentValue: String?
    @NSManaged var hitPointsValue: Int16
    @NSManaged var hitDiceValue: String
    @NSManaged var strengthValue: Int16
    @NSManaged var dexterityValue: Int16
    @NSManaged var constitutionValue: Int16
    @NSManaged var intelligenceValue: Int16
    @NSManaged var wisdomValue: Int16
    @NSManaged var charismaValue: Int16
    @NSManaged var passivePerceptionValue: Int16

    var size: Size {
        get {
            return Size(rawValue: sizeValue)!
        }
        set(newSize) {
            sizeValue = newSize.rawValue
        }
    }
    
    var alignment: Alignment? {
        get {
            return alignmentValue != nil ? Alignment(rawValue: alignmentValue!) : nil
        }
        set(newAlignment) {
            alignmentValue = newAlignment?.rawValue
        }
    }

    var hitPoints: Int {
        get {
            return Int(hitPointsValue)
        }
        set(newHitPoints) {
            hitPointsValue = Int16(newHitPoints)
        }
    }
    
    var hitDice: DiceCombo {
        get {
            return try! DiceCombo(description: hitDiceValue)
        }
        set(newHitDice) {
            hitDiceValue = newHitDice.description
        }
    }

    var strengthScore: Int {
        get {
            return Int(strengthValue)
        }
        set(newStrengthScore) {
            strengthValue = Int16(newStrengthScore)
        }
    }
    
    var strengthModifier: Int {
        return (strengthScore - 10) / 2
    }

    var dexterityScore: Int {
        get {
            return Int(dexterityValue)
        }
        set(newDexterityScore) {
            dexterityValue = Int16(newDexterityScore)
        }
    }

    var dexterityModifier: Int {
        return (dexterityScore - 10) / 2
    }
    
    var constitutionScore: Int {
        get {
            return Int(constitutionValue)
        }
        set(newConstitutionScore) {
            constitutionValue = Int16(newConstitutionScore)
        }
    }

    var constitutionModifier: Int {
        return (constitutionScore - 10) / 2
    }
    
    var intelligenceScore: Int {
        get {
            return Int(intelligenceValue)
        }
        set(newIntelligenceScore) {
            intelligenceValue = Int16(newIntelligenceScore)
        }
    }

    var intelligenceModifier: Int {
        return (intelligenceScore - 10) / 2
    }
    
    var wisdomScore: Int {
        get {
            return Int(wisdomValue)
        }
        set(newWisdomScore) {
            wisdomValue = Int16(newWisdomScore)
        }
    }

    var wisdomModifier: Int {
        return (wisdomScore - 10) / 2
    }
    
    var charismaScore: Int {
        get {
            return Int(charismaValue)
        }
        set(newCharismaScore) {
            charismaValue = Int16(newCharismaScore)
        }
    }

    var charismaModifier: Int {
        return (charismaScore - 10) / 2
    }
    
    var passivePerception: Int {
        get {
            return Int(passivePerceptionValue)
        }
        set(newPassivePerception) {
            passivePerceptionValue = Int16(newPassivePerception)
        }
    }
    
    var initiativeDice: DiceCombo {
        return try! DiceCombo(sides: 20, modifier: dexterityModifier)
    }
    
    // Partially-parsed members.
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

    var nameInitial: String {
        return String(name.characters.first!)
    }

    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Monster, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }

}

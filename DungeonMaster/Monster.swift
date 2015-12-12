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

    enum Size: String {
        case Tiny
        case Small
        case Medium
        case Large
        case Huge
        case Gargantuan
    }

    var size: Size {
        get {
            return Size(rawValue: sizeValue)!
        }
        set {
            sizeValue = size.rawValue
        }
    }
    
    enum Alignment: String {
        case Unaligned = "unaligned"
        case LawfulGood = "lawful good"
        case LawfulNeutral = "lawful neutral"
        case LawfulEvil = "lawful evil"
        case NeutralGood = "neutral good"
        case Neutral = "neutral"
        case NeutralEvil = "neutral evil"
        case ChaoticGood = "chaotic good"
        case ChaoticNeutral = "chaotic neutral"
        case ChaoticEvil = "chaotic evil"
    }
    
    var alignment: Alignment? {
        get {
            return alignmentValue != nil ? Alignment(rawValue: alignmentValue!) : nil
        }
        set {
            alignmentValue = alignment != nil ? alignment!.rawValue : nil
        }
    }

    var hitPoints: Int {
        get {
            return Int(hitPointsValue)
        }
        set {
            hitPointsValue = Int16(hitPoints)
        }
    }
    
    var hitDice: DiceCombo {
        get {
            return try! DiceCombo(description: hitDiceValue)
        }
        set {
            hitDiceValue = hitDice.description
        }
    }

    var strengthScore: Int {
        get {
            return Int(strengthValue)
        }
        set {
            strengthValue = Int16(strengthScore)
        }
    }
    
    var strengthModifier: Int {
        return (strengthScore - 10) / 2
    }

    var dexterityScore: Int {
        get {
            return Int(dexterityValue)
        }
        set {
            dexterityValue = Int16(dexterityScore)
        }
    }

    var dexterityModifier: Int {
        return (dexterityScore - 10) / 2
    }
    
    var constitutionScore: Int {
        get {
            return Int(constitutionValue)
        }
        set {
            constitutionValue = Int16(constitutionScore)
        }
    }

    var constitutionModifier: Int {
        return (constitutionScore - 10) / 2
    }
    
    var intelligenceScore: Int {
        get {
            return Int(intelligenceValue)
        }
        set {
            intelligenceValue = Int16(intelligenceScore)
        }
    }

    var intelligenceModifier: Int {
        return (intelligenceScore - 10) / 2
    }
    
    var wisdomScore: Int {
        get {
            return Int(wisdomValue)
        }
        set {
            wisdomValue = Int16(wisdomScore)
        }
    }

    var wisdomModifier: Int {
        return (wisdomScore - 10) / 2
    }
    
    var charismaScore: Int {
        get {
            return Int(charismaValue)
        }
        set {
            charismaValue = Int16(charismaScore)
        }
    }

    var charismaModifier: Int {
        return (charismaScore - 10) / 2
    }
    
    var passivePerception: Int {
        get {
            return Int(passivePerceptionValue)
        }
        set {
            passivePerceptionValue = Int16(passivePerception)
        }
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

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
    @NSManaged var isNPC: Bool
    @NSManaged var lair: Lair?

    var size: Size {
        get {
            return Size(rawValue: rawSize)!
        }
        set(newSize) {
            rawSize = newSize.rawValue
        }
    }
    @NSManaged private var rawSize: String

    var alignment: Alignment? {
        get {
            return rawAlignment != nil ? Alignment(rawValue: rawAlignment!) : nil
        }
        set(newAlignment) {
            rawAlignment = newAlignment?.rawValue
        }
    }
    @NSManaged private var rawAlignment: String?

    var hitPoints: Int? {
        get {
            return rawHitPoints?.integerValue
        }
        set(newHitPoints) {
            rawHitPoints = newHitPoints != nil ? NSNumber(integer: newHitPoints!) : nil
        }
    }
    @NSManaged private var rawHitPoints: NSNumber?

    var hitDice: DiceCombo {
        get {
            return try! DiceCombo(description: rawHitDice)
        }
        set(newHitDice) {
            rawHitDice = newHitDice.description
        }
    }
    @NSManaged private var rawHitDice: String

    var strength: Int {
        get {
            return Int(rawStrength)
        }
        set(newStrength) {
            rawStrength = Int16(newStrength)
        }
    }
    @NSManaged private var rawStrength: Int16

    var dexterity: Int {
        get {
            return Int(rawDexterity)
        }
        set(newDexterity) {
            rawDexterity = Int16(newDexterity)
        }
    }
    @NSManaged private var rawDexterity: Int16

    var constitution: Int {
        get {
            return Int(rawConstitution)
        }
        set(newConstitution) {
            rawConstitution = Int16(newConstitution)
        }
    }
    @NSManaged private var rawConstitution: Int16

    var intelligence: Int {
        get {
            return Int(rawIntelligence)
        }
        set(newIntelligence) {
            rawIntelligence = Int16(newIntelligence)
        }
    }
    @NSManaged private var rawIntelligence: Int16

    var wisdom: Int {
        get {
            return Int(rawWisdom)
        }
        set(newWisdom) {
            rawWisdom = Int16(newWisdom)
        }
    }
    @NSManaged private var rawWisdom: Int16

    var charisma: Int {
        get {
            return Int(rawCharisma)
        }
        set(newCharisma) {
            rawCharisma = Int16(newCharisma)
        }
    }
    @NSManaged private var rawCharisma: Int16

    var passivePerception: Int {
        get {
            return Int(rawPassivePerception)
        }
        set(newPassivePerception) {
            rawPassivePerception = Int16(newPassivePerception)
        }
    }
    @NSManaged private var rawPassivePerception: Int16

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
    
    @NSManaged var sources: NSSet

    var allSources: Set<Source> {
        return sources as! Set<Source>
    }
    
    @NSManaged var tags: NSOrderedSet

    var allTags: [Tag] {
        return tags.array as! [Tag]
    }
    
    @NSManaged var traits: NSOrderedSet

    var allTraits: [Trait] {
        return traits.array as! [Trait]
    }
    
    @NSManaged var actions: NSOrderedSet
    
    var allActions: [Action] {
        return actions.array as! [Action]
    }
    
    @NSManaged var reactions: NSOrderedSet

    var allReactions: [Reaction] {
        return reactions.array as! [Reaction]
    }
    
    @NSManaged var legendaryActions: NSOrderedSet

    var allLegendaryActions: [LegendaryAction] {
        return legendaryActions.array as! [LegendaryAction]
    }
    
    @NSManaged var combatants: NSSet

    var allCombatants: Set<Combatant> {
        return combatants as! Set<Combatant>
    }

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

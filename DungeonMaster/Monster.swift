//
//  Monster.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

/// Monster represents any DM-controlled creature or target in the D&D world, from evil dragons through to a helpful NPC the players might encounter.
final class Monster: NSManagedObject {
    
    /// Name for the monster.
    @NSManaged var name: String
    
    /// First initial of the monster's name, used for section and index titles in the monsters list.
    var nameInitial: String {
        return String(name.characters[name.characters.startIndex])
    }

    /// Some monsters represent a specific individual, rather than a generic creature. These individuals are intended to be the same exact creature in each encounter, rather than another generic of the same creature type.
    @NSManaged var isNPC: Bool

    /// Source material for the monster.
    ///
    /// Each member is a `Source` containing a reference to the specific book, supplement, etc. the monster text can be found in, the page number, and the section if relevant.
    @NSManaged var sources: NSSet

    /// When the monster represents a swarm of (usually) smaller monsters, this property is set to the size of the swarm itself.
    ///
    /// The size of the individual monsters in the swarm can be found in the usual `size` property.
    var swarmSize: Size? {
        get {
            return rawSwarmSize != nil ? Size(rawValue: rawSwarmSize!.integerValue)! : nil
        }
        set(newSwarmSize) {
            rawSwarmSize = newSwarmSize != nil ? NSNumber(integer: newSwarmSize!.rawValue) : nil
        }
    }
    @NSManaged private var rawSwarmSize: NSNumber?

    /// Size of the monster.
    var size: Size {
        get {
            return Size(rawValue: rawSize.integerValue)!
        }
        set(newSize) {
            rawSize = NSNumber(integer: newSize.rawValue)
        }
    }
    @NSManaged private var rawSize: NSNumber

    /// Type of the monster.
    var type: MonsterType {
        get {
            return MonsterType(rawValue: rawType.integerValue)!
        }
        set(newType) {
            rawType = NSNumber(integer: newType.rawValue)
        }
    }
    @NSManaged private var rawType: NSNumber
    
    /// Some monster stats are templates for classes of NPCs and don't have race-specific information; those have `true` for this property.
    @NSManaged var requiresRace: Bool
    
    /// Arbitrary tags applied to monsters that have no meaning in of themselves, but may be referred to in the descriptions of traits, attacks, spells, etc.
    ///
    /// Each member is a `Tag` shared with other monsters it's applied to.
    @NSManaged var tags: NSSet
    
    /// Alignment of the monster.
    ///
    /// When this value is nil, check `alignmentOptions` for the possible alignments that this monster may have. If the monster has neither alignment or alignment options, then it has no alignment ("unaligned" in the Monster Manual).
    var alignment: Alignment? {
        get {
            return rawAlignment != nil ? Alignment(rawValue: rawAlignment!.integerValue)! : nil
        }
        set(newAlignment) {
            rawAlignment = newAlignment != nil ? NSNumber(integer: newAlignment!.rawValue) : nil
        }
    }
    @NSManaged private var rawAlignment: NSNumber?

    /// Options for alignment of the monster.
    ///
    /// This field is used when `alignment` is nil and provides the set of alignments that the monster can have. Either all alignment options have the `weight` field set, in which case the weight indicates the distribution of these alignments in the general population, or all alignment options do not have the `weight` field set, in which case the options indicate an equal range of probable alignments and correspond to common sets such as "any evil alignment".
    @NSManaged var alignmentOptions: NSSet
    
    /// Fixed hit points for the monster.
    ///
    /// This is almost always nil, and the `averageValue` from `hitDice` should be used; the exception is the *Demilich* which has a special trait giving it the maximum hit points, which is contained in this value.
    var hitPoints: Int? {
        get {
            return rawHitPoints?.integerValue
        }
        set(newHitPoints) {
            rawHitPoints = newHitPoints != nil ? NSNumber(integer: newHitPoints!) : nil
        }
    }
    @NSManaged private var rawHitPoints: NSNumber?

    /// Dice to roll to generate hit points for the monster.
    ///
    /// The `averageValue` is the usual default; the dice can be rolled to generate a more random alternative.
    var hitDice: DiceCombo {
        get {
            return try! DiceCombo(description: rawHitDice)
        }
        set(newHitDice) {
            rawHitDice = newHitDice.description
        }
    }
    @NSManaged private var rawHitDice: String

    /// Dice to roll to generate initiative for the monster.
    var initiativeDice: DiceCombo {
        return try! DiceCombo(sides: 20, modifier: dexterityModifier)
    }

    /// Strength score, used for generating `strengthModifier`.
    var strength: Int {
        get {
            return Int(rawStrength)
        }
        set(newStrength) {
            rawStrength = Int16(newStrength)
        }
    }
    @NSManaged private var rawStrength: Int16

    /// Modifier to apply to strength actions, saving throws, and ability checks.
    var strengthModifier: Int {
        return (strength - 10) / 2
    }
    
    /// Dexterity score, used for generating `dexterityModifier`.
    var dexterity: Int {
        get {
            return Int(rawDexterity)
        }
        set(newDexterity) {
            rawDexterity = Int16(newDexterity)
        }
    }
    @NSManaged private var rawDexterity: Int16

    /// Modifier to apply to dexterity actions, saving throws, and ability checks.
    var dexterityModifier: Int {
        return (dexterity - 10) / 2
    }
    
    /// Constitution score, used for generating `constitutionModifier`.
    var constitution: Int {
        get {
            return Int(rawConstitution)
        }
        set(newConstitution) {
            rawConstitution = Int16(newConstitution)
        }
    }
    @NSManaged private var rawConstitution: Int16

    /// Modifier to apply to constitution saving throws and ability checks.
    var constitutionModifier: Int {
        return (constitution - 10) / 2
    }
    
    /// Intelligence score, used for generating `intelligenceModifier`.
    var intelligence: Int {
        get {
            return Int(rawIntelligence)
        }
        set(newIntelligence) {
            rawIntelligence = Int16(newIntelligence)
        }
    }
    @NSManaged private var rawIntelligence: Int16

    /// Modifier to apply to intelligence spells, saving throws, and ability checks.
    var intelligenceModifier: Int {
        return (intelligence - 10) / 2
    }
    
    /// Wisdom score, used for generating `wisdomModifier`.
    var wisdom: Int {
        get {
            return Int(rawWisdom)
        }
        set(newWisdom) {
            rawWisdom = Int16(newWisdom)
        }
    }
    @NSManaged private var rawWisdom: Int16

    /// Modifier to apply to wisdom spells, saving throws, and ability checks.
    var wisdomModifier: Int {
        return (wisdom - 10) / 2
    }
    
    /// Charisma score, used for genearting `charismaModifier`.
    var charisma: Int {
        get {
            return Int(rawCharisma)
        }
        set(newCharisma) {
            rawCharisma = Int16(newCharisma)
        }
    }
    @NSManaged private var rawCharisma: Int16

    /// Modifier to apply to charisma spells, saving throws, and ability checks.
    var charismaModifier: Int {
        return (charisma - 10) / 2
    }
    
    /// Passive perception score.
    var passivePerception: Int {
        get {
            return Int(rawPassivePerception)
        }
        set(newPassivePerception) {
            rawPassivePerception = Int16(newPassivePerception)
        }
    }
    @NSManaged private var rawPassivePerception: Int16
    
    /// The challenge rating of this monster.
    ///
    /// Represented as an NSDecimalNumber since ⅛ (0.125), ¼ (0.25), and ½ (0.5) are possible ratings, and we want to represent them without getting into fuzzy comparisons that we'd end up with using Floats or Doubles.
    @NSManaged var challenge: NSDecimalNumber

    /// XP earned for defeating this monster.
    var XP: Int {
        if challenge == 0 && actions.count == 0 && reactions.count == 0 {
            return 0
        }
        
        return sharedRules.challengeXP[challenge]!
    }

    // Original un-parsed stat block text.
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
    
    /// Special traits of this monster.
    ///
    /// Each member is a `Trait` naming and describing the trait. This is an ordered set to preserve the text from the Monster Manual, no ordering between traits need be assumed.
    @NSManaged var traits: NSOrderedSet

    /// Actions that the monster may take on its turn.
    ///
    /// Each member is an `Action` naming and describing the action. This is an ordered set to preseve the text from the Monster Manual, no ordering between actions need be assumed.
    @NSManaged var actions: NSOrderedSet
    
    /// Reactions that the monster may take as a result of another creature's turn.
    ///
    /// Each member is a `Reaction` naming and describing the reaction. This is an ordered set to preserve the text from the Monster Manual, no ordering between reactions need be assumed.
    @NSManaged var reactions: NSOrderedSet

    /// Legendary actions that the monster may take during other creatures' turns.
    ///
    /// Each member is a `LegendaryAction` naming and describing the action. This is an ordered set to preseve the text from the Monster Manual, no ordering between actions need be assumed.
    @NSManaged var legendaryActions: NSOrderedSet

    /// Description of the lair in which these monsters can sometimes be found.
    @NSManaged var lair: Lair?

    /// Individuals of this monster type involved in encounters.
    ///
    /// Each member is a `Combatant` linking a monster to its encounter, and describing the current state of that monster such as its individual hit points, damage taken, conditions, etc.
    @NSManaged var combatants: NSSet

    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Monster, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }

}

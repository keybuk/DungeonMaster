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

    /// Source material for the monster. Each member is a `Source` containing a reference to the specific book, supplement, etc. the monster text can be found in, the page number, and the section if relevant.
    @NSManaged var sources: NSSet
    
    var allSources: Set<Source> {
        return sources as! Set<Source>
    }

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
    @NSManaged var tags: NSSet
    
    var allTags: Set<Tag> {
        return tags as! Set<Tag>
    }

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
    
    var allAlignmentOptions: Set<AlignmentOption> {
        return alignmentOptions as! Set<AlignmentOption>
    }

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

    @NSManaged var cr: Float
    @NSManaged var xp: Int32

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
    @NSManaged var challenge: String
    @NSManaged var lair: Lair?
    
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

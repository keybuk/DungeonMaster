//
//  Monster.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

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
    
    /// Environments in which the monster can be found.
    ///
    /// Each member is a `MonsterEnvironment`.
    @NSManaged var environments: NSSet

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
    
    /// Armor sets that the monster may equip.
    ///
    /// At least one possible armor set is guaranteed.
    @NSManaged var armor: NSSet
    
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
    
    /// Monster's movement speed (in feet).
    var speed: Int {
        get {
            return rawSpeed.integerValue
        }
        set(newSpeed) {
            rawSpeed = NSNumber(integer: newSpeed)
        }
    }
    @NSManaged private var rawSpeed: NSNumber
    
    /// Monster's movement speed (in feet) while burrowing, if the monster is capable of this.
    var burrowSpeed: Int? {
        get {
            return rawBurrowSpeed?.integerValue
        }
        set(newBurrowSpeed) {
            rawBurrowSpeed = newBurrowSpeed != nil ? NSNumber(integer: newBurrowSpeed!) : nil
        }
    }
    @NSManaged private var rawBurrowSpeed: NSNumber?

    /// Monster's movement speed (in feet) while climbing, if the monster is capable of this.
    var climbSpeed: Int? {
        get {
            return rawClimbSpeed?.integerValue
        }
        set(newClimbSpeed) {
            rawClimbSpeed = newClimbSpeed != nil ? NSNumber(integer: newClimbSpeed!) : nil
        }
    }
    @NSManaged private var rawClimbSpeed: NSNumber?
    
    /// Monster's movement speed (in feet) while flying, if the monster is capable of this.
    var flySpeed: Int? {
        get {
            return rawFlySpeed?.integerValue
        }
        set(newFlySpeed) {
            rawFlySpeed = newFlySpeed != nil ? NSNumber(integer: newFlySpeed!) : nil
        }
    }
    @NSManaged private var rawFlySpeed: NSNumber?
    
    /// Whether the monster can hover.
    ///
    /// Ability to hover means that, while flying, if the monster is knocked prone, has its speed reduced to zero, or is otherwise restrained from moving, it doesn't fall from the sky.
    @NSManaged var canHover: Bool

    /// Monster's movement speed (in feet) while swimming, if the monster is capable of this.
    var swimSpeed: Int? {
        get {
            return rawSwimSpeed?.integerValue
        }
        set(newSwimSpeed) {
            rawSwimSpeed = newSwimSpeed != nil ? NSNumber(integer: newSwimSpeed!) : nil
        }
    }
    @NSManaged private var rawSwimSpeed: NSNumber?

    /// Strength score, used as base to calculcate modifiers for Strength actions, saving throws, and skills.
    var strengthScore: Int {
        get {
            return rawStrengthScore.integerValue
        }
        set(newStrengthScore) {
            rawStrengthScore = NSNumber(integer: newStrengthScore)
        }
    }
    @NSManaged private var rawStrengthScore: NSNumber

    /// Dexterity score, used as base to calculcate modifiers for Dexterity actions, saving throws, and skills.
    var dexterityScore: Int {
        get {
            return rawDexterityScore.integerValue
        }
        set(newDexterityScore) {
            rawDexterityScore = NSNumber(integer: newDexterityScore)
        }
    }
    @NSManaged private var rawDexterityScore: NSNumber

    /// Constitution score, used as base to calculcate modifiers for Constitution actions, saving throws, and skills.
    var constitutionScore: Int {
        get {
            return rawConstitutionScore.integerValue
        }
        set(newConstitutionScore) {
            rawConstitutionScore = NSNumber(integer: newConstitutionScore)
        }
    }
    @NSManaged private var rawConstitutionScore: NSNumber

    /// Intelligence score, used as base to calculcate modifiers for Intelligence actions, saving throws, and skills.
    var intelligenceScore: Int {
        get {
            return rawIntelligenceScore.integerValue
        }
        set(newIntelligenceScore) {
            rawIntelligenceScore = NSNumber(integer: newIntelligenceScore)
        }
    }
    @NSManaged private var rawIntelligenceScore: NSNumber

    /// Wisdom score, used as base to calculcate modifiers for Wisdom actions, saving throws, and skills.
    var wisdomScore: Int {
        get {
            return rawWisdomScore.integerValue
        }
        set(newWisdomScore) {
            rawWisdomScore = NSNumber(integer: newWisdomScore)
        }
    }
    @NSManaged private var rawWisdomScore: NSNumber

    /// Charisma score, used as base to calculcate modifiers for Charisma actions, saving throws, and skills.
    var charismaScore: Int {
        get {
            return rawCharismaScore.integerValue
        }
        set(newCharismaScore) {
            rawCharismaScore = NSNumber(integer: newCharismaScore)
        }
    }
    @NSManaged private var rawCharismaScore: NSNumber

    /// Set of saving throws that the monster is proficient in.
    ///
    /// Each member is a `MonsterSavingThrow`.
    @NSManaged var savingThrows: NSSet
    
    /// Set of skills that the monster is proficient in.
    ///
    /// Each member is a `MonsterSkill`.
    @NSManaged var skills: NSSet
    
    /// Types of damage and attack that this monster is vulnerable to.
    ///
    /// Each member is a `DamageVulnerability`.
    @NSManaged var damageVulnerabilities: NSSet
    
    /// Whether the monster is resistance to all damage from spells.
    @NSManaged var isResistantToSpellDamage: Bool
    
    /// Types of damage and attack that this monster is resistant to.
    ///
    /// Each member is a `DamageResistance`.
    @NSManaged var damageResistances: NSSet
    
    /// Select of damage types that monsters created from this can be resistant to.
    ///
    /// Each member is a `DamageResistanceOption` specifying the resistance, one of the set should be picked and used to set `damageResistances` in the new monster.
    @NSManaged var damageResistanceOptions: NSSet
    
    /// Types of damage and attack that this monster is immune to.
    ///
    /// Each member is a `DamageImmunity`.
    @NSManaged var damageImmunities: NSSet
    
    /// Conditions that this monster is immune to.
    ///
    /// Each member is a `ConditionImmunity`.
    @NSManaged var conditionImmunities: NSSet
    
    /// Whether the monster is naturally blind.
    ///
    /// This is always combined with `blindsight` to indicate what the monster's range of perception is.
    @NSManaged var isBlind: Bool
    
    /// Distance (in feet) within which the monster can perceive surroundings without relying on sight.
    var blindsight: Int? {
        get {
            return rawBlindsight?.integerValue
        }
        set(newBlindsight) {
            rawBlindsight = newBlindsight != nil ? NSNumber(integer: newBlindsight!) : nil
        }
    }
    @NSManaged private var rawBlindsight: NSNumber?
    
    /// Distance (in feet) within which the monster can see in the dark.
    ///
    /// In darkness the monster perceives as in dim light, and in dim light as if in bright light.
    var darkvision: Int? {
        get {
            return rawDarkvision?.integerValue
        }
        set(newDarkvision) {
            rawDarkvision = newDarkvision != nil ? NSNumber(integer: newDarkvision!) : nil
        }
    }
    @NSManaged private var rawDarkvision: NSNumber?
    
    /// Distance (in feet) within which the monster can detect and pinpoint vibrations.
    var tremorsense: Int? {
        get {
            return rawTremorsense?.integerValue
        }
        set(newTremorsense) {
            rawTremorsense = newTremorsense != nil ? NSNumber(integer: newTremorsense!) : nil
        }
    }
    @NSManaged private var rawTremorsense: NSNumber?
    
    /// Distance (in feet) within which the monster can see in darkness, and see invisible creatures.
    var truesight: Int? {
        get {
            return rawTruesight?.integerValue
        }
        set(newTruesight) {
            rawTruesight = newTruesight != nil ? NSNumber(integer: newTruesight!) : nil
        }
    }
    @NSManaged private var rawTruesight: NSNumber?
    
    /// Whether this monster is capable of speaking all languages.
    @NSManaged var canSpeakAllLanguages: Bool
    
    /// Languages that this monster can speak.
    ///
    /// Each member is a `Language` shared with other monsters that can also speak or understand it.
    @NSManaged var languagesSpoken: NSSet
    
    /// Languages that monsters created from this stat block can speak.
    var languagesSpokenOption: LanguageOption? {
        get {
            return rawLanguagesSpokenOption != nil ? LanguageOption(rawValue: rawLanguagesSpokenOption!.integerValue)! : nil
        }
        set(newLanguagesSpokenOption) {
            rawLanguagesSpokenOption = newLanguagesSpokenOption != nil ? NSNumber(integer: newLanguagesSpokenOption!.rawValue) : nil
        }
    }
    @NSManaged private var rawLanguagesSpokenOption: NSNumber?
    
    /// Whether this monster can understand all languages (usually for the purpose of commands).
    @NSManaged var canUnderstandAllLanguages: Bool

    /// Languages that this monster can understand, but not speak.
    ///
    /// Each member is a `Language` shared with other monsters that can also speak or understand it.
    @NSManaged var languagesUnderstood: NSSet
    
    /// Languages that monsters created from this stat block can understand.
    var languagesUnderstoodOption: LanguageOption? {
        get {
            return rawLanguagesUnderstoodOption != nil ? LanguageOption(rawValue: rawLanguagesUnderstoodOption!.integerValue)! : nil
        }
        set(newLanguagesUnderstoodOption) {
            rawLanguagesUnderstoodOption = newLanguagesUnderstoodOption != nil ? NSNumber(integer: newLanguagesUnderstoodOption!.rawValue) : nil
        }
    }
    @NSManaged private var rawLanguagesUnderstoodOption: NSNumber?

    /// Distance (in feet) within which the monster can communicate telepathically.
    var telepathy: Int? {
        get {
            return rawTelepathy?.integerValue
        }
        set(newTelepathy) {
            rawTelepathy = newTelepathy != nil ? NSNumber(integer: newTelepathy!) : nil
        }
    }
    @NSManaged private var rawTelepathy: NSNumber?
    
    /// Whether the monster's telepathy ability is limited to the languages it can speak.
    @NSManaged var telepathyIsLimited: Bool

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
    
    /// Proficiency bonus for this monster.
    ///
    /// Applied as a modifier, on top of the appropriate ability modifier, to saving throws and skills that the monster has proficiency in, and to attacks. Sometimes doubled for "expertise".
    var proficiencyBonus: Int {
        return sharedRules.challengeProficiencyBonus[challenge]!
    }
    
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
    
    /// Returns the modifier for the given ability.
    func modifierFor(ability ability: Ability) -> Int {
        let score: Int
        switch ability {
        case .Strength:
            score = strengthScore
        case .Dexterity:
            score = dexterityScore
        case .Constitution:
            score = constitutionScore
        case .Intelligence:
            score = intelligenceScore
        case .Wisdom:
            score = wisdomScore
        case .Charisma:
            score = charismaScore
        }
        
        return Int(floor(Double(score - 10) / 2.0))
    }

    /// Returns the modifier for the given saving throw.
    func modifierFor(savingThrow savingThrow: Ability) -> Int {
        for case let monsterSavingThrow as MonsterSavingThrow in savingThrows {
            if monsterSavingThrow.savingThrow == savingThrow {
                return monsterSavingThrow.modifier
            }
        }
        
        return modifierFor(ability: savingThrow)
    }
    
    /// Returns the modifier for the given skill.
    func modifierFor(skill skill: Skill) -> Int {
        for case let monsterSkill as MonsterSkill in skills {
            if monsterSkill.skill == skill {
                return monsterSkill.modifier
            }
        }
        
        return modifierFor(ability: skill.ability)
    }

    /// Dice to roll to generate initiative for the monster.
    var initiativeDice: DiceCombo {
        return try! DiceCombo(sides: 20, modifier: modifierFor(ability: .Dexterity))
    }
    
    /// Passive perception score.
    var passivePerception: Int {
        return 10 + modifierFor(skill: .Wisdom(.Perception))
    }
    
}

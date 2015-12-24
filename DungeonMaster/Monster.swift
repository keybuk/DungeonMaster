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

    /// Strength score, used for generating `strengthModifier`.
    var strengthScore: Int {
        get {
            return rawStrengthScore.integerValue
        }
        set(newStrengthScore) {
            rawStrengthScore = NSNumber(integer: newStrengthScore)
        }
    }
    @NSManaged private var rawStrengthScore: NSNumber

    /// Modifier to apply to Strength actions and attacks.
    ///
    /// This is also used as the base modifier for Strength saving throws and skill checks.
    var strengthModifier: Int {
        return Int(floor(Double(strengthScore - 10) / 2.0))
    }
    
    /// Modifier to apply for Strength saving throws.
    ///
    /// Generally this has either the value of `strengthModifier`, or the value of that property with `proficiencyBonus` added to it; but there are exceptions (read: mistakes by the D&D authors).
    var strengthSavingThrow: Int {
        get {
            return rawStrengthSavingThrow?.integerValue ?? strengthModifier
        }
        set(newStrengthSavingThrow) {
            rawStrengthSavingThrow = newStrengthSavingThrow != strengthModifier ? NSNumber(integer: newStrengthSavingThrow) : nil
        }
    }
    @NSManaged private var rawStrengthSavingThrow: NSNumber?

    /// Modifier to apply for Strength (Athletics) skill checks.
    ///
    /// Usually this has the value of `strengthModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var athleticsSkill: Int {
        get {
            return rawAthleticsSkill?.integerValue ?? strengthModifier
        }
        set(newAthleticsSkill) {
            rawAthleticsSkill = newAthleticsSkill != strengthModifier ? NSNumber(integer: newAthleticsSkill) : nil
        }
    }
    @NSManaged private var rawAthleticsSkill: NSNumber?

    /// Dexterity score, used for generating `dexterityModifier`.
    var dexterityScore: Int {
        get {
            return rawDexterityScore.integerValue
        }
        set(newDexterityScore) {
            rawDexterityScore = NSNumber(integer: newDexterityScore)
        }
    }
    @NSManaged private var rawDexterityScore: NSNumber

    /// Modifier to apply to Dexterity actions and attacks.
    ///
    /// This is also used as the base modifier for Dexterity saving throws and skill checks.
    var dexterityModifier: Int {
        return Int(floor(Double(dexterityScore - 10) / 2.0))
    }
    
    /// Modifier to apply for Dexterity saving throws.
    ///
    /// Generally this has either the value of `dexterityModifier`, or the value of that property with `proficiencyBonus` added to it; but there are exceptions (read: mistakes by the D&D authors).
    var dexteritySavingThrow: Int {
        get {
            return rawDexteritySavingThrow?.integerValue ?? dexterityModifier
        }
        set(newDexteritySavingThrow) {
            rawDexteritySavingThrow = newDexteritySavingThrow != dexterityModifier ? NSNumber(integer: newDexteritySavingThrow) : nil
        }
    }
    @NSManaged private var rawDexteritySavingThrow: NSNumber?

    /// Modifier to apply for Dexterity (Acrobatics) skill checks.
    ///
    /// Usually this has the value of `dexterityModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var acrobaticsSkill: Int {
        get {
            return rawAcrobaticsSkill?.integerValue ?? dexterityModifier
        }
        set(newAcrobaticsSkill) {
            rawAcrobaticsSkill = newAcrobaticsSkill != dexterityModifier ? NSNumber(integer: newAcrobaticsSkill) : nil
        }
    }
    @NSManaged private var rawAcrobaticsSkill: NSNumber?

    /// Modifier to apply for Dexterity (Sleight of Hand) skill checks.
    ///
    /// Usually this has the value of `dexterityModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var sleightOfHandSkill: Int {
        get {
            return rawSleightOfHandSkill?.integerValue ?? dexterityModifier
        }
        set(newSleightOfHandSkill) {
            rawSleightOfHandSkill = newSleightOfHandSkill != dexterityModifier ? NSNumber(integer: newSleightOfHandSkill) : nil
        }
    }
    @NSManaged private var rawSleightOfHandSkill: NSNumber?
    
    /// Modifier to apply for Dexterity (Stealth) skill checks.
    ///
    /// Usually this has the value of `dexterityModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var stealthSkill: Int {
        get {
            return rawStealthSkill?.integerValue ?? dexterityModifier
        }
        set(newStealthSkill) {
            rawStealthSkill = newStealthSkill != dexterityModifier ? NSNumber(integer: newStealthSkill) : nil
        }
    }
    @NSManaged private var rawStealthSkill: NSNumber?
    
    /// Dice to roll to generate initiative for the monster.
    var initiativeDice: DiceCombo {
        return try! DiceCombo(sides: 20, modifier: dexterityModifier)
    }

    /// Constitution score, used for generating `constitutionModifier`.
    var constitutionScore: Int {
        get {
            return rawConstitutionScore.integerValue
        }
        set(newConstitutionScore) {
            rawConstitutionScore = NSNumber(integer: newConstitutionScore)
        }
    }
    @NSManaged private var rawConstitutionScore: NSNumber

    /// Modifier to apply to Constitution actions and attacks.
    ///
    /// This is also used as the base modifier for Constitution saving throws and skill checks.
    var constitutionModifier: Int {
        return Int(floor(Double(constitutionScore - 10) / 2.0))
    }
    
    /// Modifier to apply for Constitution saving throws.
    ///
    /// Generally this has either the value of `constitutionModifier`, or the value of that property with `proficiencyBonus` added to it; but there are exceptions (read: mistakes by the D&D authors).
    var constitutionSavingThrow: Int {
        get {
            return rawConstitutionSavingThrow?.integerValue ?? constitutionModifier
        }
        set(newConstitutionSavingThrow) {
            rawConstitutionSavingThrow = newConstitutionSavingThrow != constitutionModifier ? NSNumber(integer: newConstitutionSavingThrow) : nil
        }
    }
    @NSManaged private var rawConstitutionSavingThrow: NSNumber?

    /// Intelligence score, used for generating `intelligenceModifier`.
    var intelligenceScore: Int {
        get {
            return rawIntelligenceScore.integerValue
        }
        set(newIntelligenceScore) {
            rawIntelligenceScore = NSNumber(integer: newIntelligenceScore)
        }
    }
    @NSManaged private var rawIntelligenceScore: NSNumber

    /// Modifier to apply to Intelligence actions and attacks.
    ///
    /// This is also used as the base modifier for Intelligence saving throws and skill checks.
    var intelligenceModifier: Int {
        return Int(floor(Double(intelligenceScore - 10) / 2.0))
    }
    
    /// Modifier to apply for Intelligence saving throws.
    ///
    /// Generally this has either the value of `intelligenceModifier`, or the value of that property with `proficiencyBonus` added to it; but there are exceptions (read: mistakes by the D&D authors).
    var intelligenceSavingThrow: Int {
        get {
            return rawIntelligenceSavingThrow?.integerValue ?? intelligenceModifier
        }
        set(newIntelligenceSavingThrow) {
            rawIntelligenceSavingThrow = newIntelligenceSavingThrow != intelligenceModifier ? NSNumber(integer: newIntelligenceSavingThrow) : nil
        }
    }
    @NSManaged private var rawIntelligenceSavingThrow: NSNumber?

    /// Modifier to apply for Intelligence (Arcana) skill checks.
    ///
    /// Usually this has the value of `intelligenceModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var arcanaSkill: Int {
        get {
            return rawArcanaSkill?.integerValue ?? intelligenceModifier
        }
        set(newArcanaSkill) {
            rawArcanaSkill = newArcanaSkill != intelligenceModifier ? NSNumber(integer: newArcanaSkill) : nil
        }
    }
    @NSManaged private var rawArcanaSkill: NSNumber?
    
    /// Modifier to apply for Intelligence (History) skill checks.
    ///
    /// Usually this has the value of `intelligenceModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var historySkill: Int {
        get {
            return rawHistorySkill?.integerValue ?? intelligenceModifier
        }
        set(newHistorySkill) {
            rawHistorySkill = newHistorySkill != intelligenceModifier ? NSNumber(integer: newHistorySkill) : nil
        }
    }
    @NSManaged private var rawHistorySkill: NSNumber?
    
    /// Modifier to apply for Intelligence (Investigation) skill checks.
    ///
    /// Usually this has the value of `intelligenceModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var investigationSkill: Int {
        get {
            return rawInvestigationSkill?.integerValue ?? intelligenceModifier
        }
        set(newInvestigationSkill) {
            rawInvestigationSkill = newInvestigationSkill != intelligenceModifier ? NSNumber(integer: newInvestigationSkill) : nil
        }
    }
    @NSManaged private var rawInvestigationSkill: NSNumber?

    /// Modifier to apply for Intelligence (Nature) skill checks.
    ///
    /// Usually this has the value of `intelligenceModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var natureSkill: Int {
        get {
            return rawNatureSkill?.integerValue ?? intelligenceModifier
        }
        set(newNatureSkill) {
            rawNatureSkill = newNatureSkill != intelligenceModifier ? NSNumber(integer: newNatureSkill) : nil
        }
    }
    @NSManaged private var rawNatureSkill: NSNumber?
    
    /// Modifier to apply for Intelligence (Religion) skill checks.
    ///
    /// Usually this has the value of `intelligenceModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var religionSkill: Int {
        get {
            return rawReligionSkill?.integerValue ?? intelligenceModifier
        }
        set(newReligionSkill) {
            rawReligionSkill = newReligionSkill != intelligenceModifier ? NSNumber(integer: newReligionSkill) : nil
        }
    }
    @NSManaged private var rawReligionSkill: NSNumber?
    
    /// Wisdom score, used for generating `wisdomModifier`.
    var wisdomScore: Int {
        get {
            return rawWisdomScore.integerValue
        }
        set(newWisdomScore) {
            rawWisdomScore = NSNumber(integer: newWisdomScore)
        }
    }
    @NSManaged private var rawWisdomScore: NSNumber

    /// Modifier to apply to Wisdom actions and attacks.
    ///
    /// This is also used as the base modifier for Wisdom saving throws and skill checks.
    var wisdomModifier: Int {
        return Int(floor(Double(wisdomScore - 10) / 2.0))
    }
    
    /// Modifier to apply for Wisdom saving throws.
    ///
    /// Generally this has either the value of `wisdomModifier`, or the value of that property with `proficiencyBonus` added to it; but there are exceptions (read: mistakes by the D&D authors).
    var wisdomSavingThrow: Int {
        get {
            return rawWisdomSavingThrow?.integerValue ?? wisdomModifier
        }
        set(newWisdomSavingThrow) {
            rawWisdomSavingThrow = newWisdomSavingThrow != wisdomModifier ? NSNumber(integer: newWisdomSavingThrow) : nil
        }
    }
    @NSManaged private var rawWisdomSavingThrow: NSNumber?

    /// Modifier to apply for Wisdom (Animal Handling) skill checks.
    ///
    /// Usually this has the value of `wisdomModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var animalHandlingSkill: Int {
        get {
            return rawAnimalHandlingSkill?.integerValue ?? wisdomModifier
        }
        set(newAnimalHandlingSkill) {
            rawAnimalHandlingSkill = newAnimalHandlingSkill != wisdomModifier ? NSNumber(integer: newAnimalHandlingSkill) : nil
        }
    }
    @NSManaged private var rawAnimalHandlingSkill: NSNumber?
    
    /// Modifier to apply for Wisdom (Insight) skill checks.
    ///
    /// Usually this has the value of `wisdomModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var insightSkill: Int {
        get {
            return rawInsightSkill?.integerValue ?? wisdomModifier
        }
        set(newInsightSkill) {
            rawInsightSkill = newInsightSkill != wisdomModifier ? NSNumber(integer: newInsightSkill) : nil
        }
    }
    @NSManaged private var rawInsightSkill: NSNumber?
    
    /// Modifier to apply for Wisdom (Medicine) skill checks.
    ///
    /// Usually this has the value of `wisdomModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var medicineSkill: Int {
        get {
            return rawMedicineSkill?.integerValue ?? wisdomModifier
        }
        set(newMedicineSkill) {
            rawMedicineSkill = newMedicineSkill != wisdomModifier ? NSNumber(integer: newMedicineSkill) : nil
        }
    }
    @NSManaged private var rawMedicineSkill: NSNumber?
    
    /// Modifier to apply for Wisdom (Perception) skill checks.
    ///
    /// Usually this has the value of `wisdomModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var perceptionSkill: Int {
        get {
            return rawPerceptionSkill?.integerValue ?? wisdomModifier
        }
        set(newPerceptionSkill) {
            rawPerceptionSkill = newPerceptionSkill != wisdomModifier ? NSNumber(integer: newPerceptionSkill) : nil
        }
    }
    @NSManaged private var rawPerceptionSkill: NSNumber?
    
    /// Modifier to apply for Wisdom (Survival) skill checks.
    ///
    /// Usually this has the value of `wisdomModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var survivalSkill: Int {
        get {
            return rawSurvivalSkill?.integerValue ?? wisdomModifier
        }
        set(newSurvivalSkill) {
            rawSurvivalSkill = newSurvivalSkill != wisdomModifier ? NSNumber(integer: newSurvivalSkill) : nil
        }
    }
    @NSManaged private var rawSurvivalSkill: NSNumber?

    /// Passive perception score.
    var passivePerception: Int {
        return 10 + perceptionSkill
    }

    /// Charisma score, used for genearting `charismaModifier`.
    var charismaScore: Int {
        get {
            return rawCharismaScore.integerValue
        }
        set(newCharismaScore) {
            rawCharismaScore = NSNumber(integer: newCharismaScore)
        }
    }
    @NSManaged private var rawCharismaScore: NSNumber

    /// Modifier to apply to Charisma actions and attacks.
    ///
    /// This is also used as the base modifier for Charisma saving throws and skill checks.
    var charismaModifier: Int {
        return Int(floor(Double(charismaScore - 10) / 2.0))
    }
    
    /// Modifier to apply for Charisma saving throws.
    ///
    /// Generally this has either the value of `charismaModifier`, or the value of that property with `proficiencyBonus` added to it; but there are exceptions (read: mistakes by the D&D authors).
    var charismaSavingThrow: Int {
        get {
            return rawCharismaSavingThrow?.integerValue ?? charismaModifier
        }
        set(newCharismaSavingThrow) {
            rawCharismaSavingThrow = newCharismaSavingThrow != charismaModifier ? NSNumber(integer: newCharismaSavingThrow) : nil
        }
    }
    @NSManaged private var rawCharismaSavingThrow: NSNumber?

    /// Modifier to apply for Charisma (Deception) skill checks.
    ///
    /// Usually this has the value of `charismaModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var deceptionSkill: Int {
        get {
            return rawDeceptionSkill?.integerValue ?? charismaModifier
        }
        set(newDeceptionSkill) {
            rawDeceptionSkill = newDeceptionSkill != charismaModifier ? NSNumber(integer: newDeceptionSkill) : nil
        }
    }
    @NSManaged private var rawDeceptionSkill: NSNumber?
    
    /// Modifier to apply for Charisma (Intimidation) skill checks.
    ///
    /// Usually this has the value of `charismaModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var intimidationSkill: Int {
        get {
            return rawIntimidationSkill?.integerValue ?? charismaModifier
        }
        set(newIntimidationSkill) {
            rawIntimidationSkill = newIntimidationSkill != charismaModifier ? NSNumber(integer: newIntimidationSkill) : nil
        }
    }
    @NSManaged private var rawIntimidationSkill: NSNumber?

    /// Modifier to apply for Charisma (Performance) skill checks.
    ///
    /// Usually this has the value of `charismaModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var performanceSkill: Int {
        get {
            return rawPerformanceSkill?.integerValue ?? charismaModifier
        }
        set(newPerformanceSkill) {
            rawPerformanceSkill = newPerformanceSkill != charismaModifier ? NSNumber(integer: newPerformanceSkill) : nil
        }
    }
    @NSManaged private var rawPerformanceSkill: NSNumber?
    
    /// Modifier to apply for Charisma (Persuasion) skill checks.
    ///
    /// Usually this has the value of `charismaModifier` either on its own, with `proficiencyBonus` added to it, or double that property added to it; but there are various exceptions to this for particular monsters.
    var persuasionSkill: Int {
        get {
            return rawPersuasionSkill?.integerValue ?? charismaModifier
        }
        set(newPersuasionSkill) {
            rawPersuasionSkill = newPersuasionSkill != charismaModifier ? NSNumber(integer: newPersuasionSkill) : nil
        }
    }
    @NSManaged private var rawPersuasionSkill: NSNumber?
    
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

}

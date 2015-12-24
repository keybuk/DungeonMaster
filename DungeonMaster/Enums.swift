//
//  Enums.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation

/// BookType categorises D&D source material into one of the following:
///  - **CoreRulebook**: the three core rulebooks: Player's Handbook, Monster Manual, and Dungeon Master's Guide.
///  - **OfficialAdventure**: an official adventure published by Wizards of the Coast, e.g. Princes of the Apocalypse.
///  - **OnlineSupplement**: freely published online supplements to core rulebooks and official adventures, including the basic rules.
enum BookType: Int {
    case CoreRulebook
    case OfficialAdventure
    case OnlineSupplement
    // TODO: category for Sword Coast Adventures? official expansion or core rulebook?
    // TODO: category for Unearthed Arcana?
    
    /// Returns the string equivalent of the book type.
    var stringValue: String {
        return sharedRules.bookType[rawValue]
    }
}

/// Ability categorises the six basic abilities of D&D monsters and characters.
enum Ability: Int {
    case Strength
    case Dexterity
    case Constitution
    case Intelligence
    case Wisdom
    case Charisma
    
    /// Returns the string equivalent of the ability.
    var stringValue: String {
        return sharedRules.ability[rawValue]
    }
    
    /// Returns the short string equivalent of the ability.
    var shortStringValue: String {
        return stringValue.substringToIndex(stringValue.startIndex.advancedBy(3))
    }
}

/// Skill categorises the different possible skills of D&D monsters and characters.
///
/// Skills are grouped according to `Ability`, there are no skills for the `Constitution` ability.
enum Skill: Equatable, Hashable {
    enum StrengthSkill: Int {
        case Athletics
    }
    case Strength(StrengthSkill)
    
    enum DexteritySkill: Int {
        case Acrobatics
        case SleightOfHand
        case Stealth
    }
    case Dexterity(DexteritySkill)
    
    enum IntelligenceSkill: Int {
        case Arcana
        case History
        case Investigation
        case Nature
        case Religion
    }
    case Intelligence(IntelligenceSkill)
    
    enum WisdomSkill: Int {
        case AnimalHandling
        case Insight
        case Medicine
        case Perception
        case Survival
    }
    case Wisdom(WisdomSkill)
    
    enum CharismaSkill: Int {
        case Deception
        case Intimidation
        case Performance
        case Persuasion
    }
    case Charisma(CharismaSkill)
    
    var rawAbilityValue: Int {
        switch self {
        case .Strength(_):
            return 0
        case .Dexterity(_):
            return 1
        // Constitution would have the value 2, if it had associated skills.
        case .Intelligence(_):
            return 3
        case .Wisdom(_):
            return 4
        case .Charisma(_):
            return 5
        }
    }

    var rawSkillValue: Int {
        switch self {
        case .Strength(let skill):
            return skill.rawValue
        case .Dexterity(let skill):
            return skill.rawValue
        case .Intelligence(let skill):
            return skill.rawValue
        case .Wisdom(let skill):
            return skill.rawValue
        case .Charisma(let skill):
            return skill.rawValue
        }
    }
    
    var hashValue: Int {
        return [ rawAbilityValue, rawSkillValue ].hashValue
    }

    init?(rawAbilityValue: Int, rawSkillValue: Int) {
        switch rawAbilityValue {
        case 0:
            guard let skill = StrengthSkill(rawValue: rawSkillValue) else { return nil }
            self = .Strength(skill)
        case 1:
            guard let skill = DexteritySkill(rawValue: rawSkillValue) else { return nil }
            self = .Dexterity(skill)
        // Constitution would have the value 2, if it had associated skills.
        case 3:
            guard let skill = IntelligenceSkill(rawValue: rawSkillValue) else { return nil }
            self = .Intelligence(skill)
        case 4:
            guard let skill = WisdomSkill(rawValue: rawSkillValue) else { return nil }
            self = .Wisdom(skill)
        case 5:
            guard let skill = CharismaSkill(rawValue: rawSkillValue) else { return nil }
            self = .Charisma(skill)
        default:
            return nil
        }
    }
    
    /// Returns the string equivalent of the skill.
    ///
    /// This consists of only the second part, e.g. "Athletics".
    var stringValue: String {
        return sharedRules.skill[rawAbilityValue][rawSkillValue]
    }
    
    /// Returns the associated ability for the skill.
    var ability: Ability {
        return Ability(rawValue: rawAbilityValue)!
    }
    
    /// Returns the string equivalent of the ability and skill.
    ///
    /// This consists of both parts, e.g. "Strength (Athletics)".
    var longStringValue: String {
        return "\(ability.stringValue) (\(stringValue))"
    }
}

func ==(lhs: Skill, rhs: Skill) -> Bool {
    return lhs.rawAbilityValue == rhs.rawAbilityValue && lhs.rawSkillValue == rhs.rawSkillValue
}

/// Size categorises the different range of monster and character sizes.
enum Size: Int {
    case Tiny
    case Small
    case Medium
    case Large
    case Huge
    case Gargantuan
    
    /// Returns the string equivalent of the size.
    var stringValue: String {
        return sharedRules.size[rawValue]
    }
    
    /// Returns the space in feet occupied by creatures of this type.
    var space: Float {
        return sharedRules.sizeSpace[rawValue]
    }
    
    /// Returns the number of sides for the hit dice used to calculate hit points of creatures of this type.
    var hitDiceSides: Int {
        return sharedRules.sizeHitDiceSides[rawValue]
    }
}

/// Alignment categorises the different alignments of monsters and characters.
enum Alignment: Int {
    case Unaligned
    case LawfulGood
    case LawfulNeutral
    case LawfulEvil
    case NeutralGood
    case Neutral
    case NeutralEvil
    case ChaoticGood
    case ChaoticNeutral
    case ChaoticEvil
    
    /// Returns the string equivalent of the alignment.
    var stringValue: String {
        return sharedRules.alignment[rawValue]
    }
    
    /// Returns a set of all alignments.
    static var allAlignments: Set<Alignment> {
        return [ .LawfulGood, .LawfulNeutral, .LawfulEvil, .NeutralGood, .Neutral, .NeutralEvil, .ChaoticGood, .ChaoticNeutral, .ChaoticEvil ]
    }
    
    /// Returns a set of all lawful alignments.
    static var lawfulAlignments: Set<Alignment> {
        return [ .LawfulGood, .LawfulNeutral, .LawfulEvil ]
    }
    
    /// Returns a set of all choatic alignments.
    static var chaoticAlignments: Set<Alignment> {
        return [ .ChaoticGood, .ChaoticNeutral, .ChaoticEvil ]
    }
    
    /// Returns a set of all good alignments.
    static var goodAlignments: Set<Alignment> {
        return [ .LawfulGood, .NeutralGood, .ChaoticGood ]
    }
    
    /// Returns a set of all evil alignments.
    static var evilAlignments: Set<Alignment> {
        return [ .LawfulEvil, .NeutralEvil, .ChaoticEvil ]
    }
}

/// MonsterType categorises the different types of monsters.
enum MonsterType: Int {
    case Aberration
    case Beast
    case Celestial
    case Construct
    case Dragon
    case Elemental
    case Fey
    case Fiend
    case Giant
    case Humanoid
    case Monstrosity
    case Ooze
    case Plant
    case Undead
    
    /// Returns the string equivalent of the monster type.
    var stringValue: String {
        return sharedRules.monsterType[rawValue]
    }
}

enum Environment {
    case Arctic
    case Coastal
    case Desert
    case Forest
    case Grassland
    case Hill
    case Mountain
    case Swamp
    case Underdark
    case Underwater
    case Urban
}

/// Race categorises the basic races of D&D.
///
/// Races can have sub-types which are represented here as nested enums.
enum Race: Equatable, Hashable {
    // Player's Handbook races.
    enum DwarfSubrace: Int {
        case HillDwarf
        case MountainDwarf
        
        // Sword Coast Adventurer's Guide subraces.
        case GrayDwarf
    }
    case Dwarf(DwarfSubrace)
    
    enum ElfSubrace: Int {
        case HighElf
        case WoodElf
        case Drow
        
        // Dungeon Master's Guide subraces.
        case Eladrin
    }
    case Elf(ElfSubrace)
    
    enum HalflingSubrace: Int {
        case Lightfoot
        case Stout
    }
    case Halfling(HalflingSubrace)
    
    case Human
    case Dragonborn
    
    enum GnomeSubrace: Int {
        case ForestGnome
        case RockGnome
        
        // Elemental Evil subraces.
        case DeepGnome
    }
    case Gnome(GnomeSubrace)
    
    case HalfElf
    case HalfOrc
    case Tiefling
    
    // Dungeon Master's Guide races.
    case Aasimar
    
    // Elemental Evil races.
    case Aarakocra
    
    enum GenasiSubrace: Int {
        case AirGenasi
        case EarthGenasi
        case FireGenasi
        case WaterGenasi
    }
    case Genasi(GenasiSubrace)
    
    case Goliath
    
    var rawRaceValue: Int {
        switch self {
        case .Dwarf(_):
            return 0
        case .Elf(_):
            return 1
        case .Halfling(_):
            return 2
        case .Human:
            return 3
        case .Dragonborn:
            return 4
        case .Gnome(_):
            return 5
        case .HalfElf:
            return 6
        case .HalfOrc:
            return 7
        case .Tiefling:
            return 8
        case .Aasimar:
            return 9
        case .Aarakocra:
            return 10
        case .Genasi(_):
            return 11
        case .Goliath:
            return 12
        }
    }
    
    var rawSubraceValue: Int? {
        switch self {
        case .Dwarf(let subrace):
            return subrace.rawValue
        case .Elf(let subrace):
            return subrace.rawValue
        case .Halfling(let subrace):
            return subrace.rawValue
        case .Human:
            return nil
        case .Dragonborn:
            return nil
        case .Gnome(let subrace):
            return subrace.rawValue
        case .HalfElf:
            return nil
        case .HalfOrc:
            return nil
        case .Tiefling:
            return nil
        case .Aasimar:
            return nil
        case .Aarakocra:
            return nil
        case .Genasi(let subrace):
            return subrace.rawValue
        case .Goliath:
            return nil
        }
    }
    
    var hashValue: Int {
        return [ rawRaceValue, rawSubraceValue ?? 0 ].hashValue
    }
    
    init?(rawRaceValue: Int, rawSubraceValue: Int?) {
        switch rawRaceValue {
        case 0:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = DwarfSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .Dwarf(subrace)
        case 1:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = ElfSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .Elf(subrace)
        case 2:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = HalflingSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .Halfling(subrace)
        case 3:
            guard rawSubraceValue == nil else { return nil }
            self = .Human
        case 4:
            guard rawSubraceValue == nil else { return nil }
            self = .Dragonborn
        case 5:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = GnomeSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .Gnome(subrace)
        case 6:
            guard rawSubraceValue == nil else { return nil }
            self = .HalfElf
        case 7:
            guard rawSubraceValue == nil else { return nil }
            self = .HalfOrc
        case 8:
            guard rawSubraceValue == nil else { return nil }
            self = .Tiefling
        case 9:
            guard rawSubraceValue == nil else { return nil }
            self = .Aasimar
        case 10:
            guard rawSubraceValue == nil else { return nil }
            self = .Aarakocra
        case 11:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = GenasiSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .Genasi(subrace)
        case 12:
            guard rawSubraceValue == nil else { return nil }
            self = .Goliath
        default:
            return nil
        }
    }
    
    /// Returns the string equivalent of the race.
    ///
    /// This consists of the full subrace name, e.g. "Wood Elf".
    var stringValue: String {
        if let rawSubraceValue = rawSubraceValue {
            return sharedRules.subrace[rawRaceValue][rawSubraceValue]
        } else {
            return raceStringValue
        }
    }

    /// Returns the string equivalent of the primary race.
    var raceStringValue: String {
        return sharedRules.race[rawRaceValue]
    }
    
    /// Returns the size of creatures of this race.
    var size: Size {
        return Size(rawValue: sharedRules.raceSize[rawRaceValue])!
    }
}

func ==(lhs: Race, rhs: Race) -> Bool {
    return lhs.rawRaceValue == rhs.rawRaceValue && ((lhs.rawSubraceValue == nil && rhs.rawSubraceValue == nil) || (lhs.rawSubraceValue != nil && rhs.rawSubraceValue != nil && lhs.rawSubraceValue! == rhs.rawSubraceValue!))
}

/// CharacterClass organises the different classes of player characters.
enum CharacterClass: Int {
    case Barbarian
    case Bard
    case Cleric
    case Druid
    case Fighter
    case Monk
    case Paladin
    case Ranger
    case Rogue
    case Sorcerer
    case Warlock
    case Wizard
    
    /// Returns the string equivalent of the character class.
    var stringValue: String {
        return sharedRules.characterClass[rawValue]
    }
}

/// Background organises the different possible backgrounds of player characters.
enum Background: Int {
    // Player's Handbook backgrounds.
    case Acolyte
    case Charlatan
    case Criminal
    case Entertainer
    case FolkHero
    case GuildArtisan
    case Hermit
    case Noble
    case Outlander
    case Sage
    case Sailor
    case Soldier
    case Urchin
    
    // Sword Coast Adventurer's Guide backgrounds.
    case CityWatch
    case ClanCrafter
    case CloisteredScholar
    case Courtier
    case FactionAgent
    case FarTraveler
    case Inheritor
    case KnightOfTheOrder
    case MercenaryVeteran
    case UrbanBountyHunter
    case WaterdhavianNoble
    
    /// Returns the string equivalent of the background.
    var stringValue: String {
        return sharedRules.background[rawValue]
    }
}

/// Armor that can be worn by players and monsters.
enum ArmorType: Int {
    case None
    case Natural

    // Light Armor
    case Padded
    case Leather
    case StuddedLeather
    
    // Medium Armor
    case Hide
    case ChainShirt
    case ScaleMail
    case Breastplate
    case HalfPlate
    
    // Heavy Armor
    case RingMail
    case ChainMail
    case Splint
    case Plate
    
    // Monster-specific Armor.
    case Scraps
    case BardingScraps
    case Patchwork
    
    /// Returns the string equivalent of the armor.
    var stringValue: String {
        return sharedRules.armorType[rawValue]
    }
    
    /// Returns the base armor class for the armor.
    ///
    /// When this returns nil, it's up to the monster designer to decide the base AC.
    var armorClass: Int? {
        return sharedRules.armorClass[rawValue]
    }
    
    /// Returns whether the monster should add its Dexterity modifier to the armor class. and maximum value for that if appropriate.
    var addDexterityModifier: (add: Bool, max: Int?) {
        return sharedRules.armorDexterityModifierMax[rawValue]
    }
    
    /// Returns the minimum strength requirement for the armor.
    ///
    /// When this is not nil, and the monster does not have a strength equal or greater to the returned score, the monster's speed is reduced by 10 feet.
    var minimumStrength: Int? {
        return sharedRules.armorMinimumStrength[rawValue]
    }
    
    /// Returns whether stealth checks for monsters wearing this armor should have disadvantage.
    var stealthDisadvantage: Bool {
        return sharedRules.armorStealthDisadvantage[rawValue]
    }
}

/// Types of attack that a monster can be vulnerable, resistant, or immune to.
/// - **All**: applies to all attacks.
/// - **Nonmagical**: applies to nonmagical attacks.
/// - **NonmagicalNotAdamantine**: applies to nonmagical attacks not made with adamantine weapons.
/// - **NonmagicalNotSilvered**: applies to nonmagical attacks not made with silvered weapons.
/// - **Magical**: applies to magic weapons.
/// - **MagicalByGood**: applies to magic weapons wielded by good creatures.
enum AttackType: Int {
    case All
    case Nonmagical
    case NonmagicalNotAdamantine
    case NonmagicalNotSilvered
    case Magical
    case MagicalByGood
}

/// Types of damage that can be dealt by attacks.
enum DamageType: Int {
    case Acid
    case Bludgeoning
    case Cold
    case Fire
    case Force
    case Lightning
    case Necrotic
    case Piercing
    case Poison
    case Psychic
    case Radiant
    case Slashing
    case Thunder
    
    /// Returns the string equivalent of the damage type.
    var stringValue: String {
        return sharedRules.damageType[rawValue]
    }
}

enum Condition: Int {
    // TODO: deal with exhaustion, and its six levels
    case Blinded
    case Charmed
    case Deafened
    case Exhaustion
    case Frightened
    case Grappled
    case Incapacitated
    case Invisible
    case Paralyzed
    case Petrified
    case Poisoned
    case Prone
    case Restrained
    case Stunned
    case Unconcious
    
    /// Returns the string equivalent of the condition.
    var stringValue: String {
        return sharedRules.condition[rawValue]
    }
    
    /// Returns an array of rules texts for the condition.
    var rulesDescription: [String] {
        return sharedRules.conditionDescription[rawValue]
    }
}

/// Options for languages that a monster can understand or speak.
/// - **UsuallyCommon**: the monster will usually understand or speak Common.
/// - **KnewInLife**: the monster can understand or speak any languages it knew in life.
/// - **OfItsCreator**: the monster can understand or speak the languages of its creator.
/// - **OneOfItsCreator**: the monster can understand or speak a single language known by its creator.
/// - **AnyOne**: the monster can understand or speak any one language.
/// - **AnyTwo**: the monster can understand or speak any two languages.
/// - **AnyFour**: the monster can understand or speak any four languages.
/// - **UpToFive**: the monster can understand or speak up to five languages.
/// - **AnySix**: the monster can understand or speak any six languages.
enum LanguageOption: Int {
    case UsuallyCommon
    case KnewInLife
    case OfItsCreator
    case OneOfItsCreator
    case AnyOne
    case AnyTwo
    case AnyFour
    case UpToFive
    case AnySix
}

enum MagicSchool {
    case Abjuration
    case Conjuration
    case Divination
    case Enchantment
    case Evocation
    case Illusion
    case Necromancy
    case Transmutation
}

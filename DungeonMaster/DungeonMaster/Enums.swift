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
enum BookType : Int {
    case coreRulebook
    case officialAdventure
    case campaignSourcebook
    case onlineSupplement
    // TODO: category for Unearthed Arcana?
    
    /// Array of all cases.
    static let cases: [BookType] = [ .coreRulebook, .officialAdventure, .campaignSourcebook, .onlineSupplement ]
    
    /// Returns the string equivalent of the book type.
    var stringValue: String {
        return sharedRules.bookType[rawValue]
    }
}

/// Ability categorises the six basic abilities of D&D monsters and characters.
enum Ability : Int {
    case strength
    case dexterity
    case constitution
    case intelligence
    case wisdom
    case charisma
    
    /// Array of all cases.
    static let cases: [Ability] = [ .strength, .dexterity, .constitution, .intelligence, .wisdom, .charisma ]
    
    /// Returns the string equivalent of the ability.
    var stringValue: String {
        return sharedRules.ability[rawValue]
    }
    
    /// Returns the short string equivalent of the ability.
    var shortStringValue: String {
        return stringValue.substring(to: stringValue.characters.index(stringValue.startIndex, offsetBy: 3))
    }
}

/// Skill categorises the different possible skills of D&D monsters and characters.
///
/// Skills are grouped according to `Ability`, there are no skills for the `Constitution` ability.
enum Skill : Equatable, Hashable {
    enum StrengthSkill : Int {
        case athletics
    }
    case strength(StrengthSkill)
    
    enum DexteritySkill : Int {
        case acrobatics
        case sleightOfHand
        case stealth
    }
    case dexterity(DexteritySkill)
    
    enum IntelligenceSkill : Int {
        case arcana
        case history
        case investigation
        case nature
        case religion
    }
    case intelligence(IntelligenceSkill)
    
    enum WisdomSkill : Int {
        case animalHandling
        case insight
        case medicine
        case perception
        case survival
    }
    case wisdom(WisdomSkill)
    
    enum CharismaSkill : Int {
        case deception
        case intimidation
        case performance
        case persuasion
    }
    case charisma(CharismaSkill)
    
    var rawAbilityValue: Int {
        switch self {
        case .strength(_):
            return 0
        case .dexterity(_):
            return 1
        // Constitution would have the value 2, if it had associated skills.
        case .intelligence(_):
            return 3
        case .wisdom(_):
            return 4
        case .charisma(_):
            return 5
        }
    }

    var rawSkillValue: Int {
        switch self {
        case .strength(let skill):
            return skill.rawValue
        case .dexterity(let skill):
            return skill.rawValue
        case .intelligence(let skill):
            return skill.rawValue
        case .wisdom(let skill):
            return skill.rawValue
        case .charisma(let skill):
            return skill.rawValue
        }
    }
    
    var hashValue: Int {
        return "\(rawAbilityValue)\(rawSkillValue)".hashValue
    }

    init?(rawAbilityValue: Int, rawSkillValue: Int) {
        switch rawAbilityValue {
        case 0:
            guard let skill = StrengthSkill(rawValue: rawSkillValue) else { return nil }
            self = .strength(skill)
        case 1:
            guard let skill = DexteritySkill(rawValue: rawSkillValue) else { return nil }
            self = .dexterity(skill)
        // Constitution would have the value 2, if it had associated skills.
        case 3:
            guard let skill = IntelligenceSkill(rawValue: rawSkillValue) else { return nil }
            self = .intelligence(skill)
        case 4:
            guard let skill = WisdomSkill(rawValue: rawSkillValue) else { return nil }
            self = .wisdom(skill)
        case 5:
            guard let skill = CharismaSkill(rawValue: rawSkillValue) else { return nil }
            self = .charisma(skill)
        default:
            return nil
        }
    }
    
    /// Array of all cases.
    static let cases: [Skill] = [ .strength(.athletics), .dexterity(.acrobatics), .dexterity(.sleightOfHand), .dexterity(.stealth), .intelligence(.arcana), .intelligence(.history), .intelligence(.investigation), .intelligence(.nature), .intelligence(.religion), .wisdom(.animalHandling), .wisdom(.insight), .wisdom(.medicine), .wisdom(.perception), .wisdom(.survival), .charisma(.deception), .charisma(.intimidation), .charisma(.performance), .charisma(.persuasion) ]

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
enum Size : Int {
    case tiny
    case small
    case medium
    case large
    case huge
    case gargantuan
    
    /// Array of all cases.
    static let cases: [Size] = [ .tiny, .small, .medium, .large, .huge, .gargantuan ]
    
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
enum Alignment : Int {
    case unaligned
    case lawfulGood
    case lawfulNeutral
    case lawfulEvil
    case neutralGood
    case neutral
    case neutralEvil
    case chaoticGood
    case chaoticNeutral
    case chaoticEvil
    
    /// Array of all cases.
    static let cases: [Alignment] = [ .unaligned, .lawfulGood, .lawfulNeutral, .lawfulEvil, .neutralGood, .neutral, .neutralEvil, .chaoticGood, .chaoticNeutral, .chaoticEvil ]
    
    /// The set of lawful alignments.
    static let lawfulAlignments: Set<Alignment> = [ .lawfulGood, .lawfulNeutral, .lawfulEvil ]
    
    /// The set of choatic alignments.
    static let chaoticAlignments: Set<Alignment> = [ .chaoticGood, .chaoticNeutral, .chaoticEvil ]
    
    /// The set of good alignments.
    static let goodAlignments: Set<Alignment> = [ .lawfulGood, .neutralGood, .chaoticGood ]
    
    /// The set of evil alignments.
    static let evilAlignments: Set<Alignment> = [ .lawfulEvil, .neutralEvil, .chaoticEvil ]
    
    /// Returns the string equivalent of the alignment.
    var stringValue: String {
        return sharedRules.alignment[rawValue]
    }
}

/// MonsterType categorises the different types of monsters.
enum MonsterType : Int {
    case aberration
    case beast
    case celestial
    case construct
    case dragon
    case elemental
    case fey
    case fiend
    case giant
    case humanoid
    case monstrosity
    case ooze
    case plant
    case undead
    
    /// Array of all cases.
    static let cases: [MonsterType] = [ .aberration, .beast, .celestial, .construct, .dragon, .elemental, .fey, .fiend, .giant, .humanoid, .monstrosity, .ooze, .plant, .undead ]
    
    /// Returns the string equivalent of the monster type.
    var stringValue: String {
        return sharedRules.monsterType[rawValue]
    }
}

/// Environment categorises the different environments in which monsters can be found.
enum Environment : Int {
    case arctic
    case coastal
    case desert
    case forest
    case grassland
    case hill
    case mountain
    case swamp
    case underdark
    case underwater
    case urban
    
    /// Array of all cases.
    static let cases: [Environment] = [ .arctic, .coastal, .desert, .forest, .grassland, .hill, .mountain, .swamp, .underdark, .underwater, .urban ]
    
    /// Returns the string equivalent of the environment.
    var stringValue: String {
        return sharedRules.environment[rawValue]
    }
}

/// Race categorises the basic races of D&D.
///
/// Races can have sub-types which are represented here as nested enums.
enum Race : Equatable, Hashable {
    // Player's Handbook races.
    enum DwarfSubrace : Int {
        case hillDwarf
        case mountainDwarf
        
        // Sword Coast Adventurer's Guide subraces.
        case grayDwarf
    }
    case dwarf(DwarfSubrace)
    
    enum ElfSubrace : Int {
        case highElf
        case woodElf
        case drow
        
        // Dungeon Master's Guide subraces.
        case eladrin
    }
    case elf(ElfSubrace)
    
    enum HalflingSubrace : Int {
        case lightfoot
        case stout
    }
    case halfling(HalflingSubrace)
    
    case human
    case dragonborn
    
    enum GnomeSubrace : Int {
        case forestGnome
        case rockGnome
        
        // Elemental Evil subraces.
        case deepGnome
    }
    case gnome(GnomeSubrace)
    
    case halfElf
    case halfOrc
    case tiefling
    
    // Dungeon Master's Guide races.
    case aasimar
    
    // Elemental Evil races.
    case aarakocra
    
    enum GenasiSubrace : Int {
        case airGenasi
        case earthGenasi
        case fireGenasi
        case waterGenasi
    }
    case genasi(GenasiSubrace)
    
    case goliath
    
    var rawRaceValue: Int {
        switch self {
        case .dwarf(_):
            return 0
        case .elf(_):
            return 1
        case .halfling(_):
            return 2
        case .human:
            return 3
        case .dragonborn:
            return 4
        case .gnome(_):
            return 5
        case .halfElf:
            return 6
        case .halfOrc:
            return 7
        case .tiefling:
            return 8
        case .aasimar:
            return 9
        case .aarakocra:
            return 10
        case .genasi(_):
            return 11
        case .goliath:
            return 12
        }
    }
    
    var rawSubraceValue: Int? {
        switch self {
        case .dwarf(let subrace):
            return subrace.rawValue
        case .elf(let subrace):
            return subrace.rawValue
        case .halfling(let subrace):
            return subrace.rawValue
        case .human:
            return nil
        case .dragonborn:
            return nil
        case .gnome(let subrace):
            return subrace.rawValue
        case .halfElf:
            return nil
        case .halfOrc:
            return nil
        case .tiefling:
            return nil
        case .aasimar:
            return nil
        case .aarakocra:
            return nil
        case .genasi(let subrace):
            return subrace.rawValue
        case .goliath:
            return nil
        }
    }
    
    var hashValue: Int {
        return "\(rawRaceValue)\(rawSubraceValue ?? 0)".hashValue
    }
    
    init?(rawRaceValue: Int, rawSubraceValue: Int?) {
        switch rawRaceValue {
        case 0:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = DwarfSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .dwarf(subrace)
        case 1:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = ElfSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .elf(subrace)
        case 2:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = HalflingSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .halfling(subrace)
        case 3:
            guard rawSubraceValue == nil else { return nil }
            self = .human
        case 4:
            guard rawSubraceValue == nil else { return nil }
            self = .dragonborn
        case 5:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = GnomeSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .gnome(subrace)
        case 6:
            guard rawSubraceValue == nil else { return nil }
            self = .halfElf
        case 7:
            guard rawSubraceValue == nil else { return nil }
            self = .halfOrc
        case 8:
            guard rawSubraceValue == nil else { return nil }
            self = .tiefling
        case 9:
            guard rawSubraceValue == nil else { return nil }
            self = .aasimar
        case 10:
            guard rawSubraceValue == nil else { return nil }
            self = .aarakocra
        case 11:
            guard let rawSubraceValue = rawSubraceValue else { return nil }
            guard let subrace = GenasiSubrace(rawValue: rawSubraceValue) else { return nil }
            self = .genasi(subrace)
        case 12:
            guard rawSubraceValue == nil else { return nil }
            self = .goliath
        default:
            return nil
        }
    }
    
    /// Array of all cases.
    static let cases: [Race] = [ .dwarf(.hillDwarf), .dwarf(.mountainDwarf), .dwarf(.grayDwarf), .elf(.highElf), .elf(.woodElf), .elf(.drow), .elf(.eladrin), .halfling(.lightfoot), .halfling(.stout), .human, .dragonborn, .gnome(.forestGnome), .gnome(.rockGnome), .gnome(.deepGnome), .halfElf, .halfOrc, .tiefling, .aasimar, .aarakocra, .genasi(.airGenasi), .genasi(.earthGenasi), .genasi(.fireGenasi), .genasi(.waterGenasi), .goliath ]

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
    
    /// Returns the string equivalent of the given primary race raw value.
    static func stringValue(forRawRaceValue rawRaceValue: Int) -> String {
        return sharedRules.race[rawRaceValue]
    }
}

func ==(lhs: Race, rhs: Race) -> Bool {
    return lhs.rawRaceValue == rhs.rawRaceValue && ((lhs.rawSubraceValue == nil && rhs.rawSubraceValue == nil) || (lhs.rawSubraceValue != nil && rhs.rawSubraceValue != nil && lhs.rawSubraceValue! == rhs.rawSubraceValue!))
}

/// CharacterClass organises the different classes of player characters.
enum CharacterClass : Int {
    case barbarian
    case bard
    case cleric
    case druid
    case fighter
    case monk
    case paladin
    case ranger
    case rogue
    case sorcerer
    case warlock
    case wizard
    
    /// Array of all cases.
    static let cases: [CharacterClass] = [ .barbarian, .bard, .cleric, .druid, .fighter, .monk, .paladin, .ranger, .rogue, .sorcerer, .warlock, .wizard ]
    
    /// Returns the string equivalent of the character class.
    var stringValue: String {
        return sharedRules.characterClass[rawValue]
    }
}

/// Background organises the different possible backgrounds of player characters.
enum Background : Int {
    // Player's Handbook backgrounds.
    case acolyte
    case charlatan
    case criminal
    case entertainer
    case folkHero
    case guildArtisan
    case hermit
    case noble
    case outlander
    case sage
    case sailor
    case soldier
    case urchin
    
    // Sword Coast Adventurer's Guide backgrounds.
    case cityWatch
    case clanCrafter
    case cloisteredScholar
    case courtier
    case factionAgent
    case farTraveler
    case inheritor
    case knightOfTheOrder
    case mercenaryVeteran
    case urbanBountyHunter
    case waterdhavianNoble
    
    /// Array of all cases.
    static let cases: [Background] = [ .acolyte, .charlatan, .criminal, .entertainer, .folkHero, .guildArtisan, .hermit, .noble, .outlander, .sage, .sailor, .soldier, .urchin, .cityWatch, .clanCrafter, .cloisteredScholar, .courtier, .factionAgent, .farTraveler, .inheritor, .knightOfTheOrder, .mercenaryVeteran, .urbanBountyHunter, .waterdhavianNoble ]
    
    /// Returns the string equivalent of the background.
    var stringValue: String {
        return sharedRules.background[rawValue]
    }
}

/// Armor that can be worn by players and monsters.
enum ArmorType : Int {
    case none
    case natural

    // Light Armor
    case padded
    case leather
    case studdedLeather
    
    // Medium Armor
    case hide
    case chainShirt
    case scaleMail
    case breastplate
    case halfPlate
    
    // Heavy Armor
    case ringMail
    case chainMail
    case splint
    case plate
    
    // Monster-specific Armor.
    case scraps
    case bardingScraps
    case patchwork
    
    /// Array of all cases.
    static let cases: [ArmorType] = [ .none, .natural, .padded, .leather, .studdedLeather, .hide, .chainShirt, .scaleMail, .breastplate, .halfPlate, .ringMail, .chainMail, .splint, .plate, .scraps, .bardingScraps, .patchwork ]
    
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
    var hasStealthDisadvantage: Bool {
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
enum AttackType : Int {
    case all
    case nonmagical
    case nonmagicalNotAdamantine
    case nonmagicalNotSilvered
    case magical
    case magicalByGood
}

/// Types of damage that can be dealt by attacks.
enum DamageType : Int {
    case acid
    case bludgeoning
    case cold
    case fire
    case force
    case lightning
    case necrotic
    case piercing
    case poison
    case psychic
    case radiant
    case slashing
    case thunder
    
    /// Array of all cases.
    static let cases: [DamageType] = [ .acid, .bludgeoning, .cold, .fire, .force, .lightning, .necrotic, .piercing, .poison, .psychic, .radiant, .slashing, .thunder ]
    
    /// Returns the string equivalent of the damage type.
    var stringValue: String {
        return sharedRules.damageType[rawValue]
    }
}

enum Condition : Int {
    // TODO: deal with exhaustion, and its six levels
    case blinded
    case charmed
    case deafened
    case exhaustion
    case frightened
    case grappled
    case incapacitated
    case invisible
    case paralyzed
    case petrified
    case poisoned
    case prone
    case restrained
    case stunned
    case unconcious
    
    /// Array of all cases.
    static let cases: [Condition] = [ .blinded, .charmed, .deafened, .exhaustion, .frightened, .grappled, .incapacitated, .invisible, .paralyzed, .petrified, .poisoned, .prone, .restrained, .stunned, .unconcious ]
    
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
enum LanguageOption : Int {
    case usuallyCommon
    case knewInLife
    case ofItsCreator
    case oneOfItsCreator
    case anyOne
    case anyTwo
    case anyFour
    case upToFive
    case anySix
}

/// MagicSchool categorises the different schools of magic that spells can be categorized under.
enum MagicSchool : Int {
    case abjuration
    case conjuration
    case divination
    case enchantment
    case evocation
    case illusion
    case necromancy
    case transmutation
    
    /// Array of all cases.
    static let cases: [MagicSchool] = [ .abjuration, .conjuration, .divination, .enchantment, .evocation, .illusion, .necromancy, .transmutation ]
    
    /// Returns the string equivalent of the condition.
    var stringValue: String {
        return sharedRules.magicSchool[rawValue]
    }
}

/// SpellRange represents the base of the range of a spell.
enum SpellRange : Int {
    case distance
    case centeredOnSelf
    case touch
    case sight
    case special
    case unlimited
}

/// SpellRangeShape represents the shape of a spell's effect.
enum SpellRangeShape : Int {
    case radius
    case sphere
    case hemisphere
    case cube
    case cone
    case line
}

/// SpellDuration represents the durations of a spell's effect.
enum SpellDuration : Int {
    case instantaneous
    case time
    case maxTime
    case rounds
    case maxRounds
    case untilDispelled
    case untilDispelledOrTriggered
    case special
}

/// Difficulty of an encounter.
/// - **None**: the encounter poses no difficulty to the players.
/// - **Easy**: victory is pretty much guaranteed, aside from the loss of a few hit points.
/// - **Medium**: characters should emerge victorious, aside from one or two scary moments.
/// - **Hard**: a slim chance that one or more characers might die.
/// - **Deadly**: an encounter that could be lethal for one or more characters.
enum EncounterDifficulty {
    case none
    case easy
    case medium
    case hard
    case deadly
}

/// Role of a creature in combat.
/// - **Foe**: a monster controlled by the DM, unfriendly to the players.
/// - **Friend**: a monster controlled by the DM, friendly to the players.
/// - **Player**: a monster or character controlled by a player.
enum CombatRole : Int {
    case foe
    case friend
    case player
}

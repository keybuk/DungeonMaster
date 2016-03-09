//
//  Importer.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

func importIfNeeded() {
    let filename = NSBundle.mainBundle().pathForResource("Data", ofType: "plist")!
    let data = NSDictionary(contentsOfFile: filename)!

    let defaults = NSUserDefaults.standardUserDefaults()
    let dataVersion = defaults.objectForKey("DataVersion") as? Int
    let plistVersion = data["version"]! as! Int

    // Shenanigans to stop Swift complaining about "unreachable code" as it optimizes out the other path.
    func inSimulator() -> Bool { return TARGET_OS_SIMULATOR != 0 }
    if inSimulator() {
        print("Running in simulator: importing data from \(plistVersion)")
    } else {
        if let dataVersion = dataVersion {
            if dataVersion == plistVersion {
                return
            }
            
            print("Importing data from \(plistVersion), replacing \(dataVersion)")
        } else {
            print("Importing data from \(plistVersion)")
        }
    }
    
    // Combatants can reference monsters, which may be about to be deleted. Collect the names of these monsters so we can find them again later.
    var combatants: [String:[Combatant]] = [:]
    let combatantFetchRequest = NSFetchRequest(entity: Model.Combatant)
    for combatant in try! managedObjectContext.executeFetchRequest(combatantFetchRequest) as! [Combatant] {
        guard let count = combatant.monster?.sources.count where count > 0 else { continue }

        if let referingCombatants = combatants[combatant.monster!.name] {
            combatants[combatant.monster!.name] = referingCombatants + [ combatant ]
        } else {
            combatants[combatant.monster!.name] = [ combatant ]
        }
    }
    
    // Delete all books. The delete will cascade and remove all information sourced from the books.
    var adventures: [String:[Adventure]] = [:]
    let bookFetchRequest = NSFetchRequest(entity: Model.Book)
    for book in try! managedObjectContext.executeFetchRequest(bookFetchRequest) as! [Book] {
        // Save the set of adventures that this book refers to, so we can reconnect them again later.
        for case let adventure as Adventure in book.adventures {
            if let referingAdventures = adventures[book.name] {
                adventures[book.name] = referingAdventures + [ adventure ]
            } else {
                adventures[book.name] = [ adventure ]
            }
        }
        
        managedObjectContext.deleteObject(book)
    }
    
    // Collect the set of tags and languages so we can re-use them on the next import.
    var tags: [String:Tag] = [:]
    let tagFetchRequest = NSFetchRequest(entity: Model.Tag)
    for tag in try! managedObjectContext.executeFetchRequest(tagFetchRequest) as! [Tag] {
        tags[tag.name] = tag
    }
    
    var languages: [String:Language] = [:]
    let languageFetchRequest = NSFetchRequest(entity: Model.Language)
    for language in try! managedObjectContext.executeFetchRequest(languageFetchRequest) as! [Language] {
        languages[language.name] = language
    }
    
    // Import books.
    var books: [Book] = []
    let bookDatas = data["books"] as! [NSDictionary]
    for bookData in bookDatas {
        let name = bookData["name"] as! String
        let book = Book(name: name, inManagedObjectContext: managedObjectContext)
        book.type = BookType(rawValue: bookData["type"]!.integerValue)!
        
        // Reconnect the book back to its previous adventures.
        if let referingAdventures = adventures[name] {
            book.adventures = NSSet(array: referingAdventures)
            adventures[name] = nil
        }
        
        books.append(book)
    }
    
    // Import monsters.
    let monsterDatas = data["monsters"] as! [NSDictionary]
    for monsterData in monsterDatas {
        let name = monsterData["name"] as! String
        let monster = Monster(name: name, inManagedObjectContext: managedObjectContext)
        
        // Combatant might refer to a monster by an old name.
        let names = monsterData["names"] as! [String]
        for name in names {
            if let referingCombatants = combatants[name] {
                for combatant in referingCombatants {
                    combatant.monster = monster
                }
            }
        }
        
        let sourceDatas = monsterData["sources"] as! [NSDictionary]
        for sourceData in sourceDatas {
            let bookIndex = sourceData["book"]!.integerValue
            let book = books[bookIndex]

            let page = sourceData["page"]!.integerValue
            
            let source = Source(book: book, page: page, monster: monster, inManagedObjectContext: managedObjectContext)
            
            if let section = sourceData["section"] as? String {
                source.section = section
            }
        }
        
        let environmentValues = monsterData["environments"] as! [NSNumber]
        for environmentValue in environmentValues {
            let environment = Environment(rawValue: environmentValue.integerValue)!
            let _ = MonsterEnvironment(monster: monster, environment: environment, inManagedObjectContext: managedObjectContext)
        }
        
        var monsterTags: [Tag] = []
        let tagNames = monsterData["tags"] as! [String]
        for tagName in tagNames {
            if let tag = tags[tagName] {
                monsterTags.append(tag)
            } else {
                let tag = Tag(name: tagName, inManagedObjectContext: managedObjectContext)
                tags[tagName] = tag
                monsterTags.append(tag)
            }
        }
        monster.tags = NSSet(array: monsterTags)

        let alignmentOptionDatas = monsterData["alignmentOptions"] as! [[NSNumber]]
        for alignmentOptionData in alignmentOptionDatas {
            let alignmentOption = AlignmentOption(monster: monster, inManagedObjectContext: managedObjectContext)
            alignmentOption.alignment = Alignment(rawValue: alignmentOptionData[0].integerValue)!

            if alignmentOptionData.count > 1 {
                alignmentOption.weight = alignmentOptionData[1].floatValue
            }
        }
        
        let armorDatas = monsterData["armor"] as! [[String: AnyObject]]
        for armorData in armorDatas {
            let armor = Armor(monster: monster, inManagedObjectContext: managedObjectContext)
            armor.setValuesForKeysWithDictionary(armorData)
        }
        
        let savingThrowData = monsterData["savingThrows"] as! [String: NSNumber]
        for (savingThrowNumber, savingThrowModifier) in savingThrowData {
            let savingThrow = Ability(rawValue: Int(savingThrowNumber)!)!
            let monsterSavingThrow = MonsterSavingThrow(monster: monster, savingThrow: savingThrow, inManagedObjectContext: managedObjectContext)
            monsterSavingThrow.modifier = savingThrowModifier.integerValue
        }
        
        let skillAbilityData = monsterData["skills"] as! [String: [String: NSNumber]]
        for (skillAbilityNumber, skillData) in skillAbilityData {
            for (skillNumber, skillModifier) in skillData {
                let skill = Skill(rawAbilityValue: Int(skillAbilityNumber)!, rawSkillValue: Int(skillNumber)!)!
                let monsterSkill = MonsterSkill(monster: monster, skill: skill, inManagedObjectContext: managedObjectContext)
                monsterSkill.modifier = skillModifier.integerValue
            }
        }
        
        let damageVulnerabilityDatas = monsterData["damageVulnerabilities"] as! [[String: AnyObject]]
        for damageVulnerabilityDate in damageVulnerabilityDatas {
            let damageVulnerability = DamageVulnerability(monster: monster, inManagedObjectContext: managedObjectContext)
            damageVulnerability.setValuesForKeysWithDictionary(damageVulnerabilityDate)
        }

        let damageResistanceDatas = monsterData["damageResistances"] as! [[String: AnyObject]]
        for damageResistanceData in damageResistanceDatas {
            let damageResistance = DamageResistance(monster: monster, inManagedObjectContext: managedObjectContext)
            damageResistance.setValuesForKeysWithDictionary(damageResistanceData)
        }
        
        let damageResistanceOptionDatas = monsterData["damageResistanceOptions"] as! [[String: AnyObject]]
        for damageResistanceOptionData in damageResistanceOptionDatas {
            let damageResistanceOption = DamageResistanceOption(monster: monster, inManagedObjectContext: managedObjectContext)
            damageResistanceOption.setValuesForKeysWithDictionary(damageResistanceOptionData)
        }

        let damageImmunityDates = monsterData["damageImmunities"] as! [[String: AnyObject]]
        for damageImmunityData in damageImmunityDates {
            let damageImmunity = DamageImmunity(monster: monster, inManagedObjectContext: managedObjectContext)
            damageImmunity.setValuesForKeysWithDictionary(damageImmunityData)
        }

        let conditionImmunityDatas = monsterData["conditionImmunities"] as! [[String: AnyObject]]
        for conditionImmunityData in conditionImmunityDatas {
            let conditionImmunity = ConditionImmunity(monster: monster, inManagedObjectContext: managedObjectContext)
            conditionImmunity.setValuesForKeysWithDictionary(conditionImmunityData)
        }

        var monsterLanguages: [Language] = []
        let languageSpokenNames = monsterData["languagesSpoken"] as! [String]
        for languageName in languageSpokenNames {
            if let language = languages[languageName] {
                monsterLanguages.append(language)
            } else {
                let language = Language(name: languageName, inManagedObjectContext: managedObjectContext)
                languages[languageName] = language
                monsterLanguages.append(language)
            }
        }
        monster.languagesSpoken = NSSet(array: monsterLanguages)
        
        monsterLanguages.removeAll()
        let languageUnderstoodNames = monsterData["languagesUnderstood"] as! [String]
        for languageName in languageUnderstoodNames {
            if let language = languages[languageName] {
                monsterLanguages.append(language)
            } else {
                let language = Language(name: languageName, inManagedObjectContext: managedObjectContext)
                languages[languageName] = language
                monsterLanguages.append(language)
            }
        }
        monster.languagesUnderstood = NSSet(array: monsterLanguages)

        let info = monsterData["info"] as! [String: AnyObject]
        monster.setValuesForKeysWithDictionary(info)
        
        let traitDatas = monsterData["traits"] as! [NSDictionary]
        for traitData in traitDatas {
            let name = traitData["name"] as! String
            let text = traitData["text"] as! String
            let _ = Trait(monster: monster, name: name, text: text, inManagedObjectContext: managedObjectContext)
        }
        
        let actionDatas = monsterData["actions"] as! [NSDictionary]
        for actionData in actionDatas {
            let name = actionData["name"] as! String
            let text = actionData["text"] as! String
            let _ = Action(monster: monster, name: name, text: text, inManagedObjectContext: managedObjectContext)
        }

        let reactionDatas = monsterData["reactions"] as! [NSDictionary]
        for reactionData in reactionDatas {
            let name = reactionData["name"] as! String
            let text = reactionData["text"] as! String
            let _ = Reaction(monster: monster, name: name, text: text, inManagedObjectContext: managedObjectContext)
        }

        let legendaryActionDatas = monsterData["legendaryActions"] as! [NSDictionary]
        for legendaryActionData in legendaryActionDatas {
            let name = legendaryActionData["name"] as! String
            let text = legendaryActionData["text"] as! String
            let _ = LegendaryAction(monster: monster, name: name, text: text, inManagedObjectContext: managedObjectContext)
        }
        
        if let lairData = monsterData["lair"] as? NSDictionary {
            let lair = Lair(inManagedObjectContext: managedObjectContext)

            let info = lairData["info"] as! [String: AnyObject]
            lair.setValuesForKeysWithDictionary(info)
            
            let lairActionTexts = lairData["lairActions"] as! [String]
            for text in lairActionTexts {
                let _ = LairAction(lair: lair, text: text, inManagedObjectContext: managedObjectContext)
            }

            let lairTraitsTexts = lairData["lairTraits"] as! [String]
            for text in lairTraitsTexts {
                let _ = LairTrait(lair: lair, text: text, inManagedObjectContext: managedObjectContext)
            }

            let regionalEffectsTexts = lairData["regionalEffects"] as! [String]
            for text in regionalEffectsTexts {
                let _ = RegionalEffect(lair: lair, text: text, inManagedObjectContext: managedObjectContext)
            }

            monster.lair = lair
        }
        
        // hitPoints can be entirely optional; since for all but one monster (the Demilich) it's simply the average value of the hit dice.
        if monster.hitPoints != monster.hitDice.averageValue {
            print("\(monster.name) has unusual HP: \(monster.hitPoints!), expected \(monster.hitDice.averageValue)")
        } else {
            monster.hitPoints = nil
        }
        
        // Sanity check saving throws and skills against modifiers and proficiency bonus.
        if monster.modifier(forSavingThrow: .Strength) != monster.modifier(forAbility: .Strength) && monster.modifier(forSavingThrow: .Strength) != monster.modifier(forAbility: .Strength) + monster.proficiencyBonus {
            print("\(monster.name) has unusual strength saving throw: \(monster.modifier(forSavingThrow: .Strength)), expected \(monster.modifier(forAbility: .Strength)) or \(monster.modifier(forAbility: .Strength) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .Strength(.Athletics)) != monster.modifier(forAbility: .Strength) && monster.modifier(forSkill: .Strength(.Athletics)) != monster.modifier(forAbility: .Strength) + monster.proficiencyBonus && monster.modifier(forSkill: .Strength(.Athletics)) != monster.modifier(forAbility: .Strength) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Str (Athletics) skill: \(monster.modifier(forSkill: .Strength(.Athletics))), expected \(monster.modifier(forAbility: .Strength)), \(monster.modifier(forAbility: .Strength) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Strength) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSavingThrow: .Dexterity) != monster.modifier(forAbility: .Dexterity) && monster.modifier(forSavingThrow: .Dexterity) != monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus {
            print("\(monster.name) has unusual dexterity saving throw: \(monster.modifier(forSavingThrow: .Dexterity)), expected \(monster.modifier(forAbility: .Dexterity)) or \(monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .Dexterity(.Acrobatics)) != monster.modifier(forAbility: .Dexterity) && monster.modifier(forSkill: .Dexterity(.Acrobatics)) != monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus && monster.modifier(forSkill: .Dexterity(.Acrobatics)) != monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Acrobatics) skill: \(monster.modifier(forSkill: .Dexterity(.Acrobatics))), expected \(monster.modifier(forAbility: .Dexterity)), \(monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .Dexterity(.SleightOfHand)) != monster.modifier(forAbility: .Dexterity) && monster.modifier(forSkill: .Dexterity(.SleightOfHand)) != monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus && monster.modifier(forSkill: .Dexterity(.SleightOfHand)) != monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Sleight of Hand) skill: \(monster.modifier(forSkill: .Dexterity(.SleightOfHand))), expected \(monster.modifier(forAbility: .Dexterity)), \(monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .Dexterity(.Stealth)) != monster.modifier(forAbility: .Dexterity) && monster.modifier(forSkill: .Dexterity(.Stealth)) != monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus && monster.modifier(forSkill: .Dexterity(.Stealth)) != monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Stealth) skill: \(monster.modifier(forSkill: .Dexterity(.Stealth))), expected \(monster.modifier(forAbility: .Dexterity)), \(monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Dexterity) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSavingThrow: .Constitution) != monster.modifier(forAbility: .Constitution) && monster.modifier(forSavingThrow: .Constitution) != monster.modifier(forAbility: .Constitution) + monster.proficiencyBonus {
            print("\(monster.name) has unusual constitution saving throw: \(monster.modifier(forSavingThrow: .Constitution)), expected \(monster.modifier(forAbility: .Constitution)) or \(monster.modifier(forAbility: .Constitution) + monster.proficiencyBonus)")
        }
        
        if monster.modifier(forSavingThrow: .Intelligence) != monster.modifier(forAbility: .Intelligence) && monster.modifier(forSavingThrow: .Intelligence) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus {
            print("\(monster.name) has unusual intelligence saving throw: \(monster.modifier(forSavingThrow: .Intelligence)), expected \(monster.modifier(forAbility: .Intelligence)) or \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .Intelligence(.Arcana)) != monster.modifier(forAbility: .Intelligence) && monster.modifier(forSkill: .Intelligence(.Arcana)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .Intelligence(.Arcana)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Arcana) skill: \(monster.modifier(forSkill: .Intelligence(.Arcana))), expected \(monster.modifier(forAbility: .Intelligence)), \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2)")
        }
    
        if monster.modifier(forSkill: .Intelligence(.History)) != monster.modifier(forAbility: .Intelligence) && monster.modifier(forSkill: .Intelligence(.History)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .Intelligence(.History)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (History) skill: \(monster.modifier(forSkill: .Intelligence(.History))), expected \(monster.modifier(forAbility: .Intelligence)), \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .Intelligence(.Investigation)) != monster.modifier(forAbility: .Intelligence) && monster.modifier(forSkill: .Intelligence(.Investigation)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .Intelligence(.Investigation)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Investigation) skill: \(monster.modifier(forSkill: .Intelligence(.Investigation))), expected \(monster.modifier(forAbility: .Intelligence)), \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .Intelligence(.Nature)) != monster.modifier(forAbility: .Intelligence) && monster.modifier(forSkill: .Intelligence(.Nature)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .Intelligence(.Nature)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Nature) skill: \(monster.modifier(forSkill: .Intelligence(.Nature))), expected \(monster.modifier(forAbility: .Intelligence)), \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .Intelligence(.Religion)) != monster.modifier(forAbility: .Intelligence) && monster.modifier(forSkill: .Intelligence(.Religion)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .Intelligence(.Religion)) != monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Religion) skill: \(monster.modifier(forSkill: .Intelligence(.Religion))), expected \(monster.modifier(forAbility: .Intelligence)), \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Intelligence) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSavingThrow: .Wisdom) != monster.modifier(forAbility: .Wisdom) && monster.modifier(forSavingThrow: .Wisdom) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus {
            print("\(monster.name) has unusual wisdom saving throw: \(monster.modifier(forSavingThrow: .Wisdom)), expected \(monster.modifier(forAbility: .Wisdom)) or \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .Wisdom(.AnimalHandling)) != monster.modifier(forAbility: .Wisdom) && monster.modifier(forSkill: .Wisdom(.AnimalHandling)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .Wisdom(.AnimalHandling)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Animal Handling) skill: \(monster.modifier(forSkill: .Wisdom(.AnimalHandling))), expected \(monster.modifier(forAbility: .Wisdom)), \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .Wisdom(.Medicine)) != monster.modifier(forAbility: .Wisdom) && monster.modifier(forSkill: .Wisdom(.Medicine)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .Wisdom(.Medicine)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Medicine) skill: \(monster.modifier(forSkill: .Wisdom(.Medicine))), expected \(monster.modifier(forAbility: .Wisdom)), \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .Wisdom(.Perception)) != monster.modifier(forAbility: .Wisdom) && monster.modifier(forSkill: .Wisdom(.Perception)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .Wisdom(.Perception)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Perception) skill: \(monster.modifier(forSkill: .Wisdom(.Perception))), expected \(monster.modifier(forAbility: .Wisdom)), \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .Wisdom(.Insight)) != monster.modifier(forAbility: .Wisdom) && monster.modifier(forSkill: .Wisdom(.Insight)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .Wisdom(.Insight)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Insight) skill: \(monster.modifier(forSkill: .Wisdom(.Insight))), expected \(monster.modifier(forAbility: .Wisdom)), \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .Wisdom(.Survival)) != monster.modifier(forAbility: .Wisdom) && monster.modifier(forSkill: .Wisdom(.Survival)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .Wisdom(.Survival)) != monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Survival) skill: \(monster.modifier(forSkill: .Wisdom(.Survival))), expected \(monster.modifier(forAbility: .Wisdom)), \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Wisdom) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSavingThrow: .Charisma) != monster.modifier(forAbility: .Charisma) && monster.modifier(forSavingThrow: .Charisma) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus {
            print("\(monster.name) has unusual charisma saving throw: \(monster.modifier(forSavingThrow: .Charisma)), expected \(monster.modifier(forAbility: .Charisma)) or \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .Charisma(.Deception)) != monster.modifier(forAbility: .Charisma) && monster.modifier(forSkill: .Charisma(.Deception)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .Charisma(.Deception)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Deception) skill: \(monster.modifier(forSkill: .Charisma(.Deception))), expected \(monster.modifier(forAbility: .Charisma)), \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .Charisma(.Intimidation)) != monster.modifier(forAbility: .Charisma) && monster.modifier(forSkill: .Charisma(.Intimidation)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .Charisma(.Intimidation)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Intimidation) skill: \(monster.modifier(forSkill: .Charisma(.Intimidation))), expected \(monster.modifier(forAbility: .Charisma)), \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .Charisma(.Performance)) != monster.modifier(forAbility: .Charisma) && monster.modifier(forSkill: .Charisma(.Performance)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .Charisma(.Performance)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Performance) skill: \(monster.modifier(forSkill: .Charisma(.Performance))), expected \(monster.modifier(forAbility: .Charisma)), \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .Charisma(.Persuasion)) != monster.modifier(forAbility: .Charisma) && monster.modifier(forSkill: .Charisma(.Persuasion)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .Charisma(.Persuasion)) != monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2 {
                print("\(monster.name) has unusual Cha (Persuasion) skill: \(monster.modifier(forSkill: .Charisma(.Persuasion))), expected \(monster.modifier(forAbility: .Charisma)), \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .Charisma) + monster.proficiencyBonus * 2)")
        }
    }
    
    // Import spells.
    let spellDatas = data["spells"] as! [NSDictionary]
    for spellData in spellDatas {
        let name = spellData["name"] as! String
        let spell = Spell(name: name, inManagedObjectContext: managedObjectContext)
        
        let sourceDatas = spellData["sources"] as! [NSDictionary]
        for sourceData in sourceDatas {
            let bookIndex = sourceData["book"]!.integerValue
            let book = books[bookIndex]
            
            let page = sourceData["page"]!.integerValue
            
            let source = Source(book: book, page: page, spell: spell, inManagedObjectContext: managedObjectContext)
            
            if let section = sourceData["section"] as? String {
                source.section = section
            }
        }
        
        let classValues = spellData["classes"] as! [NSNumber]
        for classValue in classValues {
            let characterClass = CharacterClass(rawValue: classValue.integerValue)!
            let _ = SpellClass(spell: spell, characterClass: characterClass, inManagedObjectContext: managedObjectContext)
        }
        
        let info = spellData["info"] as! [String: AnyObject]
        spell.setValuesForKeysWithDictionary(info)
    }
    
    // Check that all the adventures got reconnected to their books.
    for (bookName, referingAdventures) in adventures {
        print("Book referred to by \(referingAdventures.count) adventures is missing: \(bookName)")
    }
    
    // Check that all the combatants got a monster.
    for (monsterName, referingCombatants) in combatants {
        for combatant in referingCombatants {
            if combatant.primitiveValueForKey("monster") == nil {
                print("Monster referred to by combatant is missing: \(monsterName)")
                break
            }
        }
    }

    // Done.
    try! managedObjectContext.save()

    defaults.setObject(plistVersion, forKey: "DataVersion")
    defaults.synchronize()
}
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
    let filename = Bundle.main.path(forResource: "Data", ofType: "plist")!
    let data = NSDictionary(contentsOfFile: filename)!

    let defaults = UserDefaults.standard
    let dataVersion = defaults.object(forKey: "DataVersion") as? Int
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
    let combatantFetchRequest = NSFetchRequest<Combatant>()
    combatantFetchRequest.entity = NSEntityDescription.entity(forModel: Model.Combatant, in: managedObjectContext)
    for combatant in try! managedObjectContext.fetch(combatantFetchRequest) {
        guard let count = combatant.monster?.sources.count, count > 0 else { continue }

        if let referingCombatants = combatants[combatant.monster!.name] {
            combatants[combatant.monster!.name] = referingCombatants + [ combatant ]
        } else {
            combatants[combatant.monster!.name] = [ combatant ]
        }
    }
    
    // Delete all books. The delete will cascade and remove all information sourced from the books.
    var adventures: [String:[Adventure]] = [:]
    let bookFetchRequest = NSFetchRequest<Book>()
    bookFetchRequest.entity = NSEntityDescription.entity(forModel: Model.Book, in: managedObjectContext)
    for book in try! managedObjectContext.fetch(bookFetchRequest) {
        // Save the set of adventures that this book refers to, so we can reconnect them again later.
        for case let adventure as Adventure in book.adventures {
            if let referingAdventures = adventures[book.name] {
                adventures[book.name] = referingAdventures + [ adventure ]
            } else {
                adventures[book.name] = [ adventure ]
            }
        }
        
        managedObjectContext.delete(book)
    }
    
    // Collect the set of tags and languages so we can re-use them on the next import.
    var tags: [String:Tag] = [:]
    let tagFetchRequest = NSFetchRequest<Tag>()
    tagFetchRequest.entity = NSEntityDescription.entity(forModel: Model.Tag, in: managedObjectContext)
    for tag in try! managedObjectContext.fetch(tagFetchRequest) {
        tags[tag.name] = tag
    }
    
    var languages: [String:Language] = [:]
    let languageFetchRequest = NSFetchRequest<Language>()
    languageFetchRequest.entity = NSEntityDescription.entity(forModel: Model.Language, in: managedObjectContext)
    for language in try! managedObjectContext.fetch(languageFetchRequest) {
        languages[language.name] = language
    }
    
    // Import books.
    var books: [Book] = []
    let bookDatas = data["books"] as! [NSDictionary]
    for bookData in bookDatas {
        let name = bookData["name"] as! String
        let book = Book(name: name, insertInto: managedObjectContext)
        book.type = BookType(rawValue: (bookData["type"]! as AnyObject).intValue)!
        
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
        let monster = Monster(name: name, insertInto: managedObjectContext)
        
        // Combatant might refer to a monster by an old name.
        let names = monsterData["names"] as! [String]
        for name in names {
            if let referingCombatants = combatants[name] {
                for combatant in referingCombatants {
                    combatant.monster = monster
                }
                combatants[name] = nil
            }
        }
        
        let sourceDatas = monsterData["sources"] as! [NSDictionary]
        for sourceData in sourceDatas {
            let bookIndex = (sourceData["book"]! as! NSNumber).intValue
            let book = books[bookIndex]

            let page = (sourceData["page"]! as! NSNumber).intValue
            
            let source = Source(book: book, page: page, monster: monster, insertInto: managedObjectContext)
            
            if let section = sourceData["section"] as? String {
                source.section = section
            }
        }
        
        let environmentValues = monsterData["environments"] as! [NSNumber]
        for environmentValue in environmentValues {
            let environment = Environment(rawValue: environmentValue.intValue)!
            let _ = MonsterEnvironment(monster: monster, environment: environment, insertInto: managedObjectContext)
        }
        
        var monsterTags: [Tag] = []
        let tagNames = monsterData["tags"] as! [String]
        for tagName in tagNames {
            if let tag = tags[tagName] {
                monsterTags.append(tag)
            } else {
                let tag = Tag(name: tagName, insertInto: managedObjectContext)
                tags[tagName] = tag
                monsterTags.append(tag)
            }
        }
        monster.tags = NSSet(array: monsterTags)

        let alignmentOptionDatas = monsterData["alignmentOptions"] as! [[NSNumber]]
        for alignmentOptionData in alignmentOptionDatas {
            let alignmentOption = AlignmentOption(monster: monster, insertInto: managedObjectContext)
            alignmentOption.alignment = Alignment(rawValue: alignmentOptionData[0].intValue)!

            if alignmentOptionData.count > 1 {
                alignmentOption.weight = alignmentOptionData[1].floatValue
            }
        }
        
        let armorDatas = monsterData["armor"] as! [[String: AnyObject]]
        for armorData in armorDatas {
            let armor = Armor(monster: monster, insertInto: managedObjectContext)
            armor.setValuesForKeys(armorData)
        }
        
        let savingThrowData = monsterData["savingThrows"] as! [String: NSNumber]
        for (savingThrowNumber, savingThrowModifier) in savingThrowData {
            let savingThrow = Ability(rawValue: Int(savingThrowNumber)!)!
            let monsterSavingThrow = MonsterSavingThrow(monster: monster, savingThrow: savingThrow, insertInto: managedObjectContext)
            monsterSavingThrow.modifier = savingThrowModifier.intValue
        }
        
        let skillAbilityData = monsterData["skills"] as! [String: [String: NSNumber]]
        for (skillAbilityNumber, skillData) in skillAbilityData {
            for (skillNumber, skillModifier) in skillData {
                let skill = Skill(rawAbilityValue: Int(skillAbilityNumber)!, rawSkillValue: Int(skillNumber)!)!
                let monsterSkill = MonsterSkill(monster: monster, skill: skill, insertInto: managedObjectContext)
                monsterSkill.modifier = skillModifier.intValue
            }
        }
        
        let damageVulnerabilityDatas = monsterData["damageVulnerabilities"] as! [[String: AnyObject]]
        for damageVulnerabilityDate in damageVulnerabilityDatas {
            let damageVulnerability = DamageVulnerability(monster: monster, insertInto: managedObjectContext)
            damageVulnerability.setValuesForKeys(damageVulnerabilityDate)
        }

        let damageResistanceDatas = monsterData["damageResistances"] as! [[String: AnyObject]]
        for damageResistanceData in damageResistanceDatas {
            let damageResistance = DamageResistance(monster: monster, insertInto: managedObjectContext)
            damageResistance.setValuesForKeys(damageResistanceData)
        }
        
        let damageResistanceOptionDatas = monsterData["damageResistanceOptions"] as! [[String: AnyObject]]
        for damageResistanceOptionData in damageResistanceOptionDatas {
            let damageResistanceOption = DamageResistanceOption(monster: monster, insertInto: managedObjectContext)
            damageResistanceOption.setValuesForKeys(damageResistanceOptionData)
        }

        let damageImmunityDates = monsterData["damageImmunities"] as! [[String: AnyObject]]
        for damageImmunityData in damageImmunityDates {
            let damageImmunity = DamageImmunity(monster: monster, insertInto: managedObjectContext)
            damageImmunity.setValuesForKeys(damageImmunityData)
        }

        let conditionImmunityDatas = monsterData["conditionImmunities"] as! [[String: AnyObject]]
        for conditionImmunityData in conditionImmunityDatas {
            let conditionImmunity = ConditionImmunity(monster: monster, insertInto: managedObjectContext)
            conditionImmunity.setValuesForKeys(conditionImmunityData)
        }

        var monsterLanguages: [Language] = []
        let languageSpokenNames = monsterData["languagesSpoken"] as! [String]
        for languageName in languageSpokenNames {
            if let language = languages[languageName] {
                monsterLanguages.append(language)
            } else {
                let language = Language(name: languageName, insertInto: managedObjectContext)
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
                let language = Language(name: languageName, insertInto: managedObjectContext)
                languages[languageName] = language
                monsterLanguages.append(language)
            }
        }
        monster.languagesUnderstood = NSSet(array: monsterLanguages)

        let info = monsterData["info"] as! [String: AnyObject]
        monster.setValuesForKeys(info)
        
        let traitDatas = monsterData["traits"] as! [NSDictionary]
        for traitData in traitDatas {
            let name = traitData["name"] as! String
            let text = traitData["text"] as! String
            let _ = Trait(monster: monster, name: name, text: text, insertInto: managedObjectContext)
        }
        
        let actionDatas = monsterData["actions"] as! [NSDictionary]
        for actionData in actionDatas {
            let name = actionData["name"] as! String
            let text = actionData["text"] as! String
            let _ = Action(monster: monster, name: name, text: text, insertInto: managedObjectContext)
        }

        let reactionDatas = monsterData["reactions"] as! [NSDictionary]
        for reactionData in reactionDatas {
            let name = reactionData["name"] as! String
            let text = reactionData["text"] as! String
            let _ = Reaction(monster: monster, name: name, text: text, insertInto: managedObjectContext)
        }

        let legendaryActionDatas = monsterData["legendaryActions"] as! [NSDictionary]
        for legendaryActionData in legendaryActionDatas {
            let name = legendaryActionData["name"] as! String
            let text = legendaryActionData["text"] as! String
            let _ = LegendaryAction(monster: monster, name: name, text: text, insertInto: managedObjectContext)
        }
        
        if let lairData = monsterData["lair"] as? NSDictionary {
            let lair = Lair(insertInto: managedObjectContext)

            let info = lairData["info"] as! [String: AnyObject]
            lair.setValuesForKeys(info)
            
            let lairActionTexts = lairData["lairActions"] as! [String]
            for text in lairActionTexts {
                let _ = LairAction(lair: lair, text: text, insertInto: managedObjectContext)
            }

            let lairTraitsTexts = lairData["lairTraits"] as! [String]
            for text in lairTraitsTexts {
                let _ = LairTrait(lair: lair, text: text, insertInto: managedObjectContext)
            }

            let regionalEffectsTexts = lairData["regionalEffects"] as! [String]
            for text in regionalEffectsTexts {
                let _ = RegionalEffect(lair: lair, text: text, insertInto: managedObjectContext)
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
        if monster.modifier(forSavingThrow: .strength) != monster.modifier(forAbility: .strength) && monster.modifier(forSavingThrow: .strength) != monster.modifier(forAbility: .strength) + monster.proficiencyBonus {
            print("\(monster.name) has unusual strength saving throw: \(monster.modifier(forSavingThrow: .strength)), expected \(monster.modifier(forAbility: .strength)) or \(monster.modifier(forAbility: .strength) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .strength(.athletics)) != monster.modifier(forAbility: .strength) && monster.modifier(forSkill: .strength(.athletics)) != monster.modifier(forAbility: .strength) + monster.proficiencyBonus && monster.modifier(forSkill: .strength(.athletics)) != monster.modifier(forAbility: .strength) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Str (Athletics) skill: \(monster.modifier(forSkill: .strength(.athletics))), expected \(monster.modifier(forAbility: .strength)), \(monster.modifier(forAbility: .strength) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .strength) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSavingThrow: .dexterity) != monster.modifier(forAbility: .dexterity) && monster.modifier(forSavingThrow: .dexterity) != monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus {
            print("\(monster.name) has unusual dexterity saving throw: \(monster.modifier(forSavingThrow: .dexterity)), expected \(monster.modifier(forAbility: .dexterity)) or \(monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .dexterity(.acrobatics)) != monster.modifier(forAbility: .dexterity) && monster.modifier(forSkill: .dexterity(.acrobatics)) != monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus && monster.modifier(forSkill: .dexterity(.acrobatics)) != monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Acrobatics) skill: \(monster.modifier(forSkill: .dexterity(.acrobatics))), expected \(monster.modifier(forAbility: .dexterity)), \(monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .dexterity(.sleightOfHand)) != monster.modifier(forAbility: .dexterity) && monster.modifier(forSkill: .dexterity(.sleightOfHand)) != monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus && monster.modifier(forSkill: .dexterity(.sleightOfHand)) != monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Sleight of Hand) skill: \(monster.modifier(forSkill: .dexterity(.sleightOfHand))), expected \(monster.modifier(forAbility: .dexterity)), \(monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .dexterity(.stealth)) != monster.modifier(forAbility: .dexterity) && monster.modifier(forSkill: .dexterity(.stealth)) != monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus && monster.modifier(forSkill: .dexterity(.stealth)) != monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Stealth) skill: \(monster.modifier(forSkill: .dexterity(.stealth))), expected \(monster.modifier(forAbility: .dexterity)), \(monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .dexterity) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSavingThrow: .constitution) != monster.modifier(forAbility: .constitution) && monster.modifier(forSavingThrow: .constitution) != monster.modifier(forAbility: .constitution) + monster.proficiencyBonus {
            print("\(monster.name) has unusual constitution saving throw: \(monster.modifier(forSavingThrow: .constitution)), expected \(monster.modifier(forAbility: .constitution)) or \(monster.modifier(forAbility: .constitution) + monster.proficiencyBonus)")
        }
        
        if monster.modifier(forSavingThrow: .intelligence) != monster.modifier(forAbility: .intelligence) && monster.modifier(forSavingThrow: .intelligence) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus {
            print("\(monster.name) has unusual intelligence saving throw: \(monster.modifier(forSavingThrow: .intelligence)), expected \(monster.modifier(forAbility: .intelligence)) or \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .intelligence(.arcana)) != monster.modifier(forAbility: .intelligence) && monster.modifier(forSkill: .intelligence(.arcana)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .intelligence(.arcana)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Arcana) skill: \(monster.modifier(forSkill: .intelligence(.arcana))), expected \(monster.modifier(forAbility: .intelligence)), \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2)")
        }
    
        if monster.modifier(forSkill: .intelligence(.history)) != monster.modifier(forAbility: .intelligence) && monster.modifier(forSkill: .intelligence(.history)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .intelligence(.history)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (History) skill: \(monster.modifier(forSkill: .intelligence(.history))), expected \(monster.modifier(forAbility: .intelligence)), \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .intelligence(.investigation)) != monster.modifier(forAbility: .intelligence) && monster.modifier(forSkill: .intelligence(.investigation)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .intelligence(.investigation)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Investigation) skill: \(monster.modifier(forSkill: .intelligence(.investigation))), expected \(monster.modifier(forAbility: .intelligence)), \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .intelligence(.nature)) != monster.modifier(forAbility: .intelligence) && monster.modifier(forSkill: .intelligence(.nature)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .intelligence(.nature)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Nature) skill: \(monster.modifier(forSkill: .intelligence(.nature))), expected \(monster.modifier(forAbility: .intelligence)), \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .intelligence(.religion)) != monster.modifier(forAbility: .intelligence) && monster.modifier(forSkill: .intelligence(.religion)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus && monster.modifier(forSkill: .intelligence(.religion)) != monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Religion) skill: \(monster.modifier(forSkill: .intelligence(.religion))), expected \(monster.modifier(forAbility: .intelligence)), \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .intelligence) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSavingThrow: .wisdom) != monster.modifier(forAbility: .wisdom) && monster.modifier(forSavingThrow: .wisdom) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus {
            print("\(monster.name) has unusual wisdom saving throw: \(monster.modifier(forSavingThrow: .wisdom)), expected \(monster.modifier(forAbility: .wisdom)) or \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .wisdom(.animalHandling)) != monster.modifier(forAbility: .wisdom) && monster.modifier(forSkill: .wisdom(.animalHandling)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .wisdom(.animalHandling)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Animal Handling) skill: \(monster.modifier(forSkill: .wisdom(.animalHandling))), expected \(monster.modifier(forAbility: .wisdom)), \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .wisdom(.medicine)) != monster.modifier(forAbility: .wisdom) && monster.modifier(forSkill: .wisdom(.medicine)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .wisdom(.medicine)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Medicine) skill: \(monster.modifier(forSkill: .wisdom(.medicine))), expected \(monster.modifier(forAbility: .wisdom)), \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .wisdom(.perception)) != monster.modifier(forAbility: .wisdom) && monster.modifier(forSkill: .wisdom(.perception)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .wisdom(.perception)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Perception) skill: \(monster.modifier(forSkill: .wisdom(.perception))), expected \(monster.modifier(forAbility: .wisdom)), \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .wisdom(.insight)) != monster.modifier(forAbility: .wisdom) && monster.modifier(forSkill: .wisdom(.insight)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .wisdom(.insight)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Insight) skill: \(monster.modifier(forSkill: .wisdom(.insight))), expected \(monster.modifier(forAbility: .wisdom)), \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2)")
        }
        
        if monster.modifier(forSkill: .wisdom(.survival)) != monster.modifier(forAbility: .wisdom) && monster.modifier(forSkill: .wisdom(.survival)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus && monster.modifier(forSkill: .wisdom(.survival)) != monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Survival) skill: \(monster.modifier(forSkill: .wisdom(.survival))), expected \(monster.modifier(forAbility: .wisdom)), \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .wisdom) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSavingThrow: .charisma) != monster.modifier(forAbility: .charisma) && monster.modifier(forSavingThrow: .charisma) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus {
            print("\(monster.name) has unusual charisma saving throw: \(monster.modifier(forSavingThrow: .charisma)), expected \(monster.modifier(forAbility: .charisma)) or \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus)")
        }

        if monster.modifier(forSkill: .charisma(.deception)) != monster.modifier(forAbility: .charisma) && monster.modifier(forSkill: .charisma(.deception)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .charisma(.deception)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Deception) skill: \(monster.modifier(forSkill: .charisma(.deception))), expected \(monster.modifier(forAbility: .charisma)), \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .charisma(.intimidation)) != monster.modifier(forAbility: .charisma) && monster.modifier(forSkill: .charisma(.intimidation)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .charisma(.intimidation)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Intimidation) skill: \(monster.modifier(forSkill: .charisma(.intimidation))), expected \(monster.modifier(forAbility: .charisma)), \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .charisma(.performance)) != monster.modifier(forAbility: .charisma) && monster.modifier(forSkill: .charisma(.performance)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .charisma(.performance)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Performance) skill: \(monster.modifier(forSkill: .charisma(.performance))), expected \(monster.modifier(forAbility: .charisma)), \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2)")
        }

        if monster.modifier(forSkill: .charisma(.persuasion)) != monster.modifier(forAbility: .charisma) && monster.modifier(forSkill: .charisma(.persuasion)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus && monster.modifier(forSkill: .charisma(.persuasion)) != monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2 {
                print("\(monster.name) has unusual Cha (Persuasion) skill: \(monster.modifier(forSkill: .charisma(.persuasion))), expected \(monster.modifier(forAbility: .charisma)), \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus), or \(monster.modifier(forAbility: .charisma) + monster.proficiencyBonus * 2)")
        }
    }
    
    // Import spells.
    let spellDatas = data["spells"] as! [NSDictionary]
    for spellData in spellDatas {
        let name = spellData["name"] as! String
        let spell = Spell(name: name, insertInto: managedObjectContext)
        
        let sourceDatas = spellData["sources"] as! [NSDictionary]
        for sourceData in sourceDatas {
            let bookIndex = (sourceData["book"]! as! NSNumber).intValue
            let book = books[bookIndex]
            
            let page = (sourceData["page"]! as! NSNumber).intValue
            
            let source = Source(book: book, page: page, spell: spell, insertInto: managedObjectContext)
            
            if let section = sourceData["section"] as? String {
                source.section = section
            }
        }
        
        let classValues = spellData["classes"] as! [NSNumber]
        for classValue in classValues {
            let characterClass = CharacterClass(rawValue: classValue.intValue)!
            let _ = SpellClass(spell: spell, characterClass: characterClass, insertInto: managedObjectContext)
        }
        
        let info = spellData["info"] as! [String: AnyObject]
        spell.setValuesForKeys(info)
    }
    
    // Check that all the adventures got reconnected to their books.
    for (bookName, referingAdventures) in adventures {
        print("Book referred to by \(referingAdventures.count) adventures is missing: \(bookName)")
    }
    
    // Check that all the combatants got a monster.
    for monsterName in combatants.keys {
        print("Monster referred to by combatant is missing: \(monsterName)")
    }

    // Done.
    try! managedObjectContext.save()

    defaults.set(plistVersion, forKey: "DataVersion")
    defaults.synchronize()
}

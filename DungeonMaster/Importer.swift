//
//  Importer.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

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
        if dataVersion != nil {
            if dataVersion == plistVersion {
                return
            }
            
            print("Importing data from \(plistVersion), replacing \(dataVersion!)")
        } else {
            print("Importing data from \(plistVersion)")
        }
    }
    
    do {
        try NSFileManager.defaultManager().removeItemAtURL(Model.storeURL)
    } catch NSCocoaError.FileNoSuchFileError {
        // Ignore removing non-existant database.
    } catch {
        let nserror = error as NSError
        NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
        abort()
    }
    
    // Import books.
    var books = [Book]()
    let bookDatas = data["books"] as! [NSDictionary]
    for bookData in bookDatas {
        let name = bookData["name"] as! String
        let book = Book(name: name, inManagedObjectContext: managedObjectContext)
        book.type = BookType(rawValue: bookData["type"]!.integerValue)!
        books.append(book)
    }
    
    var tags = [String:Tag]()
    
    // Import monsters.
    let monsterDatas = data["monsters"] as! [NSDictionary]
    for monsterData in monsterDatas {
        let name = monsterData["name"] as! String
        let monster = Monster(name: name, inManagedObjectContext: managedObjectContext)
        
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
        
        var monsterTags = [Tag]()
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
        if monster.strengthSavingThrow != monster.strengthModifier && monster.strengthSavingThrow != monster.strengthModifier + monster.proficiencyBonus {
            print("\(monster.name) has unusual strength saving throw: \(monster.strengthSavingThrow), expected \(monster.strengthModifier) or \(monster.strengthModifier + monster.proficiencyBonus)")
        }

        if monster.athleticsSkill != monster.strengthModifier && monster.athleticsSkill != monster.strengthModifier + monster.proficiencyBonus && monster.athleticsSkill != monster.strengthModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Str (Athletics) skill: \(monster.athleticsSkill), expected \(monster.strengthModifier), \(monster.strengthModifier + monster.proficiencyBonus), or \(monster.strengthModifier + monster.proficiencyBonus * 2)")
        }

        if monster.dexteritySavingThrow != monster.dexterityModifier && monster.dexteritySavingThrow != monster.dexterityModifier + monster.proficiencyBonus {
            print("\(monster.name) has unusual dexterity saving throw: \(monster.dexteritySavingThrow), expected \(monster.dexterityModifier) or \(monster.dexterityModifier + monster.proficiencyBonus)")
        }

        if monster.acrobaticsSkill != monster.dexterityModifier && monster.acrobaticsSkill != monster.dexterityModifier + monster.proficiencyBonus && monster.acrobaticsSkill != monster.dexterityModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Acrobatics) skill: \(monster.acrobaticsSkill), expected \(monster.dexterityModifier), \(monster.dexterityModifier + monster.proficiencyBonus), or \(monster.dexterityModifier + monster.proficiencyBonus * 2)")
        }

        if monster.sleightOfHandSkill != monster.dexterityModifier && monster.sleightOfHandSkill != monster.dexterityModifier + monster.proficiencyBonus && monster.sleightOfHandSkill != monster.dexterityModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Sleight of Hand) skill: \(monster.sleightOfHandSkill), expected \(monster.dexterityModifier), \(monster.dexterityModifier + monster.proficiencyBonus), or \(monster.dexterityModifier + monster.proficiencyBonus * 2)")
        }
        
        if monster.stealthSkill != monster.dexterityModifier && monster.stealthSkill != monster.dexterityModifier + monster.proficiencyBonus && monster.stealthSkill != monster.dexterityModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Dex (Stealth) skill: \(monster.stealthSkill), expected \(monster.dexterityModifier), \(monster.dexterityModifier + monster.proficiencyBonus), or \(monster.dexterityModifier + monster.proficiencyBonus * 2)")
        }

        if monster.constitutionSavingThrow != monster.constitutionModifier && monster.constitutionSavingThrow != monster.constitutionModifier + monster.proficiencyBonus {
            print("\(monster.name) has unusual constitution saving throw: \(monster.constitutionSavingThrow), expected \(monster.constitutionModifier) or \(monster.constitutionModifier + monster.proficiencyBonus)")
        }
        
        if monster.intelligenceSavingThrow != monster.intelligenceModifier && monster.intelligenceSavingThrow != monster.intelligenceModifier + monster.proficiencyBonus {
            print("\(monster.name) has unusual intelligence saving throw: \(monster.intelligenceSavingThrow), expected \(monster.intelligenceModifier) or \(monster.intelligenceModifier + monster.proficiencyBonus)")
        }

        if monster.arcanaSkill != monster.intelligenceModifier && monster.arcanaSkill != monster.intelligenceModifier + monster.proficiencyBonus && monster.arcanaSkill != monster.intelligenceModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Arcana) skill: \(monster.arcanaSkill), expected \(monster.intelligenceModifier), \(monster.intelligenceModifier + monster.proficiencyBonus), or \(monster.intelligenceModifier + monster.proficiencyBonus * 2)")
        }
    
        if monster.historySkill != monster.intelligenceModifier && monster.historySkill != monster.intelligenceModifier + monster.proficiencyBonus && monster.historySkill != monster.intelligenceModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (History) skill: \(monster.historySkill), expected \(monster.intelligenceModifier), \(monster.intelligenceModifier + monster.proficiencyBonus), or \(monster.intelligenceModifier + monster.proficiencyBonus * 2)")
        }
        
        if monster.investigationSkill != monster.intelligenceModifier && monster.investigationSkill != monster.intelligenceModifier + monster.proficiencyBonus && monster.investigationSkill != monster.intelligenceModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Investigation) skill: \(monster.investigationSkill), expected \(monster.intelligenceModifier), \(monster.intelligenceModifier + monster.proficiencyBonus), or \(monster.intelligenceModifier + monster.proficiencyBonus * 2)")
        }
        
        if monster.natureSkill != monster.intelligenceModifier && monster.natureSkill != monster.intelligenceModifier + monster.proficiencyBonus && monster.natureSkill != monster.intelligenceModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Nature) skill: \(monster.natureSkill), expected \(monster.intelligenceModifier), \(monster.intelligenceModifier + monster.proficiencyBonus), or \(monster.intelligenceModifier + monster.proficiencyBonus * 2)")
        }

        if monster.religionSkill != monster.intelligenceModifier && monster.religionSkill != monster.intelligenceModifier + monster.proficiencyBonus && monster.religionSkill != monster.intelligenceModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Int (Religion) skill: \(monster.religionSkill), expected \(monster.intelligenceModifier), \(monster.intelligenceModifier + monster.proficiencyBonus), or \(monster.intelligenceModifier + monster.proficiencyBonus * 2)")
        }
        
        if monster.wisdomSavingThrow != monster.wisdomModifier && monster.wisdomSavingThrow != monster.wisdomModifier + monster.proficiencyBonus {
            print("\(monster.name) has unusual wisdom saving throw: \(monster.wisdomSavingThrow), expected \(monster.wisdomModifier) or \(monster.wisdomModifier + monster.proficiencyBonus)")
        }

        if monster.animalHandlingSkill != monster.wisdomModifier && monster.animalHandlingSkill != monster.wisdomModifier + monster.proficiencyBonus && monster.animalHandlingSkill != monster.wisdomModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Animal Handling) skill: \(monster.animalHandlingSkill), expected \(monster.wisdomModifier), \(monster.wisdomModifier + monster.proficiencyBonus), or \(monster.wisdomModifier + monster.proficiencyBonus * 2)")
        }

        if monster.medicineSkill != monster.wisdomModifier && monster.medicineSkill != monster.wisdomModifier + monster.proficiencyBonus && monster.medicineSkill != monster.wisdomModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Medicine) skill: \(monster.medicineSkill), expected \(monster.wisdomModifier), \(monster.wisdomModifier + monster.proficiencyBonus), or \(monster.wisdomModifier + monster.proficiencyBonus * 2)")
        }
        
        if monster.perceptionSkill != monster.wisdomModifier && monster.perceptionSkill != monster.wisdomModifier + monster.proficiencyBonus && monster.perceptionSkill != monster.wisdomModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Perception) skill: \(monster.perceptionSkill), expected \(monster.wisdomModifier), \(monster.wisdomModifier + monster.proficiencyBonus), or \(monster.wisdomModifier + monster.proficiencyBonus * 2)")
        }

        if monster.insightSkill != monster.wisdomModifier && monster.insightSkill != monster.wisdomModifier + monster.proficiencyBonus && monster.insightSkill != monster.wisdomModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Insight) skill: \(monster.insightSkill), expected \(monster.wisdomModifier), \(monster.wisdomModifier + monster.proficiencyBonus), or \(monster.wisdomModifier + monster.proficiencyBonus * 2)")
        }
        
        if monster.survivalSkill != monster.wisdomModifier && monster.survivalSkill != monster.wisdomModifier + monster.proficiencyBonus && monster.survivalSkill != monster.wisdomModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Wis (Survival) skill: \(monster.survivalSkill), expected \(monster.wisdomModifier), \(monster.wisdomModifier + monster.proficiencyBonus), or \(monster.wisdomModifier + monster.proficiencyBonus * 2)")
        }

        if monster.charismaSavingThrow != monster.charismaModifier && monster.charismaSavingThrow != monster.charismaModifier + monster.proficiencyBonus {
            print("\(monster.name) has unusual charisma saving throw: \(monster.charismaSavingThrow), expected \(monster.charismaModifier) or \(monster.charismaModifier + monster.proficiencyBonus)")
        }

        if monster.deceptionSkill != monster.charismaModifier && monster.deceptionSkill != monster.charismaModifier + monster.proficiencyBonus && monster.deceptionSkill != monster.charismaModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Deception) skill: \(monster.deceptionSkill), expected \(monster.charismaModifier), \(monster.charismaModifier + monster.proficiencyBonus), or \(monster.charismaModifier + monster.proficiencyBonus * 2)")
        }

        if monster.intimidationSkill != monster.charismaModifier && monster.intimidationSkill != monster.charismaModifier + monster.proficiencyBonus && monster.intimidationSkill != monster.charismaModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Intimidation) skill: \(monster.intimidationSkill), expected \(monster.charismaModifier), \(monster.charismaModifier + monster.proficiencyBonus), or \(monster.charismaModifier + monster.proficiencyBonus * 2)")
        }

        if monster.performanceSkill != monster.charismaModifier && monster.performanceSkill != monster.charismaModifier + monster.proficiencyBonus && monster.performanceSkill != monster.charismaModifier + monster.proficiencyBonus * 2 {
            print("\(monster.name) has unusual Cha (Performance) skill: \(monster.performanceSkill), expected \(monster.charismaModifier), \(monster.charismaModifier + monster.proficiencyBonus), or \(monster.charismaModifier + monster.proficiencyBonus * 2)")
        }

        if monster.persuasionSkill != monster.charismaModifier && monster.persuasionSkill != monster.charismaModifier + monster.proficiencyBonus && monster.persuasionSkill != monster.charismaModifier + monster.proficiencyBonus * 2 {
                print("\(monster.name) has unusual Cha (Persuasion) skill: \(monster.persuasionSkill), expected \(monster.charismaModifier), \(monster.charismaModifier + monster.proficiencyBonus), or \(monster.charismaModifier + monster.proficiencyBonus * 2)")
        }
    }

    do {
        try managedObjectContext.save()

        defaults.setObject(plistVersion, forKey: "DataVersion")
        defaults.synchronize()
    } catch {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
        abort()
    }

}

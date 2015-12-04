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
    let plistVersion = data["version"] as? Int
    
    if dataVersion != nil && dataVersion == plistVersion {
        return
    }
    
    print("Importing data from \(plistVersion), replacing \(dataVersion)")
    try! NSFileManager.defaultManager().removeItemAtURL(Model.storeURL)

    // Import books.
    var books = [Book]()
    let bookDatas = data["books"] as! NSArray
    for bookData in bookDatas {
        let name = bookData["name"] as! String
        let book = Book(name: name, inManagedObjectContext: managedObjectContext)
        books.append(book)
    }
    
    // Import monsters.
    let monsterDatas = data["monsters"] as! NSArray
    for monsterData in monsterDatas {
        let name = monsterData["name"] as! String
        let monster = Monster(name: name, inManagedObjectContext: managedObjectContext)
        
        var sources = [Source]()
        let sourceDatas = monsterData["sources"] as! [NSDictionary]
        for sourceData in sourceDatas {
            let bookIndex = sourceData["book"]!.integerValue
            let book = books[bookIndex]

            let page = sourceData["page"]!.integerValue
            
            let source = Source(book: book, page: Int16(page), inManagedObjectContext: managedObjectContext)
            
            if let section = sourceData["section"] as? String {
                source.section = section
            }

            sources.append(source)
        }
        monster.sources = NSSet(array: sources)
        
        let info = monsterData["info"] as! [String: AnyObject]
        monster.setValuesForKeysWithDictionary(info)
        
        var traits = [Trait]()
        let traitDatas = monsterData["traits"] as! [NSDictionary]
        for traitData in traitDatas {
            let name = traitData["name"] as! String
            let text = traitData["text"] as! String
            let trait = Trait(name: name, text: text, inManagedObjectContext: managedObjectContext)
            traits.append(trait)
        }
        monster.traits = NSOrderedSet(array: traits)
        
        var actions = [Action]()
        let actionDatas = monsterData["actions"] as! [NSDictionary]
        for actionData in actionDatas {
            let name = actionData["name"] as! String
            let text = actionData["text"] as! String
            let action = Action(name: name, text: text, inManagedObjectContext: managedObjectContext)
            actions.append(action)
        }
        monster.actions = NSOrderedSet(array: actions)

        var reactions = [Reaction]()
        let reactionDatas = monsterData["reactions"] as! [NSDictionary]
        for reactionData in reactionDatas {
            let name = reactionData["name"] as! String
            let text = reactionData["text"] as! String
            let reaction = Reaction(name: name, text: text, inManagedObjectContext: managedObjectContext)
            reactions.append(reaction)
        }
        monster.reactions = NSOrderedSet(array: reactions)

        var legendaryActions = [LegendaryAction]()
        let legendaryActionDatas = monsterData["legendaryActions"] as! [NSDictionary]
        for legendaryActionData in legendaryActionDatas {
            let name = legendaryActionData["name"] as! String
            let text = legendaryActionData["text"] as! String
            let legendaryAction = LegendaryAction(name: name, text: text, inManagedObjectContext: managedObjectContext)
            legendaryActions.append(legendaryAction)
        }
        monster.legendaryActions = NSOrderedSet(array: legendaryActions)
        
        if let lairData = monsterData["lair"] as? NSDictionary {
            let lair = Lair(inManagedObjectContext: managedObjectContext)

            let info = lairData["info"] as! [String: AnyObject]
            lair.setValuesForKeysWithDictionary(info)
            
            var lairActions = [LairAction]()
            let lairActionTexts = lairData["lairActions"] as! [String]
            for text in lairActionTexts {
                let lairAction = LairAction(text: text, inManagedObjectContext: managedObjectContext)
                lairActions.append(lairAction)
            }
            lair.lairActions = NSOrderedSet(array: lairActions)

            var lairTraits = [LairTrait]()
            let lairTraitsTexts = lairData["lairTraits"] as! [String]
            for text in lairTraitsTexts {
                let lairTrait = LairTrait(text: text, inManagedObjectContext: managedObjectContext)
                lairTraits.append(lairTrait)
            }
            lair.lairTraits = NSOrderedSet(array: lairTraits)

            var regionalEffects = [RegionalEffect]()
            let regionalEffectsTexts = lairData["regionalEffects"] as! [String]
            for text in regionalEffectsTexts {
                let regionalEffect = RegionalEffect(text: text, inManagedObjectContext: managedObjectContext)
                regionalEffects.append(regionalEffect)
            }
            lair.regionalEffects = NSOrderedSet(array: regionalEffects)


            monster.lair = lair
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

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
        book.rawType = Int16(bookData["type"]!.integerValue)
        books.append(book)
    }
    
    var tags = [String:Tag]()
    
    // Import monsters.
    let monsterDatas = data["monsters"] as! [NSDictionary]
    for monsterData in monsterDatas {
        let name = monsterData["name"] as! String
        let monster = Monster(name: name, inManagedObjectContext: managedObjectContext)
        
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
        monster.tags = NSOrderedSet(array: monsterTags)
        
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
            print("\(monster.name) has unusual HP: \(monster.hitPoints), expected \(monster.hitDice.averageValue)")
        } else {
            monster.hitPoints = nil
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

//
//  Importer.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

public func importIfNeeded(managedObjectContext: NSManagedObjectContext) {
    let fetchRequest = NSFetchRequest()
    let entity = NSEntityDescription.entity(Model.Book, inManagedObjectContext: managedObjectContext)
    fetchRequest.entity = entity

    do {
        let books = try managedObjectContext.executeFetchRequest(fetchRequest)
        if books.count == 0 {
            importIntoContext(managedObjectContext)
        }
    } catch {
        let nserror = error as NSError
        print("Unresolved error \(nserror), \(nserror.userInfo)")
        abort()
    }
}


enum NextLine {
    case Name
    case Source
    case SizeTypeAlignment
    case EndOfIntro
    case BasicStats
    case AbilityScores
    case AdvancedStats
    case Text
}

func importIntoContext(managedObjectContext: NSManagedObjectContext) {
    let filename = NSBundle.mainBundle().pathForResource("Monsters", ofType: "txt")!
    let data = try! String(contentsOfFile: filename, encoding: NSUTF8StringEncoding)
    
    let mm = Book(name: "Monster Manual", inManagedObjectContext: managedObjectContext)
    let mmTag = "mm "

    let dmbr = Book(name: "Dungeon Master's Basic Rules Version 0.3", inManagedObjectContext: managedObjectContext)
    let dmbrTag = "dmbr "
    
    var nextLine = NextLine.Name
    var monster: Monster?
    data.enumerateLines {
        line, stop in
        
        switch nextLine {
        case .Name:
            monster = Monster(name: line, inManagedObjectContext: managedObjectContext)
            print("Monster '\(monster!.name)'")
            nextLine = .Source
        case .Source:
            for sourceTextEntry in line.componentsSeparatedByString("|") {
                let sourceTextParts = sourceTextEntry.componentsSeparatedByString("; ")
                let sourceText = sourceTextParts[0]
                
                var book: Book! = nil
                var page: Int16! = nil
                if sourceText.hasPrefix(mmTag) {
                    book = mm
                    page = Int16(sourceText.substringFromIndex(sourceText.startIndex.advancedBy(mmTag.characters.count)))
                } else if sourceText.hasPrefix(dmbrTag) {
                    book = dmbr
                    page = Int16(sourceText.substringFromIndex(sourceText.startIndex.advancedBy(dmbrTag.characters.count)))
                } else {
                    print("Bad book tag: \(sourceText)")
                    abort()
                }

                print("  \(book.name) page #\(page)")

                let source = Source(book: book, page: page, monster: monster!, inManagedObjectContext: managedObjectContext)
                if sourceTextParts.count > 1 {
                    source.section = sourceTextParts[1]
                }
            }
            nextLine = .SizeTypeAlignment
        case .SizeTypeAlignment:
            monster!.sizeTypeAlignment = line
            nextLine = .EndOfIntro
        case .EndOfIntro:
            if line != "" {
                print("Unexpected line!")
                abort()
            }
            nextLine = .BasicStats
        case .BasicStats:
            let acTag = "Armor Class "
            let hpTag = "Hit Points "
            let sTag = "Speed "
            if line == "" {
                nextLine = .AbilityScores
            } else if line.hasPrefix(acTag) {
                monster!.armorClass = line.substringFromIndex(line.startIndex.advancedBy(acTag.characters.count))
            } else if line.hasPrefix(hpTag) {
                monster!.hitPoints = line.substringFromIndex(line.startIndex.advancedBy(hpTag.characters.count))
            } else if line.hasPrefix(sTag) {
                monster!.speed = line.substringFromIndex(line.startIndex.advancedBy(sTag.characters.count))
            } else {
                print("Bad basic stats line: \(line)")
                abort()
            }
        case .AbilityScores:
            if line == "" {
                nextLine = .AdvancedStats
            } else if line.hasPrefix("STR ") {
                monster!.strength = line.substringFromIndex(line.startIndex.advancedBy(4))
            } else if line.hasPrefix("DEX ") {
                monster!.dexterity = line.substringFromIndex(line.startIndex.advancedBy(4))
            } else if line.hasPrefix("CON ") {
                monster!.constitution = line.substringFromIndex(line.startIndex.advancedBy(4))
            } else if line.hasPrefix("INT ") {
                monster!.intelligence = line.substringFromIndex(line.startIndex.advancedBy(4))
            } else if line.hasPrefix("WIS ") {
                monster!.wisdom = line.substringFromIndex(line.startIndex.advancedBy(4))
            } else if line.hasPrefix("CHA ") {
                monster!.charisma = line.substringFromIndex(line.startIndex.advancedBy(4))
            } else {
                print("Bad ability scores line: \(line)")
                abort()
            }
        case .AdvancedStats:
            let stTag = "Saving Throws "
            let skTag = "Skills "
            let dvTag = "Damage Vulnerabilities "
            let drTag = "Damage Resistances "
            let drTag2 = "Damage Resistance "
            let diTag = "Damage Immunities "
            let ciTag = "Condition Immunities "
            let seTag = "Senses "
            let lTag = "Languages "
            let cTag = "Challenge "
            if line == "" {
                nextLine = .Text
            } else if line.hasPrefix(stTag) {
                monster!.savingThrows = line.substringFromIndex(line.startIndex.advancedBy(stTag.characters.count))
            } else if line.hasPrefix(skTag) {
                monster!.skills = line.substringFromIndex(line.startIndex.advancedBy(skTag.characters.count))
            } else if line.hasPrefix(seTag) {
                monster!.senses = line.substringFromIndex(line.startIndex.advancedBy(seTag.characters.count))
            } else if line.hasPrefix(dvTag) {
                monster!.damageVulnerabilities = line.substringFromIndex(line.startIndex.advancedBy(dvTag.characters.count))
            } else if line.hasPrefix(drTag) {
                monster!.damageResistances = line.substringFromIndex(line.startIndex.advancedBy(drTag.characters.count))
            } else if line.hasPrefix(drTag2) {
                monster!.damageResistances = line.substringFromIndex(line.startIndex.advancedBy(drTag2.characters.count))
            } else if line.hasPrefix(diTag) {
                monster!.damageImmunities = line.substringFromIndex(line.startIndex.advancedBy(diTag.characters.count))
            } else if line.hasPrefix(ciTag) {
                monster!.conditionImmunities = line.substringFromIndex(line.startIndex.advancedBy(ciTag.characters.count))
            } else if line.hasPrefix(lTag) {
                monster!.languages = line.substringFromIndex(line.startIndex.advancedBy(lTag.characters.count))
            } else if line.hasPrefix(cTag) {
                monster!.challenge = line.substringFromIndex(line.startIndex.advancedBy(cTag.characters.count))
            } else {
                print("Bad advanced stats line: \(line)")
                abort()
            }
        case .Text:
            if line == "--" {
                nextLine = .Name
            } else {
                monster!.text += line + "\n"
            }
        }
    }

    do {
        try managedObjectContext.save()
    } catch {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
        abort()
    }

}

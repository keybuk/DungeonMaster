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
    case WaitingForEnd
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
            nextLine = .WaitingForEnd
        case .WaitingForEnd:
            if line == "--" {
                nextLine = .Name
            }
        }
    }
    
}

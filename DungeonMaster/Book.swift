//
//  Book.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

/// Book represents a specific book, supplement, online update, etc. in which references to material can be found.
final class Book: NSManagedObject {
    
    /// Name of the book.
    @NSManaged var name: String
    
    /// Type of the book.
    var type: BookType {
        get {
            return BookType(rawValue: rawType.integerValue)!
        }
        set(newType) {
            rawType = NSNumber(integer: newType.rawValue)
        }
    }
    @NSManaged private var rawType: NSNumber

    /// References contained within this book.
    @NSManaged var sources: NSSet

    var allSources: Set<Source> {
        return sources as! Set<Source>
    }

    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Book, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }
    
}

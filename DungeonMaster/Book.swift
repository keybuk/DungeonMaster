//
//  Book.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Book: NSManagedObject {
    
    @NSManaged var name: String
    
    @NSManaged var rawType: Int16
    
    var type: BookType {
        get {
            return BookType(rawValue: rawType)!
        }
        set(newType) {
            rawType = newType.rawValue
        }
    }
    
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

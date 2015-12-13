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
    @NSManaged var sources: NSSet
    
    // Type is a wrapped enum object.
    @NSManaged var typeValue: Int16
    
    enum Type: Int16 {
        case CoreRulebook
        case OfficialAdventure
        case OnlineSupplement
    }
    
    var type: Type {
        get {
            return Type(rawValue: typeValue)!
        }
        set(newType) {
            typeValue = newType.rawValue
        }
    }
    
    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Book, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }
    
}

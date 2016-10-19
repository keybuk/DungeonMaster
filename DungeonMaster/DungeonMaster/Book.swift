//
//  Book.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Book represents a specific book, supplement, online update, etc. in which references to material can be found.
final class Book : NSManagedObject {
    
    /// Name of the book.
    @NSManaged var name: String
    
    /// Type of the book.
    var type: BookType {
        get {
            return BookType(rawValue: rawType.intValue)!
        }
        set(newType) {
            rawType = NSNumber(value: newType.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawType: NSNumber

    /// References contained within this book.
    ///
    /// Each member is a `Source` with the page of the specific reference and link to the referencing entity.
    @NSManaged var sources: NSSet
    
    /// Adventures that use this book as source material.
    ///
    /// Each member is an `Adventure`.
    @NSManaged var adventures: NSSet

    convenience init(name: String, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.Book, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.name = name
    }
    
}

//
//  Source.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Source represents an individual reference to source material.
final class Source: NSManagedObject {

    /// The source book for this reference.
    @NSManaged var book: Book

    /// Page number in the book where this reference can be found.
    var page: Int {
        get {
            return rawPage.integerValue
        }
        set(newPage) {
            rawPage = NSNumber(integer: newPage)
        }
    }
    @NSManaged private var rawPage: NSNumber

    /// Title of the section that the reference can be found in, if relevant.
    @NSManaged var section: String?
    
    /// Monster contained at this reference point.
    @NSManaged var monster: Monster

    convenience init(book: Book, page: Int, monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Source, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.book = book
        self.page = page
        self.monster = monster
    }

}

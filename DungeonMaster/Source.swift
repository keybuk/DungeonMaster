//
//  Source.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Source: NSManagedObject {

    @NSManaged var book: Book
    @NSManaged var pageValue: Int16
    @NSManaged var section: String?
    @NSManaged var monster: Monster

    var page: Int {
        get {
            return Int(pageValue)
        }
        set {
            pageValue = Int16(page)
        }
    }
    
    convenience init(book: Book, page: Int, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Source, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.book = book
        self.page = page
    }

}

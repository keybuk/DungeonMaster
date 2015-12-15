//
//  Tag.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/6/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Tag: NSManagedObject {
    
    @NSManaged var name: String

    @NSManaged var monsters: NSSet
    
    var allMonsters: Set<Monster> {
        return monsters as! Set<Monster>
    }
    
    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Tag, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }
    
}

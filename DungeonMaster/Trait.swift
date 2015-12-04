//
//  Trait.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/3/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Trait: NSManagedObject {
    
    @NSManaged var monster: Monster
    @NSManaged var name: String
    @NSManaged var text: String
    
    convenience init(name: String, text: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Trait, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
        self.text = text
    }
    
}

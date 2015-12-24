//
//  RegionalEffect.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/3/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class RegionalEffect: NSManagedObject {
    
    @NSManaged var lair: Lair
    @NSManaged var text: String
    
    convenience init(lair: Lair, text: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.RegionalEffect, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.lair = lair
        self.text = text
    }
    
}

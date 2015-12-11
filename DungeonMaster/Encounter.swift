//
//  Encounter.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/10/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Encounter: NSManagedObject {
    
    @NSManaged var lastUsed: NSDate
    @NSManaged var name: String?
    
    convenience init(inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Encounter, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        lastUsed = NSDate()
    }
    
}

//
//  LairAction.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/3/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class LairAction: NSManagedObject {
    
    @NSManaged var lair: Lair
    @NSManaged var text: String
    
    convenience init(text: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.LairAction, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.text = text
    }
    
}

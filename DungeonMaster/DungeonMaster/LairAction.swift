//
//  LairAction.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/3/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class LairAction : NSManagedObject {
    
    @NSManaged var lair: Lair
    @NSManaged var text: String
    
    convenience init(lair: Lair, text: String, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.LairAction, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.lair = lair
        self.text = text
    }
    
}

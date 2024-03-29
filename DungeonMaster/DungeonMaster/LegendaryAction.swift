//
//  LegendaryAction.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/3/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class LegendaryAction : NSManagedObject {
    
    @NSManaged var monster: Monster
    @NSManaged var name: String
    @NSManaged var text: String
    
    convenience init(monster: Monster, name: String, text: String, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.LegendaryAction, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.monster = monster
        self.name = name
        self.text = text
    }
    
}

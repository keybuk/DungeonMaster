//
//  Tag.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/6/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

/// Tag represents arbitrary text strings that can be applied to monsters.
///
/// Tags have no meaning in of themselves; but may be referred to in the descriptions of traits, attacks, spells, etc. All monsters that reference a specific tag share the same `Tag` object.
final class Tag: NSManagedObject {
    
    /// Name of the tag.
    @NSManaged var name: String

    /// Set of monsters that this tag applies to.
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

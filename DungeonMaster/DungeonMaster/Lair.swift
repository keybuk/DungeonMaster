//
//  Lair.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/3/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class Lair : NSManagedObject {

    @NSManaged var monster: Monster
    @NSManaged var text: String
    @NSManaged var lairActionsText: String?
    @NSManaged var lairActionsLimit: String?
    @NSManaged var lairTraitsText: String?
    @NSManaged var lairTraitsDuration: String?
    @NSManaged var regionalEffectsText: String?
    @NSManaged var regionalEffectsDuration: String?
    
    @NSManaged var lairActions: NSOrderedSet
    
    @NSManaged var lairTraits: NSOrderedSet

    @NSManaged var regionalEffects: NSOrderedSet

    convenience init(insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.Lair, in: context)
        self.init(entity: entity, insertInto: context)
    }

}

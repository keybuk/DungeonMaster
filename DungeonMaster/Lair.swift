//
//  Lair.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/3/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Lair: NSManagedObject {

    @NSManaged var monster: Monster
    @NSManaged var text: String
    @NSManaged var lairActionsText: String?
    @NSManaged var lairActionsLimit: String?
    @NSManaged var lairTraitsText: String?
    @NSManaged var lairTraitsDuration: String?
    @NSManaged var regionalEffectsText: String?
    @NSManaged var regionalEffectsDuration: String?
    
    @NSManaged var lairActions: NSOrderedSet
    
    var allLairActions: [LairAction] {
        return lairActions.array as! [LairAction]
    }
    
    @NSManaged var lairTraits: NSOrderedSet

    var allLairTraits: [LairTrait] {
        return lairTraits.array as! [LairTrait]
    }
    
    @NSManaged var regionalEffects: NSOrderedSet

    var allRegionalEffects: [RegionalEffect] {
        return regionalEffects.array as! [RegionalEffect]
    }

    convenience init(inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Lair, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
    }

}

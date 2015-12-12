//
//  Combatant.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Combatant: NSManagedObject {
    
    @NSManaged var encounter: Encounter
    @NSManaged var monster: Monster

    @NSManaged var hitPointsValue: Int16
    @NSManaged var initiativeValue: NSNumber?

    var hitPoints: Int {
        get {
            return Int(hitPointsValue)
        }
        set {
            hitPointsValue = Int16(hitPoints)
        }
    }

    var initiative: Int? {
        get {
            return initiativeValue?.integerValue
        }
        set {
            initiativeValue = initiative != nil ? NSNumber(integer: initiative!) : nil
        }
    }
    
    convenience init(encounter: Encounter, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Combatant, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.encounter = encounter
    }
    
}

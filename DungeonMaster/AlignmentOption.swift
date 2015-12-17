//
//  AlignmentOption.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/17/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class AlignmentOption: NSManagedObject {
    
    @NSManaged var monster: Monster
    
    var alignment: Alignment {
        get {
            return Alignment(rawValue: rawAlignment.integerValue)!
        }
        set(newAlignment) {
            rawAlignment = NSNumber(integer: newAlignment.rawValue)
        }
    }
    @NSManaged private var rawAlignment: NSNumber
    
    var weight: Float? {
        get {
            return rawWeight?.floatValue
        }
        set(newWeight) {
            rawWeight = newWeight != nil ? NSNumber(float: newWeight!) : nil
        }
    }
    @NSManaged private var rawWeight: NSNumber?

    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.AlignmentOption, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.monster = monster
    }
    
}

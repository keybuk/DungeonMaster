//
//  MonsterEnvironment.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/2/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// MonsterEnvironment represents an environment in which a Monster may be found.
final class MonsterEnvironment : NSManagedObject {
    
    /// The monster which can be found in this environment.
    @NSManaged var monster: Monster
    
    /// The environment in which the monster can be found.
    var environment: Environment {
        get {
            return Environment(rawValue: rawEnvironment.integerValue)!
        }
        set(newEnvironment) {
            rawEnvironment = NSNumber(integer: newEnvironment.rawValue)
        }
    }
    @NSManaged private var rawEnvironment: NSNumber
    
    convenience init(monster: Monster, environment: Environment, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.MonsterEnvironment, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.monster = monster
        self.environment = environment
    }
    
}

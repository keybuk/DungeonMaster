//
//  AlignmentOption.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/17/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// AlignmentOption represents a single option, in a set, for choosing the alignment of a monster.
final class AlignmentOption : NSManagedObject {
    
    /// Monster for which this alignment is an option.
    @NSManaged var monster: Monster
    
    /// The specific alignment that can be chosen.
    var alignment: Alignment {
        get {
            return Alignment(rawValue: rawAlignment.intValue)!
        }
        set(newAlignment) {
            rawAlignment = NSNumber(value: newAlignment.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawAlignment: NSNumber
    
    /// Weight that should be applied when randomly choosing an alignment from the complete set.
    ///
    /// This is always set for all alignments, or always unset for all alignments. When unset, simply pick an alignment at random from the set. When set, each alignment has a weight value in the range 0.0...1.0, with the complete set totalling 1.0.
    var weight: Float? {
        get {
            return rawWeight?.floatValue
        }
        set(newWeight) {
            rawWeight = newWeight.map({ NSNumber(value: $0 as Float) })
        }
    }
    @NSManaged fileprivate var rawWeight: NSNumber?

    convenience init(monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.AlignmentOption, inManagedObjectContext: context)
        self.init(entity: entity, insertInto: context)
        
        self.monster = monster
    }
    
}

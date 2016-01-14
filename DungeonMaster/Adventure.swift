//
//  Adventure.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/6/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Adventure represents a D&D campaign or adventure.
///
/// It's a top-level object in the model under which all user content is grouped.
final class Adventure: NSManagedObject {
    
    /// Timestamp when the Adventure object was last modified.
    @NSManaged var lastModified: NSDate

    /// Name of the adventure.
    @NSManaged var name: String
    
    /// Image associated with the adventure.
    @NSManaged var image: AdventureImage

    convenience init(inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Adventure, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        lastModified = NSDate()
        image = AdventureImage(adventure: self, inManagedObjectContext: context)
    }

    // MARK: Validation
    
    func validateName(ioObject: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let name = ioObject.memory as? String where name != "" else {
            let errorString = "Name can't be empty"
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Adventure", code: NSManagedObjectValidationError, userInfo: userDict)
        }
    }

}
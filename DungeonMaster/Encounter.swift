//
//  Encounter.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/10/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Encounter: NSManagedObject {
    
    @NSManaged var lastUsed: NSDate
    @NSManaged var name: String?
    
    @NSManaged var combatants: NSSet
    
    var notificationObserver: NSObjectProtocol?
    
    convenience init(inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Encounter, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        lastUsed = NSDate()
    }
    
    deinit {
        if let notificationObserver = notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(notificationObserver)
        }
    }

    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        observeChanges()
    }
    
    override func awakeFromFetch() {
        super.awakeFromFetch()
        
        observeChanges()
    }
    
    /// Encounter maintains a lastUsed property that is updated automatically when the encounter object itself changes, combatants are added to or removed from the encounter, or any of the combatants in the encounter is changed.
    func observeChanges() {
        guard notificationObserver == nil else { return }
    
        notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: nil) { notification in
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
                var interestingObjects = Set<NSManagedObject>()
                interestingObjects.insert(self)
                interestingObjects.unionInPlace(self.combatants.allObjects as! [NSManagedObject])
                
                if updatedObjects.intersectsSet(interestingObjects) {
                    self.setPrimitiveValue(NSDate(), forKey: "lastUsed")
                }
            }
        }
    }
    
}

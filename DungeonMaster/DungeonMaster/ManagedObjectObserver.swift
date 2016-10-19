//
//  ManagedObjectObserver.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Change observed on an `NSManagedObject`.
/// - **Inserted**: the object was inserted into its context.
/// - **Updated**: the object was updated.
/// - **Deleted**: the object was marked for deletion.
/// - **Refreshed**: the object was refreshed.
/// - **Invalidated**: the object was invalidated.
enum ManagedObjectChangeType {
    case inserted
    case updated
    case deleted
    case refreshed
    case invalidated
}

/// Objects can confirm to `ManagedObjectObserverDelegate` in order to observe changes to `NSManagedObject`s.
///
/// Implementation of a single method `managedObject(object: changedForType type:)` is necessary to receive the change events.
protocol ManagedObjectObserverDelegate: class {
    associatedtype Entity
    
    func managedObject(_ object: Entity, changedForType type: ManagedObjectChangeType)
    
}

/// ManagedObjectObserver wraps the `NSManagedObjectContextObjectsDidChangeNotification` notification to check for changes to a single object.
///
/// To avoid specifying the generic parameters when storing the observer in the class, store as a property of `NSObjectProtocol?` type.
class ManagedObjectObserver<Entity, DelegateType> : NSObject where Entity : NSManagedObject, DelegateType : ManagedObjectObserverDelegate, DelegateType.Entity == Entity {
    
    let object: Entity
    weak var delegate: DelegateType?

    init(object: Entity, delegate: DelegateType) {
        self.object = object
        self.delegate = delegate

        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: object.managedObjectContext)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func managedObjectContextObjectsDidChange(_ notification: Notification) {
        if let insertedObjects = (notification as NSNotification).userInfo?[NSInsertedObjectsKey] as? NSSet, insertedObjects.contains(object) {
            delegate?.managedObject(object, changedForType: .inserted)
        }
        
        if let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? NSSet, updatedObjects.contains(object) {
            delegate?.managedObject(object, changedForType: .updated)
        }
        
        if let deletedObjects = (notification as NSNotification).userInfo?[NSDeletedObjectsKey] as? NSSet, deletedObjects.contains(object) {
            delegate?.managedObject(object, changedForType: .deleted)
        }
        
        if let refreshedObjects = (notification as NSNotification).userInfo?[NSRefreshedObjectsKey] as? NSSet, refreshedObjects.contains(object) {
            delegate?.managedObject(object, changedForType: .refreshed)
        }
        
        if let invalidatedObjects = (notification as NSNotification).userInfo?[NSInvalidatedObjectsKey] as? NSSet, invalidatedObjects.contains(object) {
            delegate?.managedObject(object, changedForType: .invalidated)
        }
        
        if let _  = (notification as NSNotification).userInfo?[NSInvalidatedAllObjectsKey] {
            delegate?.managedObject(object, changedForType: .invalidated)
        }
    }
    
}

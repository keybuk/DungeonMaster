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
    case Inserted
    case Updated
    case Deleted
    case Refreshed
    case Invalidated
}

/// Objects can confirm to `ManagedObjectObserverDelegate` in order to observe changes to `NSManagedObject`s.
///
/// Implementation of a single method `managedObject(object: changedForType type:)` is necessary to receive the change events.
protocol ManagedObjectObserverDelegate: class {
    typealias Entity
    
    func managedObject(object: Entity, changedForType type: ManagedObjectChangeType)
    
}

/// ManagedObjectObserver wraps the `NSManagedObjectContextObjectsDidChangeNotification` notification to check for changes to a single object.
///
/// To avoid specifying the generic parameters when storing the observer in the class, store as a property of `NSObjectProtocol?` type.
class ManagedObjectObserver<Entity, DelegateType where Entity: NSManagedObject, DelegateType: ManagedObjectObserverDelegate, DelegateType.Entity == Entity>: NSObject {
    
    let object: Entity
    weak var delegate: DelegateType?

    init(object: Entity, delegate: DelegateType) {
        self.object = object
        self.delegate = delegate

        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(managedObjectContextObjectsDidChange(_:)), name: NSManagedObjectContextObjectsDidChangeNotification, object: object.managedObjectContext)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func managedObjectContextObjectsDidChange(notification: NSNotification) {
        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? NSSet where insertedObjects.containsObject(object) {
            delegate?.managedObject(object, changedForType: .Inserted)
        }
        
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet where updatedObjects.containsObject(object) {
            delegate?.managedObject(object, changedForType: .Updated)
        }
        
        if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? NSSet where deletedObjects.containsObject(object) {
            delegate?.managedObject(object, changedForType: .Deleted)
        }
        
        if let refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey] as? NSSet where refreshedObjects.containsObject(object) {
            delegate?.managedObject(object, changedForType: .Refreshed)
        }
        
        if let invalidatedObjects = notification.userInfo?[NSInvalidatedObjectsKey] as? NSSet where invalidatedObjects.containsObject(object) {
            delegate?.managedObject(object, changedForType: .Invalidated)
        }
        
        if let _  = notification.userInfo?[NSInvalidatedAllObjectsKey] {
            delegate?.managedObject(object, changedForType: .Invalidated)
        }
    }
    
}
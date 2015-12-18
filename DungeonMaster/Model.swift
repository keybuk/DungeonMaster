//
//  Model.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

enum Model: String {
    case Book
    case Source
    case Monster
    case Tag
    case AlignmentOption
    case Armor
    case Trait
    case Action
    case Reaction
    case LegendaryAction
    case Lair
    case LairAction
    case LairTrait
    case RegionalEffect
    case Encounter
    case Combatant
    case Damage
    case Condition

    static let name = "DungeonMaster"
    
    static var URL: NSURL {
        get {
            return NSBundle.mainBundle().URLForResource(Model.name, withExtension: "momd")!
        }
    }
    
    static var storeURL: NSURL {
        get {
            let documentsDirectoryURLs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return documentsDirectoryURLs.last!.URLByAppendingPathComponent(Model.name).URLByAppendingPathExtension("sqlite")
        }
    }
    
    static var managedObjectModel: NSManagedObjectModel {
        get {
            return NSManagedObjectModel(contentsOfURL: Model.URL)!
        }
    }

}

extension NSEntityDescription {
    
    class func entity(model: Model, inManagedObjectContext context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName(model.rawValue, inManagedObjectContext: context)!
    }
    
}

extension NSFetchRequest {
    
    convenience init(entity: Model) {
        self.init(entityName: entity.rawValue)
    }
    
}

let persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let options: [NSObject: AnyObject]? = [
        NSMigratePersistentStoresAutomaticallyOption : true,
        NSInferMappingModelAutomaticallyOption : true
    ]
    
    let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: Model.managedObjectModel)
    do {
        try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: Model.storeURL, options: options)
    } catch {
        let nserror = error as NSError
        print("Unresolved error \(nserror), \(nserror.userInfo)")
        abort()
    }
    return persistentStoreCoordinator
}()

let managedObjectContext: NSManagedObjectContext = {
    let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
    return managedObjectContext
}()


func childManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType, mergeType: NSMergePolicyType = .MergeByPropertyObjectTrumpMergePolicyType) -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: concurrencyType)
    context.parentContext = managedObjectContext
    context.mergePolicy = NSMergePolicy(mergeType: mergeType)
    return context
}

func saveContext () {
    if managedObjectContext.hasChanges {
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
    }
}


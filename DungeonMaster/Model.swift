//
//  Model.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

enum Model: String {
    case Book
    case Source
    case Monster
    case MonsterEnvironment
    case MonsterSavingThrow
    case MonsterSkill
    case Tag
    case AlignmentOption
    case Armor
    case DamageImmunity
    case DamageResistance
    case DamageResistanceOption
    case DamageVulnerability
    case ConditionImmunity
    case Language
    case Trait
    case Action
    case Reaction
    case LegendaryAction
    case Lair
    case LairAction
    case LairTrait
    case RegionalEffect
    case Spell
    case SpellClass
    case Adventure
    case AdventureImage
    case Player
    case PlayerSavingThrow
    case PlayerSkill
    case Encounter
    case Combatant
    case CombatantDamage
    case CombatantCondition

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
    try! persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: Model.storeURL, options: options)

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
        try! managedObjectContext.save()
    }
}


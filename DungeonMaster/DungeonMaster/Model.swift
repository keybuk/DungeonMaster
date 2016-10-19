//
//  Model.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

enum Model : String {
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
    case Game
    case PlayedGame
    case LogEntry
    case XPAward
    case LogEntryNote
    case Player
    case PlayerSavingThrow
    case PlayerSkill
    case Encounter
    case Combatant
    case CombatantDamage
    case CombatantCondition

    static let name = "DungeonMaster"
    
    static var url: URL {
        get {
            return Bundle.main.url(forResource: Model.name, withExtension: "momd")!
        }
    }
    
    static var storeURL: URL {
        get {
            let documentsDirectoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return documentsDirectoryURLs.last!.appendingPathComponent(Model.name).appendingPathExtension("sqlite")
        }
    }
    
    static var managedObjectModel: NSManagedObjectModel {
        get {
            return NSManagedObjectModel(contentsOf: Model.url)!
        }
    }

}

extension NSEntityDescription {
    
    class func entity(_ model: Model, inManagedObjectContext context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: model.rawValue, in: context)!
    }
    
}

extension NSFetchRequest {
    
    convenience init(entity: Model) {
        self.init(entityName: entity.rawValue)
    }
    
}

let persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let options: [AnyHashable: Any]? = [
        NSMigratePersistentStoresAutomaticallyOption : true,
        NSInferMappingModelAutomaticallyOption : true
    ]
    
    let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: Model.managedObjectModel)
    try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: Model.storeURL, options: options)

    return persistentStoreCoordinator
}()

let managedObjectContext: NSManagedObjectContext = {
    let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
    return managedObjectContext
}()


func childManagedObjectContext(_ concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType, mergeType: NSMergePolicyType = .mergeByPropertyObjectTrumpMergePolicyType) -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: concurrencyType)
    context.parent = managedObjectContext
    context.mergePolicy = NSMergePolicy(merge: mergeType)
    return context
}

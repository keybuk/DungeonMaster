//
//  Language.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Langauge represents a language spoken by monsters.
///
/// All monsters that can speak a specific language share the same `Language` object.
final class Language: NSManagedObject {
    
    /// Name of the language.
    @NSManaged var name: String
    
    /// Set of monsters that can speak this language.
    @NSManaged var monstersSpeaking: NSSet
    
    /// Set of monsters that can understand, but not speak, this language.
    @NSManaged var monstersUnderstanding: NSSet
    
    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Language, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }
    
}

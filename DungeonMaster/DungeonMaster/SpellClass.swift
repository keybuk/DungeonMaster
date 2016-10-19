//
//  SpellClass.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/2/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// SpellClass represents a character class that may cast a specific spell.
final class SpellClass : NSManagedObject {
    
    /// The spell that can be cast.
    @NSManaged var spell: Spell

    /// Class of characters that may cast this spell.
    var characterClass: CharacterClass {
        get {
            return CharacterClass(rawValue: rawCharacterClass.intValue)!
        }
        set(newCharacterClass) {
            rawCharacterClass = NSNumber(value: newCharacterClass.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawCharacterClass: NSNumber

    convenience init(spell: Spell, characterClass: CharacterClass, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.SpellClass, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.spell = spell
        self.characterClass = characterClass
    }

}

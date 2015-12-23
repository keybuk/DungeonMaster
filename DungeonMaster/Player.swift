//
//  Player.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Player represents a player character.
final class Player: NSManagedObject {
    
    /// Name of the character.
    @NSManaged var name: String
    
    /// Name of the player whose character this is.
    @NSManaged var playerName: String
    
    /// Race of the character.
    var race: Race {
        get {
            return Race(rawRaceValue: rawRace.integerValue, rawSubraceValue: rawSubrace?.integerValue)!
        }
        set(newRace) {
            rawRace = NSNumber(integer: newRace.rawRaceValue)
            rawSubrace = newRace.rawSubraceValue != nil ? NSNumber(integer: newRace.rawSubraceValue!) : nil
        }
    }
    @NSManaged private var rawRace: NSNumber
    @NSManaged private var rawSubrace: NSNumber?
    
    /// Class of the character.
    var characterClass: CharacterClass {
        get {
            return CharacterClass(rawValue: rawCharacterClass.integerValue)!
        }
        set(newCharacterClass) {
            rawCharacterClass = NSNumber(integer: newCharacterClass.rawValue)
        }
    }
    @NSManaged private var rawCharacterClass: NSNumber
    
    /// Background of the character.
    var background: Background {
        get {
            return Background(rawValue: rawBackground.integerValue)!
        }
        set(newBackground) {
            rawBackground = NSNumber(integer: newBackground.rawValue)
        }
    }
    @NSManaged private var rawBackground: NSNumber

    /// Alignment of the character
    var alignment: Alignment {
        get {
            return Alignment(rawValue: rawAlignment.integerValue)!
        }
        set(newAlignment) {
            rawAlignment = NSNumber(integer: newAlignment.rawValue)
        }
    }
    @NSManaged private var rawAlignment: NSNumber
    
    /// Experience points earned by the character.
    var XP: Int {
        get {
            return rawXP.integerValue
        }
        set(newXP) {
            rawXP = NSNumber(integer: newXP)
        }
    }
    @NSManaged private var rawXP: NSNumber
    
    /// Level of the character.
    ///
    /// Based on the character's current XP.
    var level: Int {
        return sharedRules.levelXP.filter({ $0.1 < XP }).map({ $0.0 }).maxElement()!
    }
    
    /// Passive perception score for the character.
    ///
    /// Unlike `Monster` this is a static value stored for the player's character, rather than calculated from player's stats. This is because we don't want to track all the player's stats, both for effort, and to avoid meta-gaming.
    var passivePerception: Int {
        get {
            return rawPassivePerception.integerValue
        }
        set(newPassivePerception) {
            rawPassivePerception = NSNumber(integer: newPassivePerception)
        }
    }
    @NSManaged private var rawPassivePerception: NSNumber
    
    /// Set of saving throws that the character if proficient in.
    ///
    /// Each member is a `PlayerSavingThrow`.
    @NSManaged var savingThrows: NSSet
    
    /// Set of skills that the character is proficient in.
    ///
    /// Each member is a `PlayerSkill`.
    @NSManaged var skills: NSSet
    
    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Player, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }
    
}

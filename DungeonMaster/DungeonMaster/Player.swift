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
final class Player : NSManagedObject {
    
    /// Name of the character.
    @NSManaged var name: String
    
    /// Name of the player whose character this is.
    @NSManaged var playerName: String
    
    /// Race of the character.
    var race: Race {
        get {
            return Race(rawRaceValue: rawRace.intValue, rawSubraceValue: rawSubrace?.intValue)!
        }
        set(newRace) {
            rawRace = NSNumber(value: newRace.rawRaceValue as Int)
            rawSubrace = newRace.rawSubraceValue.map({ NSNumber(value: $0 as Int) })
        }
    }
    @NSManaged fileprivate var rawRace: NSNumber
    @NSManaged fileprivate var rawSubrace: NSNumber?
    
    /// Class of the character.
    var characterClass: CharacterClass {
        get {
            return CharacterClass(rawValue: rawCharacterClass.intValue)!
        }
        set(newCharacterClass) {
            rawCharacterClass = NSNumber(value: newCharacterClass.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawCharacterClass: NSNumber
    
    /// Background of the character.
    var background: Background {
        get {
            return Background(rawValue: rawBackground.intValue)!
        }
        set(newBackground) {
            rawBackground = NSNumber(value: newBackground.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawBackground: NSNumber

    /// Alignment of the character
    var alignment: Alignment {
        get {
            return Alignment(rawValue: rawAlignment.intValue)!
        }
        set(newAlignment) {
            rawAlignment = NSNumber(value: newAlignment.rawValue as Int)
        }
    }
    @NSManaged fileprivate var rawAlignment: NSNumber
    
    /// Experience points earned by the character.
    var xp: Int {
        get {
            return rawXP.intValue
        }
        set(newXP) {
            rawXP = NSNumber(value: newXP as Int)
        }
    }
    @NSManaged fileprivate var rawXP: NSNumber
    
    /// String-formatted version of `xp`.
    ///
    /// Formatted as "12,345 XP".
    var xpString: String {
        let xpFormatter = NumberFormatter()
        xpFormatter.numberStyle = .decimal
        
        let xpString = xpFormatter.string(from: NSNumber(xp))!
        return "\(xpString) XP"
    }
    
    /// Level of the character.
    ///
    /// Based on the character's current XP.
    var level: Int {
        return sharedRules.levelXP.filter({ $0.1 <= xp }).map({ $0.0 }).max()!
    }
    
    /// Passive perception score for the character.
    ///
    /// Unlike `Monster` this is a static value stored for the player's character, rather than calculated from player's stats. This is because we don't want to track all the player's stats, both for effort, and to avoid meta-gaming.
    var passivePerception: Int {
        get {
            return rawPassivePerception.intValue
        }
        set(newPassivePerception) {
            rawPassivePerception = NSNumber(value: newPassivePerception as Int)
        }
    }
    @NSManaged fileprivate var rawPassivePerception: NSNumber
    
    /// Set of saving throws that the character if proficient in.
    ///
    /// Each member is a `PlayerSavingThrow`.
    @NSManaged var savingThrows: NSSet
    
    /// Set of skills that the character is proficient in.
    ///
    /// Each member is a `PlayerSkill`.
    @NSManaged var skills: NSSet
    
    /// Adventures that the character is involved in.
    ///
    /// Each member is an `Adventure`.
    @NSManaged var adventures: NSSet
    
    /// Games that the character has played.
    ///
    /// Each member is a `PlayedGame` linking to the appropriate `Game`, along with details of XP, items, etc. earned during that game.
    @NSManaged var playedGames: NSSet
    
    /// Encounters that the character is involved in.
    ///
    /// Each member is a `Combatant` linking the character to its encounter, and describing the current state of the character such as conditions, etc.
    @NSManaged var combatants: NSSet

    convenience init(insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.Player, in: context)
        self.init(entity: entity, insertInto: context)
        
        name = ""
        playerName = ""
    }
    
    /// Returns whether the player is proficient with a given saving throw.
    func isProficient(withSavingThrow savingThrow: Ability) -> Bool {
        return savingThrows.map({ ($0 as! PlayerSavingThrow).savingThrow }).contains(savingThrow)
    }
    
    /// Returns whether the player is proficient with a given skill.
    func isProficient(withSkill skill: Skill) -> Bool {
        return skills.map({ ($0 as! PlayerSkill).skill }).contains(skill)
    }
    
    // MARK: Validation
    
    func validateName(_ ioObject: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let name = ioObject.pointee as? String, name != "" else {
            let errorString = "Name can't be empty"
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Player", code: NSManagedObjectValidationError, userInfo: userDict)
        }
    }
    
}

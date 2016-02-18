//
//  Encounter.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/10/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Encounter represents a combat encounter with one or more players participating, generally against one or more monsters.
///
/// Encounters are created as part of Adventures, and played as part of Games. Each participating member of the Encounter is tracked as a Combatant.
final class Encounter: NSManagedObject {
    
    /// The Adventure that this Encounter is a part of.
    @NSManaged var adventure: Adventure
    
    /// The set of Games that this Encounter has been played in.
    ///
    /// Each member is a `Game`. An Encounter can exist in multiple Games where it's particularly long, with each Game picking up from where the previous game left off.
    @NSManaged var games: NSSet
    
    /// Timestamp when the Encounter object was last modified.
    @NSManaged var lastModified: NSDate
    
    /// Optionally provided name of the encounter.
    ///
    /// Generally for UI use the `title` property instead.
    @NSManaged var name: String?
    
    /// Title for the encounter.
    var title: String {
        if let name = name {
            return name
        }
        
        let sortDescriptor = NSSortDescriptor(key: "monster.challenge", ascending: false)
        let sortedCombatants = (combatants.sortedArrayUsingDescriptors([sortDescriptor]) as! [Combatant])
        if sortedCombatants.count > 0 {
            if let monster = sortedCombatants[0].monster {
                let count = sortedCombatants.filter { return $0.monster == monster }.count

                let plural: String
                if count > 1 {
                    plural = "\(count) " + (monster.name.hasSuffix("s") ? "\(monster.name)es" : "\(monster.name)s")
                } else {
                    plural = monster.name
                }
                
                let otherCount = sortedCombatants.count - count
                if otherCount > 1 {
                    return "\(plural) and \(otherCount) others"
                } else if otherCount == 1 {
                    return "\(plural) and \(otherCount) other"
                } else {
                    return plural
                }
            }
        }
        
        return "Encounter"
    }
    
    /// The set of players and monsters participating in the encounter.
    ///
    /// Each member is a `Combatant` linking the player or monster, and tracking Encounter-specific stats.
    @NSManaged var combatants: NSSet
    
    convenience init(adventure: Adventure, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Encounter, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.adventure = adventure
    
        lastModified = NSDate()
    }

    /// Returns the total XP for all monsters in the encounter.
    func totalXP() -> Int {
        return combatants.filter({ ($0 as! Combatant).role == .Foe }).map({ ($0 as! Combatant).monster!.XP }).reduce(0, combine: +)
    }
    
    /// Calculate the difficulty of the encounter.
    ///
    /// This is based on the challenge for the set of players in the encounter, when encountering the set of monsters in the encounter, and is calculated according to the rules of the Dungeon Master's Guide.
    ///
    /// - parameter forGame: specific game in the Adventure, used when the encounter has no player combatants yet (default nil).
    /// - parameter allyAdjusted: whether to adjust the XP of monster foes by the XP of monster allies (default true).
    ///
    /// - returns: the difficulty of the encounter.
    func calculateDifficulty(forGame game: Game? = nil, allyAdjusted: Bool = true) -> EncounterDifficulty? {
        var players: [Player] = []
        var monsterLevels: [NSDecimalNumber] = []
        var allyXP = 0, allyCount = 0
        for case let combatant as Combatant in combatants {
            if let player = combatant.player {
                players.append(player)
            } else if let monster = combatant.monster {
                // Ignore monsters with 0 XP.
                guard monster.XP > 0 else { continue }

                switch combatant.role {
                case .Foe:
                    monsterLevels.append(monster.challenge)
                case .Friend, .Player:
                    // The DMG doesnt say how to adjust encounter difficulty to account for NPCs that are friendly to the characters, the simplest solution is to add up their XP and subtract that from the monster XP (ie. 500 XP of allies needs 500 XP of monsters added to the adventure to be equivalent to one without any allies).
                    if allyAdjusted {
                        allyXP += monster.XP
                        allyCount += 1
                    }
                }
            }
        }
        
        // Encounters without monsters don't have a difficulty.
        if monsterLevels.count == 0 {
            return nil
        }
        
        // If the encounter doesn't yet have player combatants, use the players in the game, or the players in the encounter.
        if players.count == 0 {
            if let game = game {
                players = game.playedGames.map({ ($0 as! PlayedGame).player })
            } else {
                players = adventure.players.allObjects as! [Player]
            }
        }
        
        // Unlikely, but an encounter without any players can't have a difficulty either.
        if players.count == 0 {
            return nil
        }

        // Ignore monters with a level "significantly lower" than the average; I'm choosing to mean less than 5.
        let meanLevel = monsterLevels.map({ Float($0) }).reduce(0.0, combine: +) / Float(monsterLevels.count)
        let monsterXPs = monsterLevels.filter({ $0.floatValue >= meanLevel - 5.0 }).map({ sharedRules.challengeXP[$0]! })

        var index = sharedRules.monsterXPMultiplier.indexOf({ $0.0 <= monsterXPs.count })!
        if (players.count + allyCount) < 3 {
            index -= 1
        } else if (players.count + allyCount) > 5 {
            index += 1
        }

        let multiplier = sharedRules.monsterXPMultiplier[index].1
        let modifiedXP = Int(Float(monsterXPs.reduce(-allyXP, combine: +)) * multiplier)
        
        // Calculate thresholds for players.
        var easyThreshold = 0, mediumThreshold = 0, hardThreshold = 0, deadlyThreshold = 0
        for player in players {
            let thresholds = sharedRules.levelXPThreshold[player.level]!
            
            easyThreshold += thresholds[0]
            mediumThreshold += thresholds[1]
            hardThreshold += thresholds[2]
            deadlyThreshold += thresholds[3]
        }
        
        if deadlyThreshold < modifiedXP {
            return .Deadly
        } else if hardThreshold < modifiedXP {
            return .Hard
        } else if mediumThreshold < modifiedXP {
            return .Medium
        } else if easyThreshold < modifiedXP {
            return .Easy
        } else {
            return EncounterDifficulty.None
        }
    }
    
    /// Current round number.
    ///
    /// Rounds are intended to last six seconds, the first round will have the value 1 so a round of 0 indicates an encounter still being created.
    var round: Int {
        get {
            return rawRound.integerValue
        }
        set(newRound) {
            rawRound = NSNumber(integer: newRound)
        }
    }
    @NSManaged private var rawRound: NSNumber
    
}

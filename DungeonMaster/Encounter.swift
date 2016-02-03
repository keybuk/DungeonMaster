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

                if count > 1 {
                    if count < sortedCombatants.count {
                        return "\(count) \(monster.name)s and \(sortedCombatants.count - count) others"
                    } else {
                        return "\(count) \(monster.name)s"
                    }
                } else if sortedCombatants.count > 1 {
                    return "\(monster.name) and \(sortedCombatants.count - 1) others"
                } else {
                    return "\(monster.name)"
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
    /// - returns: the difficulty of the encounter.
    func calculateDifficulty(forGame game: Game? = nil) -> EncounterDifficulty? {
        var players: [Player] = []
        var monsterLevels: [NSDecimalNumber] = []
        for case let combatant as Combatant in combatants {
            if let player = combatant.player {
                players.append(player)
            } else if let monster = combatant.monster {
                // The book doesn't really say anything about calculating encounter XP involving player-controlled or friendly monsters.
                // Likewise it seems sensible to ignore monsters with 0 XP.
                guard combatant.role == .Foe else { continue }
                guard monster.XP > 0 else { continue }

                monsterLevels.append(monster.challenge)
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
        if players.count < 3 {
            index -= 1
        } else if players.count > 5 {
            index += 1
        }

        let multiplier = sharedRules.monsterXPMultiplier[index].1
        let modifiedXP = Int(Float(monsterXPs.reduce(0, combine: +)) * multiplier)
        
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
    
}

//
//  Encounter.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/10/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


/// Encounter represents a combat encounter with one or more players participating, generally against one or more monsters.
///
/// Encounters are created as part of Adventures, and played as part of Games. Each participating member of the Encounter is tracked as a Combatant.
final class Encounter : NSManagedObject {
    
    /// The Adventure that this Encounter is a part of.
    @NSManaged var adventure: Adventure
    
    /// The set of Games that this Encounter has been played in.
    ///
    /// Each member is a `Game`. An Encounter can exist in multiple Games where it's particularly long, with each Game picking up from where the previous game left off.
    @NSManaged var games: NSSet
    
    /// Timestamp when the Encounter object was last modified.
    @NSManaged var lastModified: Date
    
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
        let sortedCombatants = (combatants.sortedArray(using: [sortDescriptor]) as! [Combatant]).filter({ $0.role == .foe })
        if sortedCombatants.count > 0 {
            if let monster = sortedCombatants[0].monster {
                let count = sortedCombatants.filter({ return $0.monster == monster }).count

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
    
    /// Current round number.
    ///
    /// Rounds are intended to last six seconds, the first round will have the value 1 so a round of 0 indicates an encounter still being created.
    var round: Int {
        get {
            return rawRound.intValue
        }
        set(newRound) {
            rawRound = NSNumber(value: newRound as Int)
        }
    }
    @NSManaged fileprivate var rawRound: NSNumber
    
    /// XP awarded from this Encounter.
    ///
    /// Each member is an `XPAward` linking the encounter to the player that received the award.
    @NSManaged var xpAwards: NSSet
    
    convenience init(adventure: Adventure, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.Encounter, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.adventure = adventure
    
        lastModified = Date()
    }

    /// Adds `game` to the encounter.
    func addGame(_ game: Game) {
        mutableSetValue(forKey: "games").add(game)
    }
    
    /// Removes `game` from the encounter.
    func removeGame(_ game: Game) {
        mutableSetValue(forKey: "games").remove(game)
    }

    /// Returns the total XP for all monsters in the encounter.
    func totalXP() -> Int {
        return combatants.filter({ ($0 as! Combatant).role == .foe }).map({ ($0 as! Combatant).monster!.xp }).reduce(0, +)
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
                guard monster.xp > 0 else { continue }

                switch combatant.role {
                case .foe:
                    monsterLevels.append(monster.challenge)
                case .friend, .player:
                    // The DMG doesnt say how to adjust encounter difficulty to account for NPCs that are friendly to the characters, the simplest solution is to add up their XP and subtract that from the monster XP (ie. 500 XP of allies needs 500 XP of monsters added to the adventure to be equivalent to one without any allies).
                    if allyAdjusted {
                        allyXP += monster.xp
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
        let meanLevel = monsterLevels.map({ Float($0) }).reduce(0.0, +) / Float(monsterLevels.count)
        let monsterXPs = monsterLevels.filter({ $0.floatValue >= meanLevel - 5.0 }).map({ sharedRules.challengeXP[$0]! })

        var index = sharedRules.monsterXPMultiplier.index(where: { $0.0 <= monsterXPs.count })!
        if (players.count + allyCount) < 3 {
            index -= 1
        } else if (players.count + allyCount) > 5 {
            index += 1
        }

        let multiplier = sharedRules.monsterXPMultiplier[index].1
        let modifiedXP = Int(Float(monsterXPs.reduce(-allyXP, +)) * multiplier)
        
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
            return .deadly
        } else if hardThreshold < modifiedXP {
            return .hard
        } else if mediumThreshold < modifiedXP {
            return .medium
        } else if easyThreshold < modifiedXP {
            return .easy
        } else {
            return EncounterDifficulty.none
        }
    }
    
    /// Returns an NSFetchRequest for the encounter's combatants.
    ///
    /// The returned fetch request is sorted correctly for the combat initiative order.
    ///
    /// - parameter role: optional combat role to filter on.
    func fetchRequestForCombatants(withRole role: CombatRole? = nil) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: Model.Combatant)
        
        let encounterPredicate = NSPredicate(format: "encounter == %@", self)
        if let role = role {
            let rolePredicate = NSPredicate(format: "rawRole == %@", NSNumber(value: role.rawValue as Int))
            
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [encounterPredicate, rolePredicate])
        } else {
            fetchRequest.predicate = encounterPredicate
        }
        
        let initiativeSortDescriptor = NSSortDescriptor(key: "rawInitiative", ascending: false)
        let initiativeOrderSortDescriptor = NSSortDescriptor(key: "rawInitiativeOrder", ascending: true)
        let monsterDexSortDescriptor = NSSortDescriptor(key: "monster.rawDexterityScore", ascending: false)
        let dateCreatedSortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: true)
        fetchRequest.sortDescriptors = [initiativeSortDescriptor, initiativeOrderSortDescriptor, monsterDexSortDescriptor, dateCreatedSortDescriptor]
        
        return fetchRequest
    }
    
    /// Updates the encounter, rolling initiative for monsters that have not yet done so.
    ///
    /// - returns: true if initiative was rolled.
    func rollInitiative() -> Bool {
        var rolled = false
        
        // Gather the pre-rolled initiative values for monsters.
        var prerolledInitiative: [Monster: Int] = [:]
        for case let combatant as Combatant in combatants {
            guard combatant.role != .player else { continue }
            guard let monster = combatant.monster else { continue }
            guard let initiative = combatant.initiative else { continue }
            
            prerolledInitiative[monster] = initiative
        }
        
        // Now go back and roll initiative where we need to, making sure we use the same new roll for all monsters of the same type too.
        var initiativeDice: [Monster: DiceCombo] = [:]
        for case let combatant as Combatant in combatants {
            guard combatant.role != .player else { continue }
            guard let monster = combatant.monster else { continue }
            guard combatant.initiative == nil else { continue }
            
            if let initiative = prerolledInitiative[monster] {
                combatant.initiative = initiative
            } else if let combo = initiativeDice[monster] {
                combatant.initiative = combo.value
            } else {
                let combo = monster.initiativeDice.reroll()
                initiativeDice[monster] = combo
                combatant.initiative = combo.value
                rolled = true
            }
        }

        return rolled
    }

    /// Select the next combatants in the turn order.
    ///
    /// Updates the `currentTurn` of combatants in the encounter, and may update `round`.
    func nextTurn() {
        let fetchRequest = fetchRequestForCombatants()
        let combatants = try! managedObjectContext!.fetch(fetchRequest) as! [Combatant]
        
        // First clear the turn of the current combatants, remembering the first and last combatant whose turn it was.
        let turnIndex = combatants.index(where: { $0.isCurrentTurn })
        var lastTurnIndex = turnIndex
        for (index, combatant) in combatants.enumerated() {
            if combatant.isCurrentTurn {
                combatant.isCurrentTurn = false
                lastTurnIndex = index
            }
        }

        // Rotate the list so that the combatant who just took a turn is right at the end, this gives us an order to consider them in. Filter out non-player characters that are dead (we don't track player deaths).
        let nextTurnIndex = lastTurnIndex.map({ $0 + 1 }) ?? 0
        let nextCombatants = (combatants.suffix(from: nextTurnIndex) + combatants.prefix(upTo: nextTurnIndex)).filter({ $0.isAlive })
        for nextCombatant in nextCombatants {
            // Only consider combatants with the same initiative, role, underlying monster/player, etc.
            guard nextCombatant.initiative == nextCombatants.first?.initiative &&  nextCombatant.role == nextCombatants.first?.role && nextCombatant.monster == nextCombatants.first?.monster && nextCombatant.player == nextCombatants.first?.player else { break }

            nextCombatant.isCurrentTurn = true
        }

        // Check whether we began a new round.
        if let newTurnIndex = combatants.index(where: { $0.isCurrentTurn }), newTurnIndex <= turnIndex {
            round += 1
        }
    }
    
    /// Adds missing players from `game` to the encounter.
    func addPlayers(fromGame game: Game) {
        for case let playedGame as PlayedGame in game.playedGames {
            let _ = Combatant(encounter: self, player: playedGame.player, insertInto: managedObjectContext!)
        }
    }
    
}

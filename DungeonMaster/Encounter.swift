//
//  Encounter.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/10/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

final class Encounter: NSManagedObject {
    
    @NSManaged var lastUsed: NSDate
    @NSManaged var name: String?
    
    @NSManaged var combatants: NSSet

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

    // MARK: Internal properties
    
    var notificationObserver: NSObjectProtocol?
    
    convenience init(inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Encounter, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        lastUsed = NSDate()
    }
    
    deinit {
        if let notificationObserver = notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(notificationObserver)
        }
    }

    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        observeChanges()
    }
    
    override func awakeFromFetch() {
        super.awakeFromFetch()
        
        observeChanges()
    }
    
    /// Encounter maintains a lastUsed property that is updated automatically when the encounter object itself changes, combatants are added to or removed from the encounter, or any of the combatants in the encounter is changed.
    func observeChanges() {
        guard notificationObserver == nil else { return }
    
        notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: nil) { notification in
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
                var interestingObjects = Set<NSManagedObject>()
                interestingObjects.insert(self)
                interestingObjects.unionInPlace(self.combatants.allObjects as! [NSManagedObject])
                
                if updatedObjects.intersectsSet(interestingObjects) {
                    self.setPrimitiveValue(NSDate(), forKey: "lastUsed")
                }
            }
        }
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
    func calculateDifficulty() -> EncounterDifficulty? {
        var easyThreshold = 0, mediumThreshold = 0, hardThreshold = 0, deadlyThreshold = 0, playerCount = 0
        var monsterLevels = [NSDecimalNumber]()
        for case let combatant as Combatant in combatants {
            if let player = combatant.player {
                let thresholds = sharedRules.levelXPThreshold[player.level]!

                easyThreshold += thresholds[0]
                mediumThreshold += thresholds[1]
                hardThreshold += thresholds[2]
                deadlyThreshold += thresholds[3]
                
                playerCount += 1
            } else if let monster = combatant.monster {
                // The book doesn't really say anything about calculating encounter XP involving player-controlled or friendly monsters.
                // Likewise it seems sensible to ignore monsters with 0 XP.
                guard combatant.role == .Foe else { continue }
                guard monster.XP > 0 else { continue }

                monsterLevels.append(monster.challenge)
            }
        }
        
        // Encounters without monsters and players don't have a difficulty.
        if monsterLevels.count == 0 || playerCount == 0 {
            return nil
        }
        
        // Ignore monters with a level "significantly lower" than the average; I'm choosing to mean less than 5.
        let meanLevel = monsterLevels.map({ Float($0) }).reduce(0.0, combine: +) / Float(monsterLevels.count)
        let monsterXPs = monsterLevels.filter({ $0.floatValue >= meanLevel - 5.0 }).map({ sharedRules.challengeXP[$0]! })

        var index = sharedRules.monsterXPMultiplier.indexOf({ $0.0 <= monsterXPs.count })!
        if playerCount < 3 {
            index -= 1
        } else if playerCount > 5 {
            index += 1
        }

        let multiplier = sharedRules.monsterXPMultiplier[index].1
        let modifiedXP = Int(Float(monsterXPs.reduce(0, combine: +)) * multiplier)
        
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

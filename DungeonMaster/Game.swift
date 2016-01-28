//
//  Game.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/16/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Game represents a single game session in a long-running adventure.
final class Game: NSManagedObject {
    
    /// The Adventure that this Game is a part of.
    @NSManaged var adventure: Adventure
    
    /// The number in sequence of this game in the adventure.
    var number: Int {
        get {
            return rawNumber.integerValue
        }
        set(newNumber) {
            rawNumber = NSNumber(integer: newNumber)
        }
    }
    @NSManaged private var rawNumber: NSNumber
    
    /// The date of this Game.
    @NSManaged var date: NSDate
    
    /// Players that participated in this game.
    ///
    /// Each member is a `PlayedGame` linking to the appropriate `Game`, along with details of XP, items, etc. earned during that game.
    @NSManaged var playedGames: NSSet
    
    /// Encounters run as part of this game.
    ///
    /// Each member is an `Encounter`. Encounters may exist across multiple games until they have been completed.
    @NSManaged var encounters: NSSet
    
    convenience init(adventure: Adventure, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Game, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.adventure = adventure
        
        number = adventure.games.count
        date = NSDate()
        
        for case let player as Player in adventure.players {
            let _ = PlayedGame(game: self, player: player, inManagedObjectContext: context)
        }
    }

}
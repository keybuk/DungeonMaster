//
//  PlayedGame.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/18/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// PlayedGame represents a player participating in a single game session of a long-running adventure.
final class PlayedGame: NSManagedObject {
    
    /// The Game that the player played.
    @NSManaged var game: Game
    
    /// The Player that played the game.
    @NSManaged var player: Player
    
    /// Log entries for the player in this game.
    ///
    /// Each member is a subclass of `LogEntry`, providing the details of the specific entry.
    @NSManaged var logEntries: NSSet

    convenience init(game: Game, player: Player, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.PlayedGame, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.game = game
        self.player = player
    }
    
}
//
//  LogEntry.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/23/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// LogEntry represents an entry in the player's quest log, an abstract concept of an ordered list of items related to a player's game.
class LogEntry : NSManagedObject {
    
    /// The PlayedGame object referencing both the player and the game.
    @NSManaged var playedGame: PlayedGame
    
    /// Index of this entry in the set for the player.
    var index: Int {
        get {
            return rawIndex.intValue
        }
        set(newIndex) {
            rawIndex = NSNumber(value: newIndex as Int)
        }
    }
    @NSManaged fileprivate var rawIndex: NSNumber
    
    convenience init(model: Model, playedGame: PlayedGame, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: model, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.playedGame = playedGame
        self.index = playedGame.logEntries.count + 1
    }
    
    /// Returns InDesign Tagged Text description of the log entry.
    func descriptionForExport() -> String {
        return ""
    }
    
}

//
//  LogEntryNote.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/27/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// LogEntryNote represents any textual note added to a player's log during a game.
///
/// Ideally these will all get their own specific classes, but there's always reason to have some kind of simple text field in a game.
final class LogEntryNote : LogEntry {
    
    /// Note text.
    @NSManaged var note: String
    
    convenience init(playedGame: PlayedGame, inManagedObjectContext context: NSManagedObjectContext) {
        self.init(model: Model.LogEntryNote, playedGame: playedGame, inManagedObjectContext: context)
    }

    /// Returns InDesign Tagged Text description of the log entry.
    override func descriptionForExport() -> String {
        return note.replacingOccurrences(of: "'", with: "<0x2019>")
    }

}

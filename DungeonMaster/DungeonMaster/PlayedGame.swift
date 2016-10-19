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
final class PlayedGame : NSManagedObject {
    
    /// The Game that the player played.
    @NSManaged var game: Game
    
    /// The Player that played the game.
    @NSManaged var player: Player
    
    /// Log entries for the player in this game.
    ///
    /// Each member is a subclass of `LogEntry`, providing the details of the specific entry.
    @NSManaged var logEntries: NSSet

    convenience init(game: Game, player: Player, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.PlayedGame, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.game = game
        self.player = player
    }
    
    /// Returns InDesign Tagged Text description of the played game.
    func descriptionForExport() -> String {
        // Identify where this game is in the set of games played by this player.
        let dateSortDescriptor = NSSortDescriptor(key: "game.date", ascending: true)
        let playedGames = player.playedGames.sortedArray(using: [dateSortDescriptor]) as! [PlayedGame]
        let gameIndex = playedGames.index(of: self)!
        
        // XP is calculated excluding the XP from this game, and any future game.
        var xp = player.xp
        for playedGame in playedGames.suffix(from: gameIndex) {
            for case let xpAward as XPAward in playedGame.logEntries {
                xp -= xpAward.xp
            }
        }
        
        let xpFormatter = NumberFormatter()
        xpFormatter.numberStyle = .decimal
        
        let xpString = xpFormatter.string(from: NSNumber(xp))!

        // Level is based from this starting XP value.
        let level = sharedRules.levelXP.filter({ $0.1 <= xp }).map({ $0.0 }).max()!
        
        var string = "<ParaStyle:XP Card\\:Character Name>\(player.name)\n"
        string += "<ParaStyle:XP Card\\:Character Level>\(player.race.stringValue)\t\(player.characterClass.stringValue) \(level)\t\(player.background.stringValue)\t\(xpString) XP\n"

        // Body begins with the adventure name, and (FIXME) in-game date.
        string += "<ParaStyle:XP Card\\:Setting>\(game.adventure.name)\n"//, Melting 12
        
        let indexSortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        var lastType: LogEntry.Type? = nil
        for case let logEntry as LogEntry in logEntries.sortedArray(using: [indexSortDescriptor]) {
            if type(of: logEntry) == lastType {
                string += "<0x000A>"
            } else {
                if lastType != nil {
                    string += "\n"
                }
                string += "<ParaStyle:XP Card\\:Body>"
            }
            
            string += logEntry.descriptionForExport()

            lastType = type(of: logEntry)
        }
        
        if lastType != nil {
            string += "\n"
        }
        
        // Final line is the game date, and card number for the player.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"

        let dateString = dateFormatter.string(from: game.date as Date)
        
        string += "<ParaStyle:XP Card\\:Card Number>\(dateString), #\(gameIndex + 1)\n"

        return string
    }
    
}

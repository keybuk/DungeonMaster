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
    
    /// Returns InDesign Tagged Text description of the played game.
    func descriptionForExport() -> String {
        // Identify where this game is in the set of games played by this player.
        let dateSortDescriptor = NSSortDescriptor(key: "game.date", ascending: true)
        let playedGames = player.playedGames.sortedArrayUsingDescriptors([dateSortDescriptor]) as! [PlayedGame]
        let gameIndex = playedGames.indexOf(self)!
        
        // XP is calculated excluding the XP from this game, and any future game.
        var xp = player.XP
        for playedGame in playedGames.suffixFrom(gameIndex) {
            for case let xpAward as XPAward in playedGame.logEntries {
                xp -= xpAward.xp
            }
        }
        
        let xpFormatter = NSNumberFormatter()
        xpFormatter.numberStyle = .DecimalStyle
        
        let xpString = xpFormatter.stringFromNumber(xp)!

        // Level is based from this starting XP value.
        let level = sharedRules.levelXP.filter({ $0.1 <= xp }).map({ $0.0 }).maxElement()!
        
        var string = "<ParaStyle:XP Card\\:Character Name>\(player.name)\n"
        string += "<ParaStyle:XP Card\\:Character Level>\(player.race.stringValue)\t\(player.characterClass.stringValue) \(level)\t\(player.background.stringValue)\t\(xpString) XP\n"

        // Body begins with the adventure name, and (FIXME) in-game date.
        string += "<ParaStyle:XP Card\\:Setting>\(game.adventure.name)\n"//, Melting 12
        
        let indexSortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        var lastType: LogEntry.Type? = nil
        for case let logEntry as LogEntry in logEntries.sortedArrayUsingDescriptors([indexSortDescriptor]) {
            if logEntry.dynamicType == lastType {
                string += "<0x000A>"
            } else {
                if lastType != nil {
                    string += "\n"
                }
                string += "<ParaStyle:XP Card\\:Body>"
            }
            
            switch logEntry {
            case let xpAward as XPAward:
                let xpString = xpFormatter.stringFromNumber(xpAward.xp)!
                let reason = xpAward.reason.stringByReplacingOccurrencesOfString("'", withString: "<0x2019>")
                
                string += "+\(xpString) XP\t\(reason)"
            case let logEntryNote as LogEntryNote:
                string += logEntryNote.note.stringByReplacingOccurrencesOfString("'", withString: "<0x2019>")
            default:
                break
            }
            
            lastType = logEntry.dynamicType
        }
        
        if lastType != nil {
            string += "\n"
        }
        
        // Final line is the game date, and card number for the player.
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "M/d"

        let dateString = dateFormatter.stringFromDate(game.date)
        
        string += "<ParaStyle:XP Card\\:Card Number>\(dateString), #\(gameIndex + 1)\n"

        return string
    }
    
}
//
//  XPAward.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/22/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// XPAward represents an award of XP given to a player during a game.
final class XPAward: LogEntry {
    
    /// Amount of XP that was awarded to the player.
    var xp: Int {
        get {
            return rawXP.integerValue
        }
        set(newXP) {
            rawXP = NSNumber(integer: newXP)
        }
    }
    @NSManaged private var rawXP: NSNumber
    
    /// String-formatted version of `xp`.
    ///
    /// Formatted as "12,345 XP".
    var xpString: String {
        let xpFormatter = NSNumberFormatter()
        xpFormatter.numberStyle = .DecimalStyle
        
        let xpString = xpFormatter.stringFromNumber(xp)!
        return "\(xpString) XP"
    }

    /// Reason that the XP was awarded.
    @NSManaged var reason: String
    
    /// Encounter that the XP was awarded for.
    ///
    /// This is generally used for monster-specific XP, with the monsters listed in `combatants`.
    @NSManaged var encounter: Encounter?
    
    /// Combatants that the XP was awarded for.
    ///
    /// Each member is a `Combatant` linking to the specific monster.
    @NSManaged var combatants: NSSet

    convenience init(playedGame: PlayedGame, inManagedObjectContext context: NSManagedObjectContext) {
        self.init(model: Model.XPAward, playedGame: playedGame, inManagedObjectContext: context)
    }
    
    /// Returns InDesign Tagged Text description of the log entry.
    override func descriptionForExport() -> String {
        return "\(xpString)\t" + reason.stringByReplacingOccurrencesOfString("'", withString: "<0x2019>")
    }

}
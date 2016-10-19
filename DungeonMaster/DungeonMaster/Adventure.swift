//
//  Adventure.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/6/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Adventure represents a D&D campaign or adventure.
///
/// It's a top-level object in the model under which all user content is grouped.
final class Adventure : NSManagedObject {
    
    /// Timestamp when the Adventure object was last modified.
    @NSManaged var lastModified: Date

    /// Name of the adventure.
    @NSManaged var name: String
    
    /// Image associated with the adventure.
    @NSManaged var image: AdventureImage
    
    /// Books that the adventure uses for source material.
    ///
    /// Each member is a `Book`. New adventures automatically gain all books that exist at creation time.
    @NSManaged var books: NSSet
    
    /// Players participating in the adventure.
    ///
    /// Each member is a `Player`. New adventures automatically gain all players that exist at creation time.
    @NSManaged var players: NSSet
    
    /// Encounters that may take place in the adventure.
    ///
    /// Each member is an `Encounter`. Encounters may be created in the Adventure before being added to Games for the purposes of planning, once attached to one or more Games, it should usually be omitted from the adventure but will be present in this set.
    @NSManaged var encounters: NSSet
    
    /// The set of games played so far in this adventure.
    ///
    /// Each member is a `Game`.
    @NSManaged var games: NSSet

    convenience init(insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.Adventure, in: context)
        self.init(entity: entity, insertInto: context)
        
        name = ""
        
        lastModified = Date()
        image = AdventureImage(adventure: self, insertInto: context)
        
        books = NSSet(array: try! context.fetch(NSFetchRequest(entity: Model.Book)) )
        players = NSSet(array: try! context.fetch(NSFetchRequest(entity: Model.Player)) )
    }

    // MARK: Validation
    
    func validateName(_ ioObject: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let name = ioObject.pointee as? String, name != "" else {
            let errorString = "Name can't be empty"
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Adventure", code: NSManagedObjectValidationError, userInfo: userDict)
        }
    }
    
    /// Adds `player` to the adventure.
    func addPlayer(_ player: Player) {
        mutableSetValue(forKey: "players").add(player)
    }
    
    /// Removes `player` from the adventure.
    func removePlayer(_ player: Player) {
        mutableSetValue(forKey: "players").remove(player)
    }

    /// Adds missing players from `game` to the adventure.
    func addPlayers(fromGame game: Game) {
        let adventurePlayers = mutableSetValue(forKey: "players")
        adventurePlayers.addObjects(from: game.playedGames.map({ ($0 as! PlayedGame).player }))
    }
    
}

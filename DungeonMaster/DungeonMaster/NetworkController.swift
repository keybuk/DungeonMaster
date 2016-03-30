//
//  NetworkController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/7/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import DungeonKit
import Foundation

/// NetworkController manages the relationship between the Dungeon Master app, and player etc. apps on the DungeonNet.
///
/// This is designed with a MVC approach in mind, where the core data is the Model, the `NetworkPeer` is the View (ish), and this class is the Controller. Rather than having the apps own views try and influence the network, this watches the core data model directly and uses that to inform the network, as such this class consists of a bunch of fetch requests/results controllers and delegates based on that.
class NetworkController : NSObject, NetworkPeerDelegate, NetworkConnectionDelegate, NSFetchedResultsControllerDelegate {
    
    var networkPeer: NetworkPeer
    
    /// Controller that monitors the set of encounters.
    ///
    /// This yields a set of Encounter objects that have been started (the round is greater than 0), and are members of games on today's date, reverse sorted by when they were last modified.
    lazy var encounterResultsController: NSFetchedResultsController = { [unowned self] in
        let calendar = NSCalendar.currentCalendar()
        let today = calendar.startOfDayForDate(NSDate())
        let tomorrow = calendar.dateByAddingUnit(.Day, value: 1, toDate: today, options: [])!
        
        let fetchRequest = NSFetchRequest(entity: Model.Encounter)
        fetchRequest.predicate = NSPredicate(format: "rawRound > 0 AND SUBQUERY(games, $g, $g.date >= %@ AND $g.date < %@).@count > 0", today, tomorrow)
        
        let lastModifiedSortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [lastModifiedSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        return fetchedResultsController
    }()
    
    /// Controller that monitors the set of combatants in the encounter.
    ///
    /// This yields the correctly sorted set of Combatant objects for the first encounter in the encounter results controller.
    var combatantResultsController: NSFetchedResultsController? {
        // Can't use lazy, this has to be able to be re-fetched after being set to nil (invalidated). Maybe in Swift 3.
        get {
            if let combatantResultsController = _combatantResultsController {
                return combatantResultsController
            }
            
            guard let encounter = self.encounter else { return nil }
            let fetchRequest = encounter.fetchRequestForCombatants()
            
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            
            try! fetchedResultsController.performFetch()
    
            _combatantResultsController = fetchedResultsController
            return fetchedResultsController
        }
    
        set(newCombatantResultsController) {
            _combatantResultsController = newCombatantResultsController
        }
    }
    private var _combatantResultsController: NSFetchedResultsController? = nil

    /// Current encounter.
    var encounter: Encounter? {
        return encounterResultsController.fetchedObjects?.first as? Encounter
    }

    override init() {
        networkPeer = NetworkPeer(type: .DungeonMaster, name: "Dungeon Master", acceptedTypes: [ .InitiativeOrder ])
        
        super.init()

        networkPeer.delegate = self
        networkPeer.start()
    }
    
    /// Suspend the network controller.
    ///
    /// Stops the peer advertising and searching for other peers, also drops the existing connections. Call `resume()` to resume activity again.
    func suspend() {
        networkPeer.stop()
    }
    
    /// Resume the network controller.
    ///
    /// Starts the peer advertising and searching for other peers again.
    func resume() {
        networkPeer.start()
    }
    
    func sendEncounterTo(connection: NetworkConnection) {
        guard let encounter = encounter else { return }
        guard let combatants = combatantResultsController?.fetchedObjects else { return }
        
        // We don't send the real encounter title, but the adventure, or game title.
        var title = encounter.adventure.name
        
        let calendar = NSCalendar.currentCalendar()
        let today = calendar.startOfDayForDate(NSDate())
        let tomorrow = calendar.dateByAddingUnit(.Day, value: 1, toDate: today, options: [])!
        
        for case let game as Game in encounter.games {
            if game.date.compare(today) != .OrderedAscending && game.date.compare(tomorrow) == .OrderedAscending {
                title = game.title
            }
        }
        
        connection.sendMessage(.BeginEncounter(title: title))
        
        var index = 0
        for case let combatant as Combatant in combatants {
            if let monster = combatant.monster {
                connection.sendMessage(.InsertCombatant(toIndex: index, name: monster.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            } else if let player = combatant.player {
                connection.sendMessage(.InsertCombatant(toIndex: index, name: player.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            }
            
            index += 1
        }
        
        connection.sendMessage(.Round(round: encounter.round))
    }

    // MARK: NetworkPeerDelegate
    
    func networkPeer(peer: NetworkPeer, didEstablishConnection connection: NetworkConnection) {
        connection.delegate = self
        
        // After establishing a connection, send the version, and the current encounter to it.
        connection.sendMessage(.Hello(version: NetworkMessage.version))
        sendEncounterTo(connection)
    }
    
    // MARK: NetworkConnectionDelegate

    func combatants(withName name: String) -> [Combatant] {
        var combatantsWithName: [Combatant] = []
        if let combatants = combatantResultsController?.fetchedObjects as? [Combatant] {
            for combatant in combatants {
                if let monster = combatant.monster {
                    guard monster.name == name else { continue }
                } else if let player = combatant.player {
                    guard player.name == name else { continue }
                }

                combatantsWithName.append(combatant)
            }
        }
        return combatantsWithName
    }
    
    
    func connection(connection: NetworkConnection, didReceiveMessage message: NetworkMessage) {
        switch message {
        case let .Hello(version):
            if version != NetworkMessage.version {
                print("Dropping connection with bad version")
                connection.close()
            }
        case let .Initiative(name, initiative):
            for combatant in combatants(withName: name) {
                combatant.initiative = initiative
            }
        case let .EndTurn(name):
            if let combatant = combatants(withName: name).first where combatant.role == .Player && combatant.isCurrentTurn {
                encounter?.nextTurn()
            }
        default:
            break
        }
    }
    
    func connectionDidClose(connection: NetworkConnection) {
    }

    // MARK: NSFetchedResultsControllerDelegate
    
    var currentEncounter: Encounter?

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // Stash the current encounter to see if it changes.
        if controller === encounterResultsController {
            currentEncounter = encounter
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // We're only interested in detailed changes from the combatant results controller, since those result in list-wise changes to the peers.
        guard controller === combatantResultsController else { return }
        
        switch type {
        case .Insert:
            let combatant = anObject as! Combatant
            if let monster = combatant.monster {
                networkPeer.broadcastMessage(.InsertCombatant(toIndex: newIndexPath!.row, name: monster.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            } else if let player = combatant.player {
                networkPeer.broadcastMessage(.InsertCombatant(toIndex: newIndexPath!.row, name: player.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            }
        case .Delete:
            networkPeer.broadcastMessage(.DeleteCombatant(fromIndex: indexPath!.row))
        case .Update:
            let combatant = anObject as! Combatant
            if let monster = combatant.monster {
                networkPeer.broadcastMessage(.UpdateCombatant(index: indexPath!.row, name: monster.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            } else if let player = combatant.player {
                networkPeer.broadcastMessage(.UpdateCombatant(index: indexPath!.row, name: player.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            }
        case .Move:
            networkPeer.broadcastMessage(.MoveCombatant(fromIndex: indexPath!.row, toIndex: newIndexPath!.row))

            let combatant = anObject as! Combatant
            if let monster = combatant.monster {
                networkPeer.broadcastMessage(.UpdateCombatant(index: newIndexPath!.row, name: monster.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            } else if let player = combatant.player {
                networkPeer.broadcastMessage(.UpdateCombatant(index: newIndexPath!.row, name: player.name, initiative: combatant.initiative, isCurrentTurn: combatant.isCurrentTurn, isAlive: combatant.isAlive))
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // Check to see if the current encounter is no longer the stashed one.
        if controller === encounterResultsController {
            if encounter == currentEncounter {
                if let encounter = encounter {
                    // Current encounter did not change, rebroadcast the Round.
                    networkPeer.broadcastMessage(.Round(round: encounter.round))
                }
            } else {
                // Encounter changed, invalidate the set of combatants, and then send the new encounter out.
                combatantResultsController = nil
                
                for connection in networkPeer.connections {
                    sendEncounterTo(connection)
                }
            }
            
            currentEncounter = nil
        }
    }
    
}

//
//  EncounterPlayersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/24/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class EncounterPlayersViewController: UITableViewController {
    
    var encounter: Encounter!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Player)
        
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
    
    // MARK: Actions
    
    @IBAction func allButtonTapped(sender: UIBarButtonItem) {
        for case (let row, let player as Player) in fetchedResultsController.sections![0].objects!.enumerate() {
            let playerPredicate = NSPredicate(format: "rawRole == %@ AND player == %@", NSNumber(integer: CombatRole.Player.rawValue), player)
            if encounter.combatants.filteredSetUsingPredicate(playerPredicate).count == 0 {
                let _ = Combatant(encounter: encounter, player: player, inManagedObjectContext: managedObjectContext)
                
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                cell?.accessoryType = .Checkmark
            }
        }
    }

}

// MARK: UITableViewDataSource
extension EncounterPlayersViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlayerCell", forIndexPath: indexPath)
        let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
        
        cell.textLabel?.text = player.name

        let playerPredicate = NSPredicate(format: "rawRole == %@ AND player == %@", NSNumber(integer: CombatRole.Player.rawValue), player)
        if let _ = encounter.combatants.filteredSetUsingPredicate(playerPredicate).first as? Combatant {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    
}

// MARK: UITableViewDelegate
extension EncounterPlayersViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
        
        let playerPredicate = NSPredicate(format: "rawRole == %@ AND player == %@", NSNumber(integer: CombatRole.Player.rawValue), player)
        if let combatant = encounter.combatants.filteredSetUsingPredicate(playerPredicate).first as? Combatant {
            managedObjectContext.deleteObject(combatant)
        } else {
            let _ = Combatant(encounter: encounter, player: player, inManagedObjectContext: managedObjectContext)
        }
    }
    
}

// MARK: NSFetchedResultsControllerDelegate
extension EncounterPlayersViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

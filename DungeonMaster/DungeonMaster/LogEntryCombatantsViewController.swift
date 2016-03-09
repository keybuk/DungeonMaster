//
//  LogEntryCombatantsViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class LogEntryCombatantsViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var logEntryType: LogEntry.Type!
    var game: Game!
    var encounter: Encounter!
    
    var combatants: Set<Combatant> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for case let combatant as Combatant in fetchedResultsController.fetchedObjects! {
            if combatant.damagePoints >= combatant.hitPoints {
                combatants.insert(combatant)
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickPlayersSegue" {
            let viewController = segue.destinationViewController as! LogEntryPlayersViewController
            viewController.logEntryType = logEntryType
            viewController.game = game
            viewController.encounter = encounter
            viewController.combatants = combatants
        }
    }
    
    // MARK: Actions
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = self.encounter.fetchRequestForCombatants(withRole: .Foe)

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LogEntryCombatantCell", forIndexPath: indexPath) as! LogEntryCombatantCell
        let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
        cell.combatant = combatant
        cell.accessoryType = combatants.contains(combatant) ? .Checkmark : .None
        return cell
    }

    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
        if combatants.contains(combatant) {
            combatants.remove(combatant)
        } else {
            combatants.insert(combatant)
        }
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? LogEntryCombatantCell {
            cell.accessoryType = combatants.contains(combatant) ? .Checkmark : .None
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
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
            let combatant = anObject as! Combatant
            if combatant.damagePoints >= combatant.hitPoints {
                combatants.insert(combatant)
            }

            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Bottom)
        case .Delete:
            let combatant = anObject as! Combatant
            combatants.remove(combatant)

            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Bottom)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LogEntryCombatantCell {
                let combatant = anObject as! Combatant
                cell.combatant = combatant
                cell.accessoryType = combatants.contains(combatant) ? .Checkmark : .None
            }
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LogEntryCombatantCell {
                let combatant = anObject as! Combatant
                cell.combatant = combatant
                cell.accessoryType = combatants.contains(combatant) ? .Checkmark : .None
            }
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

}

// MARK: -

class LogEntryCombatantCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var combatant: Combatant! {
        didSet {
            if let monster = combatant.monster {
                nameLabel.text = monster.name
            } else if let player = combatant.player {
                nameLabel.text = player.name
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

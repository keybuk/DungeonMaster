//
//  LogEntryCombatantsViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class LogEntryCombatantsViewController : UITableViewController, NSFetchedResultsControllerDelegate {

    var logEntryType: LogEntry.Type!
    var game: Game!
    var encounter: Encounter!
    
    var combatants: Set<Combatant> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for combatant in fetchedResultsController.fetchedObjects! {
            if combatant.damagePoints >= combatant.hitPoints {
                combatants.insert(combatant)
            }
        }
        
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickPlayersSegue" {
            let viewController = segue.destination as! LogEntryPlayersViewController
            viewController.logEntryType = logEntryType
            viewController.game = game
            viewController.encounter = encounter
            viewController.combatants = combatants
        }
    }
    
    // MARK: Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController<Combatant> = { [unowned self] in
        let fetchRequest = self.encounter.fetchRequestForCombatants(withRole: .foe)

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogEntryCombatantCell", for: indexPath) as! LogEntryCombatantCell
        let combatant = fetchedResultsController.object(at: indexPath)
        cell.combatant = combatant
        cell.accessoryType = combatants.contains(combatant) ? .checkmark : .none
        return cell
    }

    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let combatant = fetchedResultsController.object(at: indexPath)
        if combatants.contains(combatant) {
            combatants.remove(combatant)
        } else {
            combatants.insert(combatant)
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? LogEntryCombatantCell {
            cell.accessoryType = combatants.contains(combatant) ? .checkmark : .none
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            let combatant = anObject as! Combatant
            if combatant.damagePoints >= combatant.hitPoints {
                combatants.insert(combatant)
            }

            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            let combatant = anObject as! Combatant
            combatants.remove(combatant)

            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? LogEntryCombatantCell {
                let combatant = anObject as! Combatant
                cell.combatant = combatant
                cell.accessoryType = combatants.contains(combatant) ? .checkmark : .none
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}

// MARK: -

class LogEntryCombatantCell : UITableViewCell {
    
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
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

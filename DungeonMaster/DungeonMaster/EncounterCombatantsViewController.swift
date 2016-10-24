//
//  EncounterCombatantsViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/2/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class EncounterCombatantsViewController : UITableViewController, NSFetchedResultsControllerDelegate {
    
    var encounter: Encounter!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Leave the selected combatant always selected as we go in/out of the property views or table top.
        clearsSelectionOnViewWillAppear = false
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let oldEditing = self.isEditing, tableViewLoaded = self.tableViewLoaded
        super.setEditing(editing, animated: animated)
        
        if editing != oldEditing && tableViewLoaded {
            let addSection = fetchedResultsController.sections?.count ?? 0
            if editing {
                tableView.insertSections(IndexSet(integer: addSection), with: .automatic)
            } else {
                tableView.deleteSections(IndexSet(integer: addSection), with: .automatic)
            }
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CombatantSegue" {
            performSegue(withIdentifier: "CombatantMonsterSegue", sender: sender)
            if let indexPath = tableView.indexPathForSelectedRow {
                let combatant = fetchedResultsController.object(at: indexPath)
                let viewController = segue.destination as! CombatantViewController
                viewController.combatant = combatant
            }
        } else if segue.identifier == "CombatantMonsterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let combatant = fetchedResultsController.object(at: indexPath)
                let viewController = segue.destination as! MonsterViewController
                viewController.monster = combatant.monster
            }
        } else if segue.identifier == "AddCombatantSegue" {
            // This is pretty hacky, we're stealing one view and embedding in another just to work around restrictions. The fact this gets complicated, requiring intermediate classes, should show that I shouldn't do things this way and should come up with a better way. I just don't know what that is yet.
            let viewController = segue.destination as! EncounterAddCombatantViewController
            viewController.encounter = encounter
            
            viewController.completionBlock = { cancelled, monster, quantity in
                if let monster = monster, !cancelled {
                    for _ in 1...quantity {
                        let combatant = Combatant(encounter: self.encounter, monster: monster, insertInto: managedObjectContext)
                        combatant.role = .foe
                    }
                    
                    self.encounter.lastModified = Date()
                    try! managedObjectContext.save()
                }
                
                self.dismiss(animated: true, completion: nil)
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            }

        }
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController<Combatant> = { [unowned self] in
        let fetchRequest = self.encounter.fetchRequestForCombatants()
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
    
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    // MARK: UITableViewDataSource

    var tableViewLoaded = false

    override func numberOfSections(in tableView: UITableView) -> Int {
        tableViewLoaded = true
        return (fetchedResultsController.sections?.count ?? 0) + (isEditing ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if section < addSection {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if (indexPath as NSIndexPath).section < addSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EncounterCombatantCell", for: indexPath) as! EncounterCombatantCell
            let combatant = fetchedResultsController.object(at: indexPath)
            cell.combatant = combatant
            return cell
        } else {
            // Cell to add monsters.
            let cell = tableView.dequeueReusableCell(withIdentifier: "EncounterAddCombatantCell", for: indexPath) as! EncounterAddCombatantCell
            return cell
        }
    }

    // MARK: Edit support
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let combatant = fetchedResultsController.object(at: indexPath)
            managedObjectContext.delete(combatant)
        }
        
        encounter.lastModified = Date()
        try! managedObjectContext.save()
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if (indexPath as NSIndexPath).section < addSection {
            return isEditing ? nil : indexPath
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if (indexPath as NSIndexPath).section < addSection {
            return .delete
        } else {
            return .insert
        }
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
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? EncounterCombatantCell {
                let combatant = anObject as! Combatant
                cell.combatant = combatant
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}

// MARK: -

class EncounterCombatantCell : UITableViewCell {
    
    @IBOutlet var turnIndicator: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var healthProgress: UIProgressView!
    @IBOutlet var statLabel: UILabel!
    @IBOutlet var statCaptionLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var combatant: Combatant! {
        didSet {
            turnIndicator.isHidden = !combatant.isCurrentTurn

            var passivePerception: Int? = nil
            if let monster = combatant.monster {
                nameLabel.text = monster.name
                passivePerception = monster.passivePerception
            } else if let player = combatant.player {
                nameLabel.text = player.name
                passivePerception = player.passivePerception
            }
            
            switch combatant.role {
            case .foe, .friend:
                // Foe and Friend both show AC and health, since they are DM-controlled.
                healthProgress.isHidden = false
                healthProgress.progress = combatant.health

                statCaptionLabel.text = "AC"
                statLabel.text = "\(combatant.armorClass!)"
            case .player:
                // Player-controlled characters do not show health or AC, they show PP instead.
                healthProgress.isHidden = true
                
                statCaptionLabel.text = "PP"
                statLabel.text = "\(passivePerception!)"
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        selectionStyle = editing ? .none : .default
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        statCaptionLabel.transform = CGAffineTransform(rotationAngle: -CGFloat(π / 2.0))
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

class EncounterAddCombatantCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.textColor = tintColor
    }

}

//
//  EncounterCombatantsViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/2/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class EncounterCombatantsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var encounter: Encounter!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Leave the selected combatant always selected as we go in/out of the property views or table top.
        clearsSelectionOnViewWillAppear = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        let oldEditing = self.editing, tableViewLoaded = self.tableViewLoaded
        super.setEditing(editing, animated: animated)
        
        if editing != oldEditing && tableViewLoaded {
            let addSection = fetchedResultsController.sections?.count ?? 0
            if editing {
                tableView.insertSections(NSIndexSet(index: addSection), withRowAnimation: .Automatic)
            } else {
                tableView.deleteSections(NSIndexSet(index: addSection), withRowAnimation: .Automatic)
            }
        }
        
        if oldEditing && !editing {
            encounter.adventure.lastModified = NSDate()
            
            try! managedObjectContext.save()
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CombatantSegue" {
            performSegueWithIdentifier("CombatantMonsterSegue", sender: sender)
            if let indexPath = tableView.indexPathForSelectedRow {
                let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
                let viewController = segue.destinationViewController as! CombatantViewController
                viewController.combatant = combatant
            }
        } else if segue.identifier == "CombatantMonsterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
                let viewController = segue.destinationViewController as! MonsterViewController
                viewController.monster = combatant.monster
            }
        } else if segue.identifier == "AddCombatantSegue" {
            // This is pretty hacky, we're stealing one view and embedding in another just to work around restrictions. The fact this gets complicated, requiring intermediate classes, should show that I shouldn't do things this way and should come up with a better way. I just don't know what that is yet.
            let viewController = segue.destinationViewController as! EncounterAddCombatantViewController
            viewController.encounter = encounter
            
            viewController.completionBlock = { cancelled, monster, quantity in
                if let monster = monster where !cancelled {
                    for _ in 1...quantity {
                        let combatant = Combatant(encounter: self.encounter, monster: monster, inManagedObjectContext: managedObjectContext)
                        combatant.role = .Foe
                    }
                }
                
                self.dismissViewControllerAnimated(true, completion: nil)
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
            }

        }
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Combatant)
        fetchRequest.predicate = NSPredicate(format: "encounter == %@", self.encounter)
        
        let initiativeSortDescriptor = NSSortDescriptor(key: "rawInitiative", ascending: false)
        let initiativeOrderSortDescriptor = NSSortDescriptor(key: "rawInitiativeOrder", ascending: true)
        let monsterDexSortDescriptor = NSSortDescriptor(key: "monster.rawDexterityScore", ascending: false)
        let dateCreatedSortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: true)
        fetchRequest.sortDescriptors = [initiativeSortDescriptor, initiativeOrderSortDescriptor, monsterDexSortDescriptor, dateCreatedSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
    
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    // MARK: UITableViewDataSource

    var tableViewLoaded = false

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        tableViewLoaded = true
        return (fetchedResultsController.sections?.count ?? 0) + (editing ? 1 : 0)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if section < addSection {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            let cell = tableView.dequeueReusableCellWithIdentifier("EncounterCombatantCell", forIndexPath: indexPath) as! EncounterCombatantCell
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            cell.combatant = combatant
            return cell
        } else {
            // Cell to add monsters.
            let cell = tableView.dequeueReusableCellWithIdentifier("EncounterAddCombatantCell", forIndexPath: indexPath) as! EncounterAddCombatantCell
            return cell
        }
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            managedObjectContext.deleteObject(combatant)
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            return editing ? nil : indexPath
        } else {
            return indexPath
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            return .Delete
        } else {
            return .Insert
        }
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
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Bottom)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Bottom)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? EncounterCombatantCell {
                let combatant = anObject as! Combatant
                cell.combatant = combatant
            }
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? EncounterCombatantCell {
                let combatant = anObject as! Combatant
                cell.combatant = combatant
            }
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

}

class EncounterCombatantCell: UITableViewCell {
    
    @IBOutlet var turnIndicator: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var healthProgress: UIProgressView!
    @IBOutlet var statLabel: UILabel!
    @IBOutlet var statCaptionLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var combatant: Combatant! {
        didSet {
            turnIndicator.hidden = !combatant.isCurrentTurn

            var passivePerception: Int? = nil
            if let monster = combatant.monster {
                nameLabel.text = monster.name
                passivePerception = monster.passivePerception
            } else if let player = combatant.player {
                nameLabel.text = player.name
                passivePerception = player.passivePerception
            }
            
            switch combatant.role {
            case .Foe, .Friend:
                // Foe and Friend both show AC and health, since they are DM-controlled.
                healthProgress.hidden = false
                healthProgress.progress = combatant.health

                statCaptionLabel.text = "AC"
                statLabel.text = "\(combatant.armorClass!)"
            case .Player:
                // Player-controlled characters do not show health or AC, they show PP instead.
                healthProgress.hidden = true
                
                statCaptionLabel.text = "PP"
                statLabel.text = "\(passivePerception!)"
            }
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        selectionStyle = editing ? .None : .Default
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        statCaptionLabel.transform = CGAffineTransformMakeRotation(-CGFloat(π / 2.0))
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

class EncounterAddCombatantCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.textColor = tintColor
    }

}

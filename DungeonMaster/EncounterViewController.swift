//
//  EncounterViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/8/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import CoreData

class EncounterViewController: UITableViewController {
    
    /// The Encounter being used.
    var encounter: Encounter!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.collapsed
        super.viewWillAppear(animated)
        
        // FIXME This is the wrong place to do this, because it's triggered in several places, especially collapsed mode and portrait collapsed mode.
        performSegueWithIdentifier("TabletopSegue", sender: self)
        
        navigationController?.toolbarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.toolbarHidden = true
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        // We use a predicate on the Combatant table, matching against the encounter, rather than just using "encounter.combatants" so that we can be a delegate and get change notifications.
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entity(Model.Combatant, inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate(format: "encounter = %@", encounter)
        fetchRequest.predicate = predicate
        
        let initiativeSortDescriptor = NSSortDescriptor(key: "rawInitiative", ascending: false)
        let dexSortDescriptor = NSSortDescriptor(key: "monster.rawDexterityScore", ascending: false)
        fetchRequest.sortDescriptors = [initiativeSortDescriptor, dexSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            let error = error as NSError
            print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?

    // MARK: Navigation
    
    @IBAction func unwindFromMonster(segue: UIStoryboardSegue) {
        let controller = segue.sourceViewController as! DetailViewController
        let monster = controller.detailItem as! Monster
        
        let _ = Combatant(encounter: encounter, monster: monster, inManagedObjectContext: managedObjectContext)
        saveContext()
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TabletopSegue" {
            let tabletopViewController = (segue.destinationViewController as! UINavigationController).topViewController as! TabletopViewController
            tabletopViewController.encounter = encounter
            tabletopViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
            tabletopViewController.navigationItem.leftItemsSupplementBackButton = true
            
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        } else if segue.identifier == "CombatantSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant

                let combatantViewController = (segue.destinationViewController as! UINavigationController).topViewController as! CombatantViewController
                combatantViewController.combatant = combatant
                combatantViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                combatantViewController.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func initiativeTapped(sender: UIBarButtonItem) {
        PlaySound(.Initiative)
        
        var initiativeDice = [Monster: DiceCombo]()
        for case let combatant as Combatant in encounter.combatants {
            if let combo = initiativeDice[combatant.monster] {
                combatant.initiative = combo.value
            } else {
                let combo = combatant.monster.initiativeDice.reroll()
                initiativeDice[combatant.monster] = combo
                combatant.initiative = combo.value
            }
        }
        
        saveContext()
    }

}


// MARK: UITableViewDataSource
extension EncounterViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CombatantCell", forIndexPath: indexPath) as! CombatantCell
        let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
        cell.combatant = combatant
        return cell
    }
    
    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            managedObjectContext.deleteObject(combatant)
            saveContext()
        }
    }
    
}

// MARK: UITableViewDelegate
extension EncounterViewController {
}

// MARK: NSFetchedResultsControllerDelegate
extension EncounterViewController: NSFetchedResultsControllerDelegate {
    
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
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! CombatantCell
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath!) as! Combatant
            cell.combatant = combatant
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

// MARK: -

class CombatantCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var acLabel: UILabel!
    
    var combatant: Combatant! {
        didSet {
            nameLabel.text = combatant.monster.name
            progress.progress = combatant.health
            
            acLabel.text = "\(combatant.equippedArmor.armorClass)"
        }
    }

}

//
//  GameEncountersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/27/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class GameEncountersViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var game: Game!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        // Clear the cache of unused encounters.
        invalidateUnusedEncounters()

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
            game.adventure.lastModified = NSDate()
            
            try! managedObjectContext.save()
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EncounterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
                let viewController = segue.destinationViewController as! EncounterViewController
                viewController.encounter = encounter
                viewController.game = game
            }
        }
    }

    // MARK: Actions
    
    @IBAction func addButtonTapped(sender: UIButton) {
        let encounter = Encounter(adventure: game.adventure, inManagedObjectContext: managedObjectContext)
        let games = encounter.mutableSetValueForKey("games")
        games.addObject(game)
        
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("EncounterViewController") as! EncounterViewController
        viewController.encounter = encounter
        viewController.game = game
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Encounter)
        fetchRequest.predicate = NSPredicate(format: "ANY games == %@", self.game)
        
        let lastModifiedSortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [lastModifiedSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()
    
    /// The set of Encounters attached to the Adventure that have not yet been attached to a game.
    var unusedEncounters: [Encounter] {
        if let unusedEncounters = _unusedEncounters {
            return unusedEncounters
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Encounter)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@ AND games.@count == 0", game.adventure)
        // TODO also encounters from the previous game that haven't had XP allocated
    
        let lastModifiedSortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [lastModifiedSortDescriptor]
        
        _unusedEncounters = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Encounter]
        return _unusedEncounters!
    }
    var _unusedEncounters: [Encounter]?
    
    /// Invalidate the set of unused encounters.
    func invalidateUnusedEncounters() {
        _unusedEncounters = nil
    }

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
            return unusedEncounters.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GameEncounterCell", forIndexPath: indexPath) as! GameEncounterCell

        let addSection = fetchedResultsController.sections?.count ?? 0
        let encounter = (indexPath.section < addSection ? fetchedResultsController.objectAtIndexPath(indexPath) : unusedEncounters[indexPath.row]) as! Encounter
        
        cell.encounter = encounter
        
        return cell
    }
    
    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let encounters = game.mutableSetValueForKey("encounters")
        if editingStyle == .Delete {
            let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
            encounters.removeObject(encounter)
        } else if editingStyle == .Insert {
            let encounter = unusedEncounters[indexPath.row]
            encounters.addObject(encounter)
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            return .Delete
        } else {
            return .Insert
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    var oldUnusedEncounters: [Encounter]?
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // Clear or reset the cache of unused encounters, keeping the old cache around for insertion checking.
        oldUnusedEncounters = editing ? unusedEncounters : nil
        invalidateUnusedEncounters()

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
            let encounter = anObject as! Encounter
            if let oldIndex = oldUnusedEncounters?.indexOf(encounter) {
                let oldIndexPath = NSIndexPath(forRow: oldIndex, inSection: 1)
                tableView.deleteRowsAtIndexPaths([ oldIndexPath ], withRowAnimation: .Top)
            }

            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Bottom)
        case .Delete:
            let encounter = anObject as! Encounter
            if let newIndex = unusedEncounters.indexOf(encounter) {
                let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 1)
                tableView.insertRowsAtIndexPaths([ newIndexPath ], withRowAnimation: .Top)
            }
    
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Bottom)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? GameEncounterCell {
                let encounter = anObject as! Encounter
                cell.encounter = encounter
            }
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? GameEncounterCell {
                let encounter = anObject as! Encounter
                cell.encounter = encounter
            }
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

}

// MARK: -

class GameEncounterCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var encounter: Encounter! {
        didSet {
            label.text = encounter.title
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

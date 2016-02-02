//
//  AdventureEncountersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/27/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventureEncountersViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var adventure: Adventure!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EncounterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
                let viewController = segue.destinationViewController as! EncounterViewController
                viewController.encounter = encounter
            }
        }
    }
    
    // MARK: Actions

    @IBAction func addButtonTapped(sender: UIButton) {
        let encounter = Encounter(adventure: adventure, inManagedObjectContext: managedObjectContext)
        
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("EncounterViewController") as! EncounterViewController
        viewController.encounter = encounter
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Encounter)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@ AND games.@count == 0", adventure)
        
        let lastModifiedSortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [lastModifiedSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?

    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AdventureEncounterCell", forIndexPath: indexPath) as! AdventureEncounterCell
        let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
        cell.encounter = encounter
        return cell
    }
    
    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
            managedObjectContext.deleteObject(encounter)
            try! managedObjectContext.save()
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
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventureEncounterCell
            let encounter = anObject as! Encounter
            cell.encounter = encounter
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventureEncounterCell
            let encounter = anObject as! Encounter
            cell.encounter = encounter
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

// MARK: -

class AdventureEncounterCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!

    var encounter: Encounter! {
        didSet {
            label.text = encounter.title
            leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        if let leadingConstraint = leadingConstraint {
            leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
        }
        
        super.setEditing(editing, animated: animated)
    }
    
}

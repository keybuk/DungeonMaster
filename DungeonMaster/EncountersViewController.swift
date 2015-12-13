//
//  EncountersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/8/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import CoreData

class EncountersViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = true
        
        navigationItem.leftBarButtonItem = self.editButtonItem()
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
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entity(Model.Encounter, inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
        
        let sortDescriptor = NSSortDescriptor(key: "lastUsed", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EncounterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
                let encounterViewController = segue.destinationViewController as! EncounterViewController
                encounterViewController.encounter = encounter
            }
        } else if segue.identifier == "CreateEncounterSegue" {
            let encounter = Encounter(inManagedObjectContext: managedObjectContext)
            let encounterViewController = segue.destinationViewController as! EncounterViewController
            encounterViewController.encounter = encounter
        }
    }

}

// MARK: UITableViewDataSource
extension EncountersViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EncounterCell", forIndexPath: indexPath)
        let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
        cell.textLabel?.text = encounter.title
        return cell
    }

    // MARK: Edit support.
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let encounter = fetchedResultsController.objectAtIndexPath(indexPath) as! Encounter
            managedObjectContext.deleteObject(encounter)
        }
    }
    
}

// MARK: UITableViewDelegate
extension EncountersViewController {
}

// MARK: NSFetchedResultsControllerDelegate
extension EncountersViewController: NSFetchedResultsControllerDelegate {
    
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
            let cell = tableView.cellForRowAtIndexPath(indexPath!)
            let encounter = fetchedResultsController.objectAtIndexPath(indexPath!) as! Encounter
            cell?.textLabel?.text = encounter.title
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

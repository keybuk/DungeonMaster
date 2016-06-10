//
//  AdventureEncountersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/27/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventureEncountersViewController : UITableViewController {
    
    var adventure: Adventure!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EncounterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let encounter = fetchedResultsController.object(at: indexPath)
                let viewController = segue.destinationViewController as! EncounterViewController
                viewController.encounter = encounter
            }
        }
    }
    
    // MARK: Actions

    @IBAction func addButtonTapped(sender: UIButton) {
        let encounter = Encounter(adventure: adventure, inManagedObjectContext: managedObjectContext)
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()

        let viewController = storyboard?.instantiateViewControllerWithIdentifier("EncounterViewController") as! EncounterViewController
        viewController.encounter = encounter
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: FetchedResultsController<Int, Encounter> = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Encounter)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@ AND games.@count == 0", self.adventure)
        
        let lastModifiedSortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [lastModifiedSortDescriptor]
        
        let fetchedResultsController = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in return 0 }, sectionKeys: nil, handleChanges: self.handleFetchedResultsControllerChanges)
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()
    
    func handleFetchedResultsControllerChanges(changes: [FetchedResultsChange<Int, Encounter>]) {
        tableView.beginUpdates()
        for change in changes {
            switch change {
            case let .InsertSection(sectionInfo: _, newIndex: newIndex):
                tableView.insertSections(NSIndexSet(index: newIndex), withRowAnimation: .Automatic)
            case let .DeleteSection(sectionInfo: _, index: index):
                tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            case let .Insert(object: _, newIndexPath: newIndexPath):
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            case let .Delete(object: _, indexPath: indexPath):
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            case let .Move(object: _, indexPath: indexPath, newIndexPath: newIndexPath):
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            case let .Update(object: encounter, indexPath: indexPath):
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? AdventureEncounterCell {
                    cell.encounter = encounter
                }
            }
        }
        tableView.endUpdates()
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections[section].objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AdventureEncounterCell", forIndexPath: indexPath) as! AdventureEncounterCell
        let encounter = fetchedResultsController.object(at: indexPath)
        cell.encounter = encounter
        return cell
    }
    
    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let encounter = fetchedResultsController.object(at: indexPath)

        if editingStyle == .Delete {
            managedObjectContext.deleteObject(encounter)
        }
        
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()
    }

}

// MARK: -

class AdventureEncounterCell : UITableViewCell {
    
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

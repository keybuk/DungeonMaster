//
//  GameEncountersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/27/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class GameEncountersViewController : UITableViewController {
    
    var game: Game!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func setEditing(editing: Bool, animated: Bool) {
        assert(editing != self.editing, "setEditing called with same value")
        
        super.setEditing(editing, animated: animated)
        
        // Still have a "table view loaded" issue here with notifyChanges

        // TODO this is a dupe
        if editing {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "ANY games == %@ OR (adventure == %@ AND games.@count == 0)", self.game, self.game.adventure)
            // TODO also encounters from the previous game that haven't had XP allocated
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "ANY games == %@", self.game)
        }
        try! fetchedResultsController.performFetch(notifyChanges: true)
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EncounterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let encounter = fetchedResultsController.object(at: indexPath)
                let viewController = segue.destinationViewController as! EncounterViewController
                viewController.encounter = encounter
                viewController.game = game
            }
        }
    }

    // MARK: Actions
    
    @IBAction func addButtonTapped(sender: UIButton) {
        let encounter = Encounter(adventure: game.adventure, inManagedObjectContext: managedObjectContext)
        encounter.addGame(game)
        
        game.adventure.lastModified = NSDate()
        try! managedObjectContext.save()
        
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("EncounterViewController") as! EncounterViewController
        viewController.encounter = encounter
        viewController.game = game
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: FetchedResultsController<Int, Encounter> = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Encounter)
        
        if self.editing {
            fetchRequest.predicate = NSPredicate(format: "ANY games == %@ OR (adventure == %@ AND games.@count == 0)", self.game, self.game.adventure)
            // TODO also encounters from the previous game that haven't had XP allocated
        } else {
            fetchRequest.predicate = NSPredicate(format: "ANY games == %@", self.game)
        }
        
        let lastModifiedSortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [lastModifiedSortDescriptor]

        let fetchedResultsController = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.games.count > 0 ? 0 : 1 }, sectionKeys: ["games"], handleChanges: self.handleFetchedResultsControllerChanges)
        try! fetchedResultsController.performFetch()

        return fetchedResultsController
    }()
    
    // TODO this is basically boiler-plate, aside from the .Update case
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
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? GameEncounterCell {
                    cell.encounter = encounter
                }
            }
        }
        tableView.endUpdates()
    }
    
    // MARK: UITableViewDataSource
    
    // TODO boiler-plate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections.count
    }
    
    // TODO boiler-plate
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections[section].objects.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GameEncounterCell", forIndexPath: indexPath) as! GameEncounterCell
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
            encounter.removeGame(game)
        } else if editingStyle == .Insert {
            encounter.addGame(game)
        }
        
        game.adventure.lastModified = NSDate()
        try! managedObjectContext.save()
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        switch fetchedResultsController.sections[indexPath.section].name {
        case 0:
            return .Delete
        case 1:
            return .Insert
        default:
            fatalError()
        }
    }
    
}

// MARK: -

class GameEncounterCell : UITableViewCell {
    
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

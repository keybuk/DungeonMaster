//
//  AdventureGamesViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/16/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventureGamesViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var adventure: Adventure!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GameSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let game = fetchedResultsController.objectAtIndexPath(indexPath) as! Game
                let viewController = segue.destinationViewController as! GameViewController
                viewController.game = game
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func addButtonTapped(sender: UIButton) {
        let game = Game(adventure: adventure, inManagedObjectContext: managedObjectContext)
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()
        
        let viewController = storyboard?.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
        viewController.game = game
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Game)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@", self.adventure)
        
        let numberSortDescriptor = NSSortDescriptor(key: "rawNumber", ascending: false)
        fetchRequest.sortDescriptors = [numberSortDescriptor]
        
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
        let cell = tableView.dequeueReusableCellWithIdentifier("AdventureGameCell", forIndexPath: indexPath) as! AdventureGameCell
        let game = fetchedResultsController.objectAtIndexPath(indexPath) as! Game
        cell.game = game
        return cell
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let game = fetchedResultsController.objectAtIndexPath(indexPath) as! Game
            managedObjectContext.deleteObject(game)
            
            // Renumber the games above the deleted one to account for it having gone away
            for row in 0..<indexPath.row {
                let updateIndexPath = NSIndexPath(forRow: row, inSection: indexPath.section)
                let updateGame = fetchedResultsController.objectAtIndexPath(updateIndexPath) as! Game
                
                updateGame.number -= 1
            }
            
            adventure.lastModified = NSDate()
            try! managedObjectContext.save()
        }
    }
    
    // MARK: Move support
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    var userMovedTableRow: NSIndexPath?
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let sourceGame = fetchedResultsController.objectAtIndexPath(sourceIndexPath) as! Game
        let destinationGame = fetchedResultsController.objectAtIndexPath(destinationIndexPath) as! Game

        sourceGame.number = destinationGame.number

        // We have to move everything from the destination, up to but not including, the source. We can't use ..< because that won't go in either direction.
        var row = destinationIndexPath.row
        let step = destinationIndexPath.row > sourceIndexPath.row ? -1 : 1
        while row != sourceIndexPath.row {
            let indexPath = NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
            let game = fetchedResultsController.objectAtIndexPath(indexPath) as! Game

            // The table is sorted in reverse order, with the highest number first, so we actually move the game number in the opposite direction to the step through the rows.
            game.number -= step

            row += step
        }
        
        userMovedTableRow = sourceIndexPath
        
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()
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
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? AdventureGameCell {
                let game = anObject as! Game
                cell.game = game
            }
        case .Move:
            // FIXME this is wrong, we have to ignore all table changes... but haven't figured out how to deal with the inherent "Update" of the games list.
            if let userMovedTableRow = userMovedTableRow where userMovedTableRow == indexPath! {
                // Ignore row moved by the user, since the table already reflects the model.
                self.userMovedTableRow = nil
            } else {
                // .Move implies .Update; update the cell at the old index, and then move it.
                if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? AdventureGameCell {
                    let game = anObject as! Game
                    cell.game = game
                }
            
                tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

}

// MARK: -

class AdventureGameCell: UITableViewCell {
    
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var game: Game! {
        didSet {
            numberLabel.text = game.title
        
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .NoStyle
            
            dateLabel.text = dateFormatter.stringFromDate(game.date)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

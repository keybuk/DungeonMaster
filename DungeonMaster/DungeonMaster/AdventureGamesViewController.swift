//
//  AdventureGamesViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/16/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventureGamesViewController : UITableViewController {

    var adventure: Adventure!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GameSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let game = fetchedResultsController.object(at: indexPath)
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
    
    lazy var fetchedResultsController: FetchedResultsController<Int, Game> = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Game)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@", self.adventure)
        
        let numberSortDescriptor = NSSortDescriptor(key: "rawNumber", ascending: false)
        fetchRequest.sortDescriptors = [numberSortDescriptor]
        
        let fetchedResultsController = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in 0 }, sectionKeys: nil, handleChanges: self.handleFetchedResultsControllerChanges)        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    func handleFetchedResultsControllerChanges(changes: [FetchedResultsChange<Int, Game>]) {
        guard !changeIsUserDriven else {
            changeIsUserDriven = false
            return
        }

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
            case let .Update(object: game, indexPath: indexPath):
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? AdventureGameCell {
                    cell.game = game
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
        let cell = tableView.dequeueReusableCellWithIdentifier("AdventureGameCell", forIndexPath: indexPath) as! AdventureGameCell
        let game = fetchedResultsController.object(at: indexPath)
        cell.game = game
        return cell
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let game = fetchedResultsController.object(at: indexPath)

        if editingStyle == .Delete {
            managedObjectContext.deleteObject(game)
            
            // Renumber the games above the deleted one to account for it having gone away
            for row in 0..<indexPath.row {
                let updateIndexPath = NSIndexPath(forRow: row, inSection: indexPath.section)
                let updateGame = fetchedResultsController.object(at: updateIndexPath)
                
                updateGame.number -= 1
            }
        }
        
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()
    }
    
    // MARK: Move support
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    var changeIsUserDriven = false
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let sourceGame = fetchedResultsController.object(at: sourceIndexPath)
        let destinationGame = fetchedResultsController.object(at: destinationIndexPath)

        sourceGame.number = destinationGame.number

        // We have to move everything from the destination, up to but not including, the source. We can't use ..< because that won't go in either direction.
        var row = destinationIndexPath.row
        let step = destinationIndexPath.row > sourceIndexPath.row ? -1 : 1
        while row != sourceIndexPath.row {
            let indexPath = NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
            let game = fetchedResultsController.object(at: indexPath)

            // The table is sorted in reverse order, with the highest number first, so we actually move the game number in the opposite direction to the step through the rows.
            game.number -= step

            row += step
        }
        
        changeIsUserDriven = true
        
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()
    }

}

// MARK: -

class AdventureGameCell : UITableViewCell {
    
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

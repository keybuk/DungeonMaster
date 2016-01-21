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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Game)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@", adventure)
        
        let numberSortDescriptor = NSSortDescriptor(key: "rawNumber", ascending: false)
        fetchRequest.sortDescriptors = [numberSortDescriptor]
        
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
            try! managedObjectContext.save()
        }
    }

    // MARK: UITableViewDelegate
    
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
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventureGameCell
            let game = anObject as! Game
            cell.game = game
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventureGameCell
            let game = anObject as! Game
            cell.game = game
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
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
        try! managedObjectContext.save()

        let viewController = storyboard?.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
        viewController.game = game
        navigationController?.pushViewController(viewController, animated: true)
        
    }

}

// MARK: -

class AdventureGameCell: UITableViewCell {
    
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var game: Game! {
        didSet {
            let numberFormatter = RomanNumeralFormatter()
            let number = numberFormatter.stringFromNumber(game.number)!
            numberLabel.text = "\(game.adventure.name) \(number)"
        
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .NoStyle
            
            dateLabel.text = dateFormatter.stringFromDate(game.date)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        if let leadingConstraint = leadingConstraint {
            leadingConstraint.constant = editing ? 0.0 : 7.0
        }
        
        super.setEditing(editing, animated: animated)
    }

}

//
//  PlayersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class PlayersViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.collapsed
        super.viewWillAppear(animated)
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Player)
        
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
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

    var selectNextInsert = false
    var newIndexPathToSelect: NSIndexPath?
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowPlayerSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
                let playerViewController = (segue.destinationViewController as! UINavigationController).topViewController as! PlayerViewController
                playerViewController.player = player
                playerViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                playerViewController.navigationItem.leftItemsSupplementBackButton = true
            }
        } else if segue.identifier == "AddPlayerSegue" {
            let playerViewController = (segue.destinationViewController as! UINavigationController).topViewController as! PlayerViewController

            selectNextInsert = true
            playerViewController.player = Player(inManagedObjectContext: managedObjectContext)
            playerViewController.newPlayer = true

            playerViewController.setEditing(true, animated: true)
        }
    }

}

// MARK: UITableViewDataSource
extension PlayersViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlayerCell", forIndexPath: indexPath) as! PlayerCell
        let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
        
        cell.player = player
        return cell
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
            managedObjectContext.deleteObject(player)
            saveContext()
        }
    }
}

// MARK: UITableViewDelegate
extension PlayersViewController {
    
}

// MARK: NSFetchedResultsControllerDelegate
extension PlayersViewController: NSFetchedResultsControllerDelegate {
    
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
            if selectNextInsert {
                newIndexPathToSelect = newIndexPath
                selectNextInsert = false
            }
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! PlayerCell
            let player = fetchedResultsController.objectAtIndexPath(indexPath!) as! Player
            cell.player = player
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        if let indexPath = newIndexPathToSelect {
            tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            newIndexPathToSelect = nil
        }
    }
    
}

// MARK: -

class PlayerCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var raceLabel: UILabel!
    @IBOutlet var classLabel: UILabel!
    @IBOutlet var backgroundLabel: UILabel!
    @IBOutlet var xpLabel: UILabel!
    
    var player: Player! {
        didSet {
            nameLabel.text = player.name
            if player.primitiveValueForKey("rawRace") != nil {
                raceLabel.text = player.race.stringValue
            } else {
                raceLabel.text = nil
            }
            if player.primitiveValueForKey("rawCharacterClass") != nil {
                classLabel.text = "\(player.characterClass.stringValue) \(player.level)"
            } else {
                classLabel.text = nil
            }
            if player.primitiveValueForKey("rawBackground") != nil {
                backgroundLabel.text = player.background.stringValue
            } else {
                backgroundLabel.text = nil
            }
            
            let xpFormatter = NSNumberFormatter()
            xpFormatter.numberStyle = .DecimalStyle
            
            let xpString = xpFormatter.stringFromNumber(player.XP)!
            xpLabel.text = "\(xpString) XP"
        }
    }
    
}

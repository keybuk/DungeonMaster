//
//  AdventurePlayersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventurePlayersViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var adventure: Adventure!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        // Clear the cache of missing players.
        invalidateMissingPlayers()

        super.setEditing(editing, animated: animated)

        let addSection = fetchedResultsController.sections?.count ?? 0
        if editing {
            tableView.insertSections(NSIndexSet(index: addSection), withRowAnimation: .Automatic)
        } else {
            tableView.deleteSections(NSIndexSet(index: addSection), withRowAnimation: .Automatic)
            try! managedObjectContext.save()
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlayerSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
                
                let viewController = segue.destinationViewController as! PlayerViewController
                viewController.player = player
            }
            
        } else if segue.identifier == "AddPlayerSegue" {
            let player = Player(inManagedObjectContext: managedObjectContext)
            
            let viewController = (segue.destinationViewController as! UINavigationController).topViewController as! PlayerViewController
            viewController.player = player
            
            viewController.completionBlock = { cancelled, player in
                if let player = player where !cancelled {
                    let players = self.adventure.mutableSetValueForKey("players")
                    players.addObject(player)
                }

                self.dismissViewControllerAnimated(true, completion: nil)
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
            }
        }
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Player)
        fetchRequest.predicate = NSPredicate(format: "ANY adventures == %@", adventure)
        
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
    
    /// The set of Players that are not participating in this adventure.
    ///
    /// This is generated by using the standard results controller, and has to be invalidated using `invalidateMissingPlayers` whenever that changes.
    var missingPlayers: [Player] {
        if let missingPlayers = _missingPlayers {
            return missingPlayers
        }

        // Ideally we'd use something like "NONE adventures == %@" here, but that doesn't work.
        let fetchRequest = NSFetchRequest(entity: Model.Player)
        fetchRequest.predicate = NSPredicate(format: "NOT SELF IN %@", fetchedResultsController.fetchedObjects!)
        
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]

        _missingPlayers = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Player]
        return _missingPlayers!
    }
    var _missingPlayers: [Player]?
    
    /// Invalidate the set of missing players.
    func invalidateMissingPlayers() {
        _missingPlayers = nil
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (fetchedResultsController.sections?.count ?? 0) + (editing ? 1 : 0)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if section < addSection {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        } else {
            return missingPlayers.count + 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            // Player in the adventure.
            let cell = tableView.dequeueReusableCellWithIdentifier("AdventurePlayerCell", forIndexPath: indexPath) as! AdventurePlayerCell
            let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
            cell.player = player
            return cell
        } else if indexPath.row < missingPlayers.count {
            // Player not yet in the adventure.
            let cell = tableView.dequeueReusableCellWithIdentifier("AdventurePlayerCell", forIndexPath: indexPath) as! AdventurePlayerCell
            let player = missingPlayers[indexPath.row]
            cell.player = player
            return cell
        } else {
            // Cell to create a new player.
            let cell = tableView.dequeueReusableCellWithIdentifier("AdventureAddPlayerCell", forIndexPath: indexPath)
            return cell
        }
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let players = adventure.mutableSetValueForKey("players")

        if editingStyle == .Delete {
            let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
            players.removeObject(player)

        } else if editingStyle == .Insert {
            if indexPath.row < missingPlayers.count {
                let player = missingPlayers[indexPath.row]
                players.addObject(player)
            } else {
                performSegueWithIdentifier("AddPlayerSegue", sender: self)
            }
        }
    }

    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            return editing ? nil : indexPath
        } else if indexPath.row < missingPlayers.count {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            return .Delete
        } else if indexPath.row < missingPlayers.count {
            return .Insert
        } else {
            return .Insert
        }
    }

    // MARK: NSFetchedResultsControllerDelegate
    
    var oldMissingPlayers: [Player]?

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // Clear or reset the cache of missing players, keeping the old cache around for insertion checking.
        oldMissingPlayers = editing ? missingPlayers : nil
        invalidateMissingPlayers()

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
            let player = anObject as! Player
            if let oldIndex = oldMissingPlayers?.indexOf(player) {
                let oldIndexPath = NSIndexPath(forRow: oldIndex, inSection: 1)
                tableView.deleteRowsAtIndexPaths([ oldIndexPath ], withRowAnimation: .Bottom)
            }

            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Bottom)
        case .Delete:
            let player = anObject as! Player
            if let newIndex = missingPlayers.indexOf(player) {
                let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 1)
                tableView.insertRowsAtIndexPaths([ newIndexPath ], withRowAnimation: .Bottom)
            }

            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Bottom)
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventurePlayerCell
            let player = anObject as! Player
            cell.player = player
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventurePlayerCell
            let player = anObject as! Player
            cell.player = player
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

// MARK: -

class AdventurePlayerCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var raceLabel: UILabel!
    @IBOutlet var classLabel: UILabel!
    @IBOutlet var backgroundLabel: UILabel!
    @IBOutlet var xpLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var player: Player! {
        didSet {
            nameLabel.text = player.name
            raceLabel.text = player.race.stringValue
            classLabel.text = "\(player.characterClass.stringValue) \(player.level)"
            backgroundLabel.text = player.background.stringValue
            
            let xpFormatter = NSNumberFormatter()
            xpFormatter.numberStyle = .DecimalStyle
            
            let xpString = xpFormatter.stringFromNumber(player.XP)!
            xpLabel.text = "\(xpString) XP"
            
            leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        if let leadingConstraint = leadingConstraint {
            leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
        }
        
        super.setEditing(editing, animated: animated)

        selectionStyle = editing ? .None : .Default
    }
    
}

class AdventureAddPlayerCell: UITableViewCell {

    @IBOutlet var label: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        label.textColor = tintColor
    }

}
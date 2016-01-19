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
        super.setEditing(editing, animated: animated)
        
        if let tableView = tableView {
            let addSection = fetchedResultsController.sections?.count ?? 0
            if editing {
                tableView.insertSections(NSIndexSet(index: addSection), withRowAnimation: .Automatic)
            } else {
                tableView.deleteSections(NSIndexSet(index: addSection), withRowAnimation: .Automatic)
            }
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
        fetchRequest.predicate = NSPredicate(format: "%@ IN adventures", adventure)
        
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?

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
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            let cell = tableView.dequeueReusableCellWithIdentifier("AdventurePlayerCell", forIndexPath: indexPath) as! AdventurePlayerCell
            let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
            cell.player = player
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("AdventureAddPlayerCell", forIndexPath: indexPath)
            return cell
        }
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // FIXME this is wrong
            let player = fetchedResultsController.objectAtIndexPath(indexPath) as! Player
            managedObjectContext.deleteObject(player)
            try! managedObjectContext.save()
        } else if editingStyle == .Insert {
            // FIXME
        }
    }

    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection && editing {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            return .Delete
        } else {
            return .Insert
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
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventurePlayerCell
            let player = fetchedResultsController.objectAtIndexPath(indexPath!) as! Player
            cell.player = player
        case .Move:
            // .Move implies .Update; update the cell at the old index with the result at the new index, and then move it.
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AdventurePlayerCell
            let player = fetchedResultsController.objectAtIndexPath(newIndexPath!) as! Player
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
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        if let leadingConstraint = leadingConstraint {
            leadingConstraint.constant = editing ? 0.0 : 7.0
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
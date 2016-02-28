//
//  LogEntryPlayersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class LogEntryPlayersViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var logEntryType: LogEntry.Type!
    var game: Game!
    var encounter: Encounter?
    var combatants: Set<Combatant>?
    
    var playedGames: Set<PlayedGame> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playedGames.unionInPlace(fetchedResultsController.fetchedObjects! as! [PlayedGame])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Actions
    
    @IBAction func nextButtonTapped(sender: UIBarButtonItem) {
        switch logEntryType {
        case is XPAward.Type:
            performSegueWithIdentifier("XPAwardSegue", sender: sender)
        case is LogEntryNote.Type:
            performSegueWithIdentifier("NoteSegue", sender: sender)
        default:
            fatalError("Unknown Log Entry type")
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "NoteSegue" {
            let viewController = segue.destinationViewController as! LogEntryNoteViewController
            viewController.playedGames = playedGames
        } else if segue.identifier == "XPAwardSegue" {
            let viewController = segue.destinationViewController as! LogEntryXPAwardViewController
            viewController.playedGames = playedGames
            viewController.encounter = encounter
            viewController.combatants = combatants
        }
    }
    
    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.PlayedGame)
        let gamePredicate = NSPredicate(format: "game == %@", self.game)
        if let encounter = self.encounter {
            let encounterPredicate = NSPredicate(format: "ANY player.combatants.encounter == %@", encounter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [ gamePredicate, encounterPredicate ])
        } else {
            fetchRequest.predicate = gamePredicate
        }
        
        let nameSortDescriptor = NSSortDescriptor(key: "player.name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
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
        let cell = tableView.dequeueReusableCellWithIdentifier("LogEntryPlayerCell", forIndexPath: indexPath) as! LogEntryPlayerCell
        let playedGame = fetchedResultsController.objectAtIndexPath(indexPath) as! PlayedGame
        cell.player = playedGame.player
        cell.accessoryType = playedGames.contains(playedGame) ? .Checkmark : .None
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playedGame = fetchedResultsController.objectAtIndexPath(indexPath) as! PlayedGame
        if playedGames.contains(playedGame) {
            playedGames.remove(playedGame)
        } else {
            playedGames.insert(playedGame)
        }
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? LogEntryPlayerCell {
            cell.accessoryType = playedGames.contains(playedGame) ? .Checkmark : .None
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
            let playedGame = anObject as! PlayedGame
            playedGames.insert(playedGame)
            
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Bottom)
        case .Delete:
            let playedGame = anObject as! PlayedGame
            playedGames.remove(playedGame)

            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Bottom)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LogEntryPlayerCell {
                let playedGame = anObject as! PlayedGame
                cell.player = playedGame.player
                cell.accessoryType = playedGames.contains(playedGame) ? .Checkmark : .None
            }
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LogEntryPlayerCell {
                let playedGame = anObject as! PlayedGame
                cell.player = playedGame.player
                cell.accessoryType = playedGames.contains(playedGame) ? .Checkmark : .None
            }
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

}

class LogEntryPlayerCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var player: Player! {
        didSet {
            nameLabel.text = player.name
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }
    
}

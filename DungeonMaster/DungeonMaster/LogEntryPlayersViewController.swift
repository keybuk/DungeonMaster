//
//  LogEntryPlayersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class LogEntryPlayersViewController : UITableViewController, NSFetchedResultsControllerDelegate {
    
    var logEntryType: LogEntry.Type!
    var game: Game!
    var encounter: Encounter?
    var combatants: Set<Combatant>?
    
    var playedGames: Set<PlayedGame> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playedGames.formUnion(fetchedResultsController.fetchedObjects!)
    }

    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NoteSegue" {
            let viewController = segue.destination as! LogEntryNoteViewController
            viewController.playedGames = playedGames
        } else if segue.identifier == "XPAwardSegue" {
            let viewController = segue.destination as! LogEntryXPAwardViewController
            viewController.playedGames = playedGames
            viewController.encounter = encounter
            viewController.combatants = combatants
        }
    }
    
    // MARK: Actions
    
    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
        switch logEntryType {
        case is XPAward.Type:
            performSegue(withIdentifier: "XPAwardSegue", sender: sender)
        case is LogEntryNote.Type:
            performSegue(withIdentifier: "NoteSegue", sender: sender)
        default:
            fatalError("Unknown Log Entry type")
        }
    }
    
    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController<PlayedGame> = { [unowned self] in
        let fetchRequest = NSFetchRequest<PlayedGame>()
        fetchRequest.entity = NSEntityDescription.entity(forModel: Model.PlayedGame, in: managedObjectContext)
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogEntryPlayerCell", for: indexPath) as! LogEntryPlayerCell
        let playedGame = fetchedResultsController.object(at: indexPath)
        cell.player = playedGame.player
        cell.accessoryType = playedGames.contains(playedGame) ? .checkmark : .none
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playedGame = fetchedResultsController.object(at: indexPath)
        if playedGames.contains(playedGame) {
            playedGames.remove(playedGame)
        } else {
            playedGames.insert(playedGame)
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? LogEntryPlayerCell {
            cell.accessoryType = playedGames.contains(playedGame) ? .checkmark : .none
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            let playedGame = anObject as! PlayedGame
            playedGames.insert(playedGame)
            
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            let playedGame = anObject as! PlayedGame
            playedGames.remove(playedGame)

            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? LogEntryPlayerCell {
                let playedGame = anObject as! PlayedGame
                cell.player = playedGame.player
                cell.accessoryType = playedGames.contains(playedGame) ? .checkmark : .none
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}

// MARK: -

class LogEntryPlayerCell : UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var player: Player! {
        didSet {
            nameLabel.text = player.name
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }
    
}

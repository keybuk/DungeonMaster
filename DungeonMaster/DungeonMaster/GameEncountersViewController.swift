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

    override func setEditing(_ editing: Bool, animated: Bool) {
        assert(editing != self.isEditing, "setEditing called with same value")
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EncounterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let encounter = fetchedResultsController.object(at: indexPath)
                let viewController = segue.destination as! EncounterViewController
                viewController.encounter = encounter
                viewController.game = game
            }
        }
    }

    // MARK: Actions
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let encounter = Encounter(adventure: game.adventure, insertInto: managedObjectContext)
        encounter.addGame(game)
        
        game.adventure.lastModified = Date()
        try! managedObjectContext.save()
        
        let viewController = storyboard?.instantiateViewController(withIdentifier: "EncounterViewController") as! EncounterViewController
        viewController.encounter = encounter
        viewController.game = game
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: FetchedResultsController<Int, Encounter> = { [unowned self] in
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: Model.Encounter)
        
        if self.isEditing {
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
    
    func handleFetchedResultsControllerChanges(_ changes: [FetchedResultsChange<Int, Encounter>]) {
        tableView.beginUpdates()
        for change in changes {
            switch change {
            case let .insertSection(sectionInfo: _, newIndex: newIndex):
                tableView.insertSections(IndexSet(integer: newIndex), with: .automatic)
            case let .deleteSection(sectionInfo: _, index: index):
                tableView.deleteSections(IndexSet(integer: index), with: .automatic)
            case let .insert(object: _, newIndexPath: newIndexPath):
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            case let .delete(object: _, indexPath: indexPath):
                tableView.deleteRows(at: [indexPath], with: .automatic)
            case let .move(object: _, indexPath: indexPath, newIndexPath: newIndexPath):
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            case let .update(object: encounter, indexPath: indexPath):
                if let cell = tableView.cellForRow(at: indexPath) as? GameEncounterCell {
                    cell.encounter = encounter
                }
            }
        }
        tableView.endUpdates()
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections[section].objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameEncounterCell", for: indexPath) as! GameEncounterCell
        let encounter = fetchedResultsController.object(at: indexPath)
        cell.encounter = encounter
        return cell
    }
    
    // MARK: Edit support
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let encounter = fetchedResultsController.object(at: indexPath)

        if editingStyle == .delete {
            encounter.removeGame(game)
        } else if editingStyle == .insert {
            encounter.addGame(game)
        }
        
        game.adventure.lastModified = Date()
        try! managedObjectContext.save()
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        switch fetchedResultsController.sections[(indexPath as NSIndexPath).section].name {
        case 0:
            return .delete
        case 1:
            return .insert
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
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

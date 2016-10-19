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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GameSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let game = fetchedResultsController.object(at: indexPath)
                let viewController = segue.destination as! GameViewController
                viewController.game = game
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let game = Game(adventure: adventure, inManagedObjectContext: managedObjectContext)
        adventure.lastModified = Date()
        try! managedObjectContext.save()
        
        let viewController = storyboard?.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        viewController.game = game
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: FetchedResultsController<Int, Game> = { [unowned self] in
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: Model.Game)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@", self.adventure)
        
        let numberSortDescriptor = NSSortDescriptor(key: "rawNumber", ascending: false)
        fetchRequest.sortDescriptors = [numberSortDescriptor]
        
        let fetchedResultsController = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in 0 }, sectionKeys: nil, handleChanges: self.handleFetchedResultsControllerChanges)        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    func handleFetchedResultsControllerChanges(_ changes: [FetchedResultsChange<Int, Game>]) {
        guard !changeIsUserDriven else {
            changeIsUserDriven = false
            return
        }

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
            case let .update(object: game, indexPath: indexPath):
                if let cell = tableView.cellForRow(at: indexPath) as? AdventureGameCell {
                    cell.game = game
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "AdventureGameCell", for: indexPath) as! AdventureGameCell
        let game = fetchedResultsController.object(at: indexPath)
        cell.game = game
        return cell
    }

    // MARK: Edit support
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let game = fetchedResultsController.object(at: indexPath)

        if editingStyle == .delete {
            managedObjectContext.delete(game)
            
            // Renumber the games above the deleted one to account for it having gone away
            for row in 0..<(indexPath as NSIndexPath).row {
                let updateIndexPath = IndexPath(row: row, section: (indexPath as NSIndexPath).section)
                let updateGame = fetchedResultsController.object(at: updateIndexPath)
                
                updateGame.number -= 1
            }
        }
        
        adventure.lastModified = Date()
        try! managedObjectContext.save()
    }
    
    // MARK: Move support
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    var changeIsUserDriven = false
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceGame = fetchedResultsController.object(at: sourceIndexPath)
        let destinationGame = fetchedResultsController.object(at: destinationIndexPath)

        sourceGame.number = destinationGame.number

        // We have to move everything from the destination, up to but not including, the source. We can't use ..< because that won't go in either direction.
        var row = (destinationIndexPath as NSIndexPath).row
        let step = (destinationIndexPath as NSIndexPath).row > (sourceIndexPath as NSIndexPath).row ? -1 : 1
        while row != (sourceIndexPath as NSIndexPath).row {
            let indexPath = IndexPath(row: row, section: (sourceIndexPath as NSIndexPath).section)
            let game = fetchedResultsController.object(at: indexPath)

            // The table is sorted in reverse order, with the highest number first, so we actually move the game number in the opposite direction to the step through the rows.
            game.number -= step

            row += step
        }
        
        changeIsUserDriven = true
        
        adventure.lastModified = Date()
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
        
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            
            dateLabel.text = dateFormatter.string(from: game.date as Date)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

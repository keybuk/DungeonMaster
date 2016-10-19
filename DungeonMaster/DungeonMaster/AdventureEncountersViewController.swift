//
//  AdventureEncountersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/27/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventureEncountersViewController : UITableViewController {
    
    var adventure: Adventure!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EncounterSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let encounter = fetchedResultsController.object(at: indexPath)
                let viewController = segue.destination as! EncounterViewController
                viewController.encounter = encounter
            }
        }
    }
    
    // MARK: Actions

    @IBAction func addButtonTapped(_ sender: UIButton) {
        let encounter = Encounter(adventure: adventure, insertInto: managedObjectContext)
        adventure.lastModified = Date()
        try! managedObjectContext.save()

        let viewController = storyboard?.instantiateViewController(withIdentifier: "EncounterViewController") as! EncounterViewController
        viewController.encounter = encounter
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: FetchedResultsController<Int, Encounter> = { [unowned self] in
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: Model.Encounter)
        fetchRequest.predicate = NSPredicate(format: "adventure == %@ AND games.@count == 0", self.adventure)
        
        let lastModifiedSortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [lastModifiedSortDescriptor]
        
        let fetchedResultsController = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in return 0 }, sectionKeys: nil, handleChanges: self.handleFetchedResultsControllerChanges)
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
                if let cell = tableView.cellForRow(at: indexPath) as? AdventureEncounterCell {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "AdventureEncounterCell", for: indexPath) as! AdventureEncounterCell
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
            managedObjectContext.delete(encounter)
        }
        
        adventure.lastModified = Date()
        try! managedObjectContext.save()
    }

}

// MARK: -

class AdventureEncounterCell : UITableViewCell {
    
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

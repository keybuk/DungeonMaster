//
//  AdventurePlayersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventurePlayersViewController : UITableViewController, NSFetchedResultsControllerDelegate {
    
    var adventure: Adventure!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        // Clear the cache of missing players.
        missingPlayers = nil

        let oldEditing = self.isEditing
        super.setEditing(editing, animated: animated)

        if editing != oldEditing {
            let addSection = fetchedResultsController.sections?.count ?? 0
            if editing {
                tableView.insertSections(IndexSet(integer: addSection), with: .automatic)
            } else {
                tableView.deleteSections(IndexSet(integer: addSection), with: .automatic)
            }
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlayerSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let player = fetchedResultsController.object(at: indexPath) 
                
                let viewController = segue.destination as! PlayerRootViewController
                viewController.player = player
            }
            
        } else if segue.identifier == "AddPlayerSegue" {
            let player = Player(insertInto: managedObjectContext)
            
            let viewController = (segue.destination as! UINavigationController).topViewController as! PlayerViewController
            viewController.player = player
            
            viewController.completionBlock = { cancelled, player in
                if let player = player, !cancelled {
                    self.adventure.addPlayer(player)

                    self.adventure.lastModified = Date()
                    try! managedObjectContext.save()
                }

                self.dismiss(animated: true, completion: nil)
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
    }
    
    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController<Player> = { [unowned self] in
        let fetchRequest = NSFetchRequest<Player>()
        fetchRequest.entity = NSEntityDescription.entity(forModel: Model.Player, in: managedObjectContext)
        fetchRequest.predicate = NSPredicate(format: "ANY adventures == %@", self.adventure)
        
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()
    
    /// The set of Players that are not participating in this adventure.
    ///
    /// This is generated by using the standard results controller, and has to be reset whenever that changes.
    var missingPlayers: [Player]! {
        get {
            if let missingPlayers = _missingPlayers {
                return missingPlayers
            }

            // Ideally we'd use something like "NONE adventures == %@" here, but that doesn't work.
            let fetchRequest = NSFetchRequest<Player>()
            fetchRequest.entity = NSEntityDescription.entity(forModel: Model.Player, in: managedObjectContext)
            fetchRequest.predicate = NSPredicate(format: "NOT SELF IN %@", fetchedResultsController.fetchedObjects!)
            
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [nameSortDescriptor]

            _missingPlayers = try! managedObjectContext.fetch(fetchRequest)
            return _missingPlayers!
        }
        
        set(newMissingPlayers) {
            _missingPlayers = newMissingPlayers
        }
    }
    fileprivate var _missingPlayers: [Player]?
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (fetchedResultsController.sections?.count ?? 0) + (isEditing ? 1 : 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if section < addSection {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        } else {
            return missingPlayers.count + 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if (indexPath as NSIndexPath).section < addSection {
            // Player in the adventure.
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdventurePlayerCell", for: indexPath) as! AdventurePlayerCell
            let player = fetchedResultsController.object(at: indexPath) 
            cell.player = player
            return cell
        } else if (indexPath as NSIndexPath).row < missingPlayers.count {
            // Player not yet in the adventure.
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdventurePlayerCell", for: indexPath) as! AdventurePlayerCell
            let player = missingPlayers[(indexPath as NSIndexPath).row]
            cell.player = player
            return cell
        } else {
            // Cell to create a new player.
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdventureAddPlayerCell", for: indexPath)
            return cell
        }
    }

    // MARK: Edit support
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let player = fetchedResultsController.object(at: indexPath) 
            adventure.removePlayer(player)
            
            adventure.lastModified = Date()
            try! managedObjectContext.save()

        } else if editingStyle == .insert {
            if (indexPath as NSIndexPath).row < missingPlayers.count {
                let player = missingPlayers[(indexPath as NSIndexPath).row]
                adventure.addPlayer(player)
                
                adventure.lastModified = Date()
                try! managedObjectContext.save()
            } else {
                performSegue(withIdentifier: "AddPlayerSegue", sender: self)
            }
        }
    }

    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if (indexPath as NSIndexPath).section < addSection {
            return isEditing ? nil : indexPath
        } else if (indexPath as NSIndexPath).row < missingPlayers.count {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if (indexPath as NSIndexPath).section < addSection {
            return .delete
        } else if (indexPath as NSIndexPath).row < missingPlayers.count {
            return .insert
        } else {
            return .insert
        }
    }

    // MARK: NSFetchedResultsControllerDelegate
    
    var oldMissingPlayers: [Player]?

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Clear or reset the cache of missing players, keeping the old cache around for insertion checking.
        oldMissingPlayers = isEditing ? missingPlayers : nil
        missingPlayers = nil

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
            let player = anObject as! Player
            if let oldIndex = oldMissingPlayers?.index(of: player) {
                let oldIndexPath = IndexPath(row: oldIndex, section: 1)
                tableView.deleteRows(at: [ oldIndexPath ], with: .top)
            }

            tableView.insertRows(at: [newIndexPath!], with: .bottom)
        case .delete:
            let player = anObject as! Player
            if let newIndex = missingPlayers.index(of: player) {
                let newIndexPath = IndexPath(row: newIndex, section: 1)
                tableView.insertRows(at: [ newIndexPath ], with: .top)
            }

            tableView.deleteRows(at: [indexPath!], with: .bottom)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? AdventurePlayerCell {
                let player = anObject as! Player
                cell.player = player
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}

// MARK: -

class AdventurePlayerCell : UITableViewCell {
    
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
            xpLabel.text = player.xpString
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        selectionStyle = editing ? .none : .default
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

class AdventureAddPlayerCell : UITableViewCell {

    @IBOutlet var label: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        label.textColor = tintColor
    }

}

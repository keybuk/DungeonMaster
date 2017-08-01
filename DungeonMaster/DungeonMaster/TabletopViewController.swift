//
//  TabletopViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/8/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class TabletopViewController : UIViewController, TabletopViewDataSource, TabletopViewDelegate, NSFetchedResultsControllerDelegate {

    var tabletopView: TabletopView!
    
    var encounter: Encounter!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tabletopView = view as! TabletopView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = encounter.title
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController<Combatant> = { [unowned self] in
        // We use a predicate on the Combatant table, matching against the encounter, rather than just using "encounter.combatants" so that we can be a delegate and get change notifications.
        let fetchRequest = NSFetchRequest<Combatant>()
        fetchRequest.entity = NSEntityDescription.entity(forModel: Model.Combatant, in: managedObjectContext)
        
        let predicate = NSPredicate(format: "encounter == %@", self.encounter)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()

        return fetchedResultsController
    }()

    // MARK: TabletopViewDataSource
    
    func numberOfItemsInTabletopView(_ tabletopView: TabletopView) -> Int {
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func tabletopView(_ tabletopView: TabletopView, locationForItem index: Int) -> TabletopLocation {
        let combatant = fetchedResultsController.fetchedObjects![index]
        if let location = combatant.location {
            return location
        } else {
            combatant.location = tabletopView.emptyLocationForNewItem()!
            return combatant.location!
        }
    }
    
    func tabletopView(_ tabletopView: TabletopView, nameForItem index: Int) -> String {
        let combatant = fetchedResultsController.fetchedObjects![index]
        return (combatant.monster?.name ?? combatant.player?.name)!
    }
    
    func tabletopView(_ tabletopView: TabletopView, isItemPlayerControlled index: Int) -> Bool {
        let combatant = fetchedResultsController.fetchedObjects![index]
        return combatant.role == .player
    }
    
    func tabletopView(_ tabletopView: TabletopView, healthForItem index: Int) -> Float {
        let combatant = fetchedResultsController.fetchedObjects![index]
        return combatant.health
    }

    // MARK: TabletopViewDelegate
    
    func tabletopView(_ tabletopView: TabletopView, moveItem index: Int, to location: TabletopLocation) {
        let combatant = fetchedResultsController.fetchedObjects![index]
        combatant.location = location
        
        encounter.lastModified = Date()
        try! managedObjectContext.save()
    }
    
    func tabletopView(_ tabletopView: TabletopView, didSelectItem index: Int) {
        let combatant = fetchedResultsController.fetchedObjects![index]

        // This is kind of a hack, but it does what I want for now.
        navigationController?.popViewController(animated: true)
        if let encounterViewController = navigationController?.topViewController as? EncounterViewController {
            let combatantsViewController: EncounterCombatantsViewController! = encounterViewController.combatantsViewController
            let indexPath = combatantsViewController.fetchedResultsController.indexPath(forObject: combatant)
            combatantsViewController.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            combatantsViewController?.performSegue(withIdentifier: "CombatantSegue", sender: self)
        }
    }

    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tabletopView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tabletopView.insertItemAtIndex((newIndexPath! as NSIndexPath).row)
        case .delete:
            tabletopView.deleteItemAtIndex((indexPath! as NSIndexPath).row)
        case .update:
            tabletopView.updateItemAtIndex((indexPath! as NSIndexPath).row)
        case .move:
            tabletopView.deleteItemAtIndex((indexPath! as NSIndexPath).row)
            tabletopView.insertItemAtIndex((newIndexPath! as NSIndexPath).row)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tabletopView.endUpdates()
    }
    
}

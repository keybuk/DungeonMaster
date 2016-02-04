//
//  TabletopViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/8/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class TabletopViewController: UIViewController, TabletopViewDataSource, TabletopViewDelegate, NSFetchedResultsControllerDelegate {

    var tabletopView: TabletopView!
    
    var encounter: Encounter!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tabletopView = view as! TabletopView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = encounter.title
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        }
        
        // We use a predicate on the Combatant table, matching against the encounter, rather than just using "encounter.combatants" so that we can be a delegate and get change notifications.
        let fetchRequest = NSFetchRequest(entity: Model.Combatant)
        
        let predicate = NSPredicate(format: "encounter == %@", encounter)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?

    // MARK: TabletopViewDataSource
    
    func numberOfItemsInTabletopView(tabletopView: TabletopView) -> Int {
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func tabletopView(tabletopView: TabletopView, locationForItem index: Int) -> TabletopLocation {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        if let location = combatant.location {
            return location
        } else {
            combatant.location = tabletopView.emptyLocationForNewItem()!
            return combatant.location!
        }
    }
    
    func tabletopView(tabletopView: TabletopView, nameForItem index: Int) -> String {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        return combatant.monster != nil ? combatant.monster!.name : combatant.player!.name
    }
    
    func tabletopView(tabletopView: TabletopView, isItemPlayerControlled index: Int) -> Bool {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        return combatant.role == .Player
    }
    
    func tabletopView(tabletopView: TabletopView, healthForItem index: Int) -> Float {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        return combatant.health
    }

    // MARK: TabletopViewDelegate
    
    func tabletopView(tabletopView: TabletopView, moveItem index: Int, to location: TabletopLocation) {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        combatant.location = location
    }
    
    func tabletopView(tabletopView: TabletopView, didSelectItem index: Int) {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant

        // This is kind of a hack, but it does what I want for now.
        navigationController?.popViewControllerAnimated(true)
        if let encounterViewController = navigationController?.topViewController as? EncounterViewController {
            let combatantsViewController = encounterViewController.combatantsViewController
            let indexPath = combatantsViewController.fetchedResultsController.indexPathForObject(combatant)
            combatantsViewController.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
            combatantsViewController.performSegueWithIdentifier("CombatantSegue", sender: self)
        }
    }

    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tabletopView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tabletopView.insertItemAtIndex(newIndexPath!.row)
        case .Delete:
            tabletopView.deleteItemAtIndex(indexPath!.row)
        case .Update:
            tabletopView.updateItemAtIndex(indexPath!.row)
        case .Move:
            tabletopView.deleteItemAtIndex(indexPath!.row)
            tabletopView.insertItemAtIndex(newIndexPath!.row)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tabletopView.endUpdates()
    }
    
}

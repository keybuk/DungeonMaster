//
//  TabletopViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/8/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class TabletopViewController: UIViewController {

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
        if let textField = navigationItem.titleView as? UITextField {
            textField.text = navigationItem.title
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        // We use a predicate on the Combatant table, matching against the encounter, rather than just using "encounter.combatants" so that we can be a delegate and get change notifications.
        let fetchRequest = NSFetchRequest(entity: Model.Combatant)
        
        let predicate = NSPredicate(format: "encounter = %@", encounter)
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

    // MARK: Actions
    
    @IBAction func textFieldPrimaryAction(sender: UITextField) {
        encounter.name = sender.text
        sender.resignFirstResponder()
    }
}

// MARK: TabletopViewDataSource
extension TabletopViewController: TabletopViewDataSource {
    
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
        return combatant.monster.name
    }
    
    func tabletopView(tabletopView: TabletopView, healthForItem index: Int) -> Float {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        return combatant.health
    }

}

// MARK: TabletopViewDelegate
extension TabletopViewController: TabletopViewDelegate {
    
    func tabletopView(tabletopView: TabletopView, moveItem index: Int, to location: TabletopLocation) {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        combatant.location = location
    }
    
    func tabletopView(tabletopView: TabletopView, didSelectItem index: Int) {
        let combatant = fetchedResultsController.fetchedObjects![index] as! Combatant
        if let encounterViewController = (splitViewController?.viewControllers[0] as! UINavigationController).topViewController as? EncounterViewController {
            for (sectionIndex, section) in encounterViewController.fetchedResultsController.sections!.enumerate() {
                let combatants = section.objects as! [Combatant]?
                if let rowIndex = combatants?.indexOf(combatant) {
                    encounterViewController.tableView.selectRowAtIndexPath(NSIndexPath(forRow: rowIndex, inSection: sectionIndex), animated: true, scrollPosition: .Middle)
                    encounterViewController.performSegueWithIdentifier("CombatantSegue", sender: self)
                }
            }
        }
    }

}

// MARK: NSFetchedResultsControllerDelegate
extension TabletopViewController: NSFetchedResultsControllerDelegate {
    
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

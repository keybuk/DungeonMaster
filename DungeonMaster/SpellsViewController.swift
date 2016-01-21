//
//  SpellsViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/29/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class SpellsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISplitViewControllerDelegate {

    var books: [Book]!

    @IBOutlet var tableView: UITableView!

    var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController?.delegate = self
        
        // Search Controller; can't create these in IB yet.
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
    }

    var contentOffsetIncludesSearchBar = false

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when we reappear in collapsed mode, or when not using a split view controller.
        if splitViewController == nil || splitViewController!.collapsed {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        
        // Offset the table view by the height of the search bar to hide it under the navigation bar by default.
        if !contentOffsetIncludesSearchBar {
            tableView.contentOffset.y += searchController.searchBar.bounds.size.height
            contentOffsetIncludesSearchBar = true
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SpellDetailSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let spell = fetchedResultsController.objectAtIndexPath(indexPath) as! Spell
                let viewController = (segue.destinationViewController as! UINavigationController).topViewController as! SpellViewController
                viewController.spell = spell
                viewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                viewController.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Spell)
        fetchRequest.fetchBatchSize = 20

        // Sorting by name is enough for section handling by initial to work.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [ sortDescriptor ]
        
        // Set the filter based on both the set of books, and the search pattern.
        let booksPredicate = NSPredicate(format: "ANY sources.book IN %@", books)
        
        if let search = searchController.searchBar.text where searchController.active {
            let schoolList = MagicSchool.cases.filter({ $0.stringValue.lowercaseString.containsString(search.lowercaseString) }).map({ $0.rawValue })
            
            let searchPredicate = NSPredicate(format: "rawSchool IN %@ OR name CONTAINS[cd] %@", schoolList as NSArray, search)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [booksPredicate, searchPredicate])
        } else {
            fetchRequest.predicate = booksPredicate
        }

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "nameInitial", cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
 
    func updateFetchedResults() {
        _fetchedResultsController = nil
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    // MARK: Sections
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchController.active else { return nil }
        return fetchedResultsController.sections![section].name
    }

    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard !searchController.active else { return nil }
        return fetchedResultsController.sectionIndexTitles
    }
    
    // MARK: Rows
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SpellCell", forIndexPath: indexPath) as! SpellCell
        let spell = fetchedResultsController.objectAtIndexPath(indexPath) as! Spell
        cell.spell = spell
        return cell
    }
    
    // MARK: - UITableViewDelegate

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
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! SpellCell
            let spell = anObject as! Spell
            cell.spell = spell
        case .Move:
            // .Move implies .Update; update the cell at the old index with the result at the new index, and then move it.
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! SpellCell
            let spell = anObject as! Spell
            cell.spell = spell
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

    // MARK: UISearchControllerDelegate
    
    func didPresentSearchController(searchController: UISearchController) {
        // Remove the thumb index when displaying the search controller. This works because the delegate method checks whether the search controller is active before displaying.
        tableView.reloadSectionIndexTitles()
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        // Reset the table back to no search predicate, and reload the data.
        updateFetchedResults()
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        updateFetchedResults()
    }

    // MARK: UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        if let secondaryViewController = secondaryViewController as? UINavigationController,
            spellViewController = secondaryViewController.topViewController as? SpellViewController where spellViewController.spell == nil {
                // If we're not yet showing a spell detail in the secondary view controller, do nothing, and then return 'true' to indicate the automatic behavior should be skipped—thus discarding the empty detail view.
                return true
        }
        
        // Otherwise let the automatic behavior win.
        return false
    }

}

// MARK: -

class SpellCell: UITableViewCell {

    var spell: Spell! {
        didSet {
            textLabel?.text = spell.name
        }
    }

}


//
//  SpellsViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/29/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class SpellsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISplitViewControllerDelegate {

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when we reappear in collapsed mode, or when not using a split view controller.
        if splitViewController == nil || splitViewController!.isCollapsed {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
        
        // Offset the table view by the height of the search bar to hide it under the navigation bar by default.
        if !contentOffsetIncludesSearchBar {
            tableView.contentOffset.y += searchController.searchBar.bounds.size.height
            contentOffsetIncludesSearchBar = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SpellDetailSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let spell = fetchedResultsController.object(at: indexPath) as! Spell
                let viewController = (segue.destination as! UINavigationController).topViewController as! SpellViewController
                viewController.spell = spell
                viewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                viewController.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>! {
        get {
            if let fetchedResultsController = _fetchedResultsController {
                return fetchedResultsController
            }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entity: Model.Spell)
            fetchRequest.fetchBatchSize = 20

            // Sorting by name is enough for section handling by initial to work.
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [ sortDescriptor ]
            
            // Set the filter based on both the set of books, and the search pattern.
            let booksPredicate = NSPredicate(format: "ANY sources.book IN %@", books)
            
            if let search = searchController.searchBar.text, searchController.isActive {
                let schoolList = MagicSchool.cases.filter({ $0.stringValue.lowercased().contains(search.lowercased()) }).map({ $0.rawValue })
                
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
        
        set(newFetchedResultsController) {
            _fetchedResultsController = newFetchedResultsController
        }
    }
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
 
    // MARK: UITableViewDataSource

    // MARK: Sections
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchController.isActive else { return nil }
        return fetchedResultsController.sections![section].name
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !searchController.isActive else { return nil }
        return fetchedResultsController.sectionIndexTitles
    }
    
    // MARK: Rows
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpellCell", for: indexPath) as! SpellCell
        let spell = fetchedResultsController.object(at: indexPath) as! Spell
        cell.spell = spell
        return cell
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
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? SpellCell {
                let spell = anObject as! Spell
                cell.spell = spell
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    // MARK: UISearchControllerDelegate
    
    func didPresentSearchController(_ searchController: UISearchController) {
        // Remove the thumb index when displaying the search controller. This works because the delegate method checks whether the search controller is active before displaying.
        tableView.reloadSectionIndexTitles()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        // Reset the table back to no search predicate, and reload the data.
        fetchedResultsController = nil
        tableView.reloadData()
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        fetchedResultsController = nil
        tableView.reloadData()
    }

    // MARK: UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        if let secondaryViewController = secondaryViewController as? UINavigationController,
            let spellViewController = secondaryViewController.topViewController as? SpellViewController, spellViewController.spell == nil {
                // If we're not yet showing a spell detail in the secondary view controller, do nothing, and then return 'true' to indicate the automatic behavior should be skipped—thus discarding the empty detail view.
                return true
        }
        
        // Otherwise let the automatic behavior win.
        return false
    }

}

// MARK: -

class SpellCell : UITableViewCell {

    var spell: Spell! {
        didSet {
            textLabel?.text = spell.name
        }
    }

}


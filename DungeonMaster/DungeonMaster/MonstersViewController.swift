//
//  MonstersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/4/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class MonstersViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISplitViewControllerDelegate {
    
    var books: [Book]!
    
    // This feels like a hack, it's just used to be able to use the entire split view as a way to add monsters from the compendium.
    var detailBarButtonItems: [UIBarButtonItem]?

    @IBOutlet var extendedNavigationBarView: ExtendedNavigationBarView!
    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    var searchController: UISearchController!

    enum MonstersSort: Int {
        case byName
        case byCrXp
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedNavigationBarView.navigationBar = navigationController?.navigationBar
        extendedNavigationBarView.scrollView = tableView
        
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
        if segue.identifier == "MonsterDetailSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let monster = fetchedResultsController.object(at: indexPath)
                let viewController = (segue.destination as! UINavigationController).topViewController as! MonsterViewController
                viewController.monster = monster
                viewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                viewController.navigationItem.leftItemsSupplementBackButton = true
                if let rightBarButtonItems = detailBarButtonItems {
                    viewController.navigationItem.rightBarButtonItems = rightBarButtonItems
                }
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func sortControlValueChanged(_ sortControl: UISegmentedControl) {
        fetchedResultsController = nil
        tableView.reloadData()
    }

    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Monster>! {
        get {
            if let fetchedResultsController = _fetchedResultsController {
                return fetchedResultsController
            }
            
            let fetchRequest = NSFetchRequest<Monster>(entity: Model.Monster)
            fetchRequest.fetchBatchSize = 20
            
            let sectionNameKeyPath: String
            let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
            switch sort {
            case .byName:
                // Sorting by name is enough for section handling by initial to work.
                let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
                fetchRequest.sortDescriptors = [sortDescriptor]
                
                sectionNameKeyPath = "nameInitial"
            case .byCrXp:
                let primarySortDescriptor = NSSortDescriptor(key: "challenge", ascending: true)
                let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
                fetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
                
                sectionNameKeyPath = "challenge"
            }
            
            // Set the filter based on both the set of books, and the search pattern.
            let booksPredicate = NSPredicate(format: "ANY sources.book IN %@", books)

            if let search = searchController.searchBar.text, searchController.isActive {
                let typeList = MonsterType.cases.filter({ $0.stringValue.lowercased().contains(search.lowercased()) }).map({ $0.rawValue })
                
                let searchPredicate = NSPredicate(format: "rawType IN %@ OR name CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", typeList as NSArray, search, search)
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [booksPredicate, searchPredicate])
            } else {
                fetchRequest.predicate = booksPredicate
            }

            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
            fetchedResultsController.delegate = self
            _fetchedResultsController = fetchedResultsController
            
            try! _fetchedResultsController!.performFetch()

            return _fetchedResultsController!
        }
        
        set(newFetchedResultsController) {
            _fetchedResultsController = newFetchedResultsController
        }
    }
    fileprivate var _fetchedResultsController: NSFetchedResultsController<Monster>?
    
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
        let sectionInfo = fetchedResultsController.sections![section]
        
        let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
        switch sort {
        case .byName:
            return sectionInfo.name
        case .byCrXp:
            let challenge = NSDecimalNumber(string: sectionInfo.name)
            let challengeString: String
            if challenge == NSDecimalNumber(string: "0.125") {
                challengeString = "1/8"
            } else if challenge == NSDecimalNumber(string: "0.25") {
                challengeString = "1/4"
            } else if challenge == NSDecimalNumber(string: "0.5") {
                challengeString = "1/2"
            } else {
                challengeString = "\(challenge)"
            }

            let xpString: String
            if challenge != 0 {
                let xpFormatter = NumberFormatter()
                xpFormatter.numberStyle = .decimal
                
                xpString = xpFormatter.string(from: NSNumber(value: sharedRules.challengeXP[challenge]!))!
            } else {
                xpString = "0–10"
            }

            return "\(challengeString) (\(xpString) XP)"
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !searchController.isActive else { return nil }
        return fetchedResultsController.sectionIndexTitles
    }
    
    // MARK: Rows

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MonsterCell", for: indexPath) as! MonsterCell
        let monster = fetchedResultsController.object(at: indexPath)
        cell.monster = monster        
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
            if let cell = tableView.cellForRow(at: indexPath!) as? MonsterCell {
                let monster = anObject as! Monster
                cell.monster = monster
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
        
        switch sort {
        case .byName:
            return sectionName
        case .byCrXp:
            if sectionName == "0.125" {
                return "⅛"
            } else if sectionName == "0.25" {
                return "¼"
            } else if sectionName == "0.5" {
                return "½"
            } else {
                return sectionName
            }
        }
    }
    
    // MARK: UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        // Hide the part of the navigation bar with the sort buttons.
        extendedNavigationBarView.isHidden = true
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        // Remove the thumb index when displaying the search controller. This works because the delegate method checks whether the search controller is active before displaying.
        tableView.reloadSectionIndexTitles()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        // Unhide the part of the navigation bar with the sort button.
        extendedNavigationBarView.isHidden = false
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        // Reset the table back to no search predicate, and reload the data.
        _fetchedResultsController = nil
        tableView.reloadData()
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        _fetchedResultsController = nil
        tableView.reloadData()
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        if let secondaryViewController = secondaryViewController as? UINavigationController,
            let monsterViewController = secondaryViewController.topViewController as? MonsterViewController, monsterViewController.monster == nil {
                // If we're not yet showing a monster stat block in the secondary view controller, do nothing, and then return 'true' to indicate the automatic behavior should be skipped—thus discarding the empty stat block view.
                return true
        }
        
        // Otherwise let the automatic behavior win.
        return false
    }
    
}

// MARK: -

class MonsterCell : UITableViewCell {
    
    var monster: Monster! {
        didSet {
            textLabel?.text = monster.name
        }
    }

}


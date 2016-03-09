//
//  MonstersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/4/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class MonstersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISplitViewControllerDelegate {
    
    var books: [Book]!
    
    // This feels like a hack, it's just used to be able to use the entire split view as a way to add monsters from the compendium.
    var detailBarButtonItems: [UIBarButtonItem]?

    @IBOutlet var extendedNavigationBarView: ExtendedNavigationBarView!
    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    var searchController: UISearchController!

    enum MonstersSort: Int {
        case ByName
        case ByCrXp
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
        if segue.identifier == "MonsterDetailSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let monster = fetchedResultsController.objectAtIndexPath(indexPath) as! Monster
                let viewController = (segue.destinationViewController as! UINavigationController).topViewController as! MonsterViewController
                viewController.monster = monster
                viewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                viewController.navigationItem.leftItemsSupplementBackButton = true
                if let rightBarButtonItems = detailBarButtonItems {
                    viewController.navigationItem.rightBarButtonItems = rightBarButtonItems
                }
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func sortControlValueChanged(sortControl: UISegmentedControl) {
        fetchedResultsController = nil
        tableView.reloadData()
    }

    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController! {
        get {
            if let fetchedResultsController = _fetchedResultsController {
                return fetchedResultsController
            }
            
            let fetchRequest = NSFetchRequest(entity: Model.Monster)
            fetchRequest.fetchBatchSize = 20
            
            let sectionNameKeyPath: String
            let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
            switch sort {
            case .ByName:
                // Sorting by name is enough for section handling by initial to work.
                let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
                fetchRequest.sortDescriptors = [sortDescriptor]
                
                sectionNameKeyPath = "nameInitial"
            case .ByCrXp:
                let primarySortDescriptor = NSSortDescriptor(key: "challenge", ascending: true)
                let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
                fetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
                
                sectionNameKeyPath = "challenge"
            }
            
            // Set the filter based on both the set of books, and the search pattern.
            let booksPredicate = NSPredicate(format: "ANY sources.book IN %@", books)

            if let search = searchController.searchBar.text where searchController.active {
                let typeList = MonsterType.cases.filter({ $0.stringValue.lowercaseString.containsString(search.lowercaseString) }).map({ $0.rawValue })
                
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
    private var _fetchedResultsController: NSFetchedResultsController?
    
    // MARK: UITableViewDataSource
    
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
        let sectionInfo = fetchedResultsController.sections![section]
        
        let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
        switch sort {
        case .ByName:
            return sectionInfo.name
        case .ByCrXp:
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
                let xpFormatter = NSNumberFormatter()
                xpFormatter.numberStyle = .DecimalStyle
                
                xpString = xpFormatter.stringFromNumber(sharedRules.challengeXP[challenge]!)!
            } else {
                xpString = "0–10"
            }

            return "\(challengeString) (\(xpString) XP)"
        }
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard !searchController.active else { return nil }
        return fetchedResultsController.sectionIndexTitles
    }
    
    // MARK: Rows

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MonsterCell", forIndexPath: indexPath) as! MonsterCell
        let monster = fetchedResultsController.objectAtIndexPath(indexPath) as! Monster
        cell.monster = monster        
        return cell
    }

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
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? MonsterCell {
                let monster = anObject as! Monster
                cell.monster = monster
            }
        case .Move:
            // .Move implies .Update; update the cell at the old index with the result at the new index, and then move it.
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? MonsterCell {
                let monster = anObject as! Monster
                cell.monster = monster
            }

            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
        let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
        
        switch sort {
        case .ByName:
            return sectionName
        case .ByCrXp:
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
    
    func willPresentSearchController(searchController: UISearchController) {
        // Hide the part of the navigation bar with the sort buttons.
        extendedNavigationBarView.hidden = true
    }

    func didPresentSearchController(searchController: UISearchController) {
        // Remove the thumb index when displaying the search controller. This works because the delegate method checks whether the search controller is active before displaying.
        tableView.reloadSectionIndexTitles()
    }

    func willDismissSearchController(searchController: UISearchController) {
        // Unhide the part of the navigation bar with the sort button.
        extendedNavigationBarView.hidden = false
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        // Reset the table back to no search predicate, and reload the data.
        _fetchedResultsController = nil
        tableView.reloadData()
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        _fetchedResultsController = nil
        tableView.reloadData()
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        if let secondaryViewController = secondaryViewController as? UINavigationController,
            monsterViewController = secondaryViewController.topViewController as? MonsterViewController where monsterViewController.monster == nil {
                // If we're not yet showing a monster stat block in the secondary view controller, do nothing, and then return 'true' to indicate the automatic behavior should be skipped—thus discarding the empty stat block view.
                return true
        }
        
        // Otherwise let the automatic behavior win.
        return false
    }
    
}

// MARK: -

class MonsterCell: UITableViewCell {
    
    var monster: Monster! {
        didSet {
            textLabel?.text = monster.name
        }
    }

}


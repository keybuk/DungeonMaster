//
//  MonstersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/4/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class MonstersViewController: UIViewController {
    
    @IBOutlet var extendedNavigationBarView: ExtendedNavigationBarView!
    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var topConstraintOutsideSearch: NSLayoutConstraint!
    @IBOutlet var topConstraintInsideSearch: NSLayoutConstraint!
    
    var addMode = false

    var searchController: UISearchController?
    var hiddenBooks: Set<Book>?

    enum MonstersSort: Int {
        case ByName
        case ByCrXp
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Search Controller; can't create these in IB yet.
        searchController = UISearchController(searchResultsController: nil)
        searchController!.delegate = self
        searchController!.searchResultsUpdater = self
        searchController!.obscuresBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController!.searchBar
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Remove the navigation bar's shadow.
        extendedNavigationBarView.removeShadowFromNavigationBar(navigationController?.navigationBar)

        // Deselect the row when we reappear in collapsed mode.
        if splitViewController!.collapsed {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }

        // Shift the table down to hide the search bar.
        tableView.contentOffset.y += searchController!.searchBar.frame.size.height
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore the default navigation bar shadow for the next view.
        extendedNavigationBarView.restoreShadowToNavigationBar(navigationController?.navigationBar)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MonsterDetailSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let monster = fetchedResultsController.objectAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = monster
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                if let index = controller.navigationItem.rightBarButtonItems?.indexOf(controller.addButton) {
                    if !addMode {
                        controller.navigationItem.rightBarButtonItems?.removeAtIndex(index)
                    }
                }
                if let index = controller.navigationItem.rightBarButtonItems?.indexOf(controller.doneButton) {
                    controller.navigationItem.rightBarButtonItems?.removeAtIndex(index)
                }
            }
        } else if segue.identifier == "BooksPopoverSegue" {
            let booksViewController = (segue.destinationViewController as! UINavigationController).topViewController as! BooksViewController
            booksViewController.hiddenBooks = hiddenBooks
        }
    }
    
    @IBAction func unwindFromBooks(segue: UIStoryboardSegue) {
        let booksViewController = segue.sourceViewController as! BooksViewController
        if booksViewController.hiddenBooks != hiddenBooks {
            hiddenBooks = booksViewController.hiddenBooks
            updateFetchedResults()
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let hiddenBooks = hiddenBooks {
                let bookNames = hiddenBooks.map { book -> String in
                    return book.name
                }
                defaults.setObject(bookNames, forKey: "HiddenBooks")
            } else {
                defaults.removeObjectForKey("HiddenBooks")
            }
        }
    }

    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        }
        
        // Load previously saved hidden books. Handled here rather than in viewDidLoad because this happens first, and reloading data straight after would be ugly.
        let defaults = NSUserDefaults.standardUserDefaults()
        if let hiddenBookNames = defaults.objectForKey("HiddenBooks") as? [String] {
            let fetchRequest = NSFetchRequest(entity: Model.Book)
            fetchRequest.predicate = NSPredicate(format: "name in %@", hiddenBookNames)
            
            let books = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Book]
            hiddenBooks = Set<Book>(books)
        }
        
        // Create and execute the fetch request.
        updateFetchRequestController()

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
    
    func updateFetchRequestController(search search: String? = nil) {
        let fetchRequest = NSFetchRequest(entity: Model.Monster)
        fetchRequest.fetchBatchSize = 20

        // Sorting by name is enough for section handling by initial to work.
        let sectionNameKeyPath: String
        let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
        switch sort {
        case .ByName:
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            sectionNameKeyPath = "nameInitial"
        case .ByCrXp:
            let primarySortDescriptor = NSSortDescriptor(key: "challenge", ascending: true)
            let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
            
            sectionNameKeyPath = "challenge"
        }
        
        // Set the filter based on both the hidden books, and the search pattern.
        var booksPredicate: NSPredicate?
        var searchPredicate: NSPredicate?
        
        if let hiddenBooks = hiddenBooks {
            booksPredicate = NSPredicate(format: "SUBQUERY(sources, $s, $s.book IN %@).@count < sources.@count", hiddenBooks)
        }
        
        if let search = search {
            let typeList = MonsterType.cases.filter({ $0.stringValue.lowercaseString.containsString(search.lowercaseString) }).map({ $0.rawValue })
    
            searchPredicate = NSPredicate(format: "rawType IN %@ OR name CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", typeList as NSArray, search, search)
        }
        
        if let booksPredicate = booksPredicate, searchPredicate = searchPredicate {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [booksPredicate, searchPredicate])
        } else if let booksPredicate = booksPredicate {
            fetchRequest.predicate = booksPredicate
        } else if let searchPredicate = searchPredicate {
            fetchRequest.predicate = searchPredicate
        }
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
    }
    
    func updateFetchedResults(search search: String? = nil) {
        updateFetchRequestController(search: search)
        tableView.reloadData()
    }
    
    // MARK: Actions

    @IBAction func sortControlValueChanged(sortControl: UISegmentedControl) {
        updateFetchedResults()
    }

}

// MARK: UITableViewDataSource
extension MonstersViewController: UITableViewDataSource {
    
    // MARK: Sections

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchController!.active else { return nil }
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
        guard !searchController!.active else { return nil }
        return fetchedResultsController.sectionIndexTitles
    }
    
    // MARK: Rows

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MonsterCell", forIndexPath: indexPath) as! MonsterCell
        let monster = fetchedResultsController.objectAtIndexPath(indexPath) as! Monster
        cell.monster = monster        
        return cell
    }

}

// MARK: UITableViewDelegate
extension MonstersViewController: UITableViewDelegate {

}

// MARK: NSFetchedResultsControllerDelegate
extension MonstersViewController: NSFetchedResultsControllerDelegate {

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
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! MonsterCell
            let monster = fetchedResultsController.objectAtIndexPath(indexPath!) as! Monster
            cell.monster = monster
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
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
    
}

// MARK: UISearchControllerDelegate
extension MonstersViewController: UISearchControllerDelegate {
    
    func willPresentSearchController(searchController: UISearchController) {
        // Hide the part of the navigation bar with the sort buttons.
        view.removeConstraint(topConstraintOutsideSearch)
        view.addConstraint(topConstraintInsideSearch)
        extendedNavigationBarView.hidden = true
    }

    func didPresentSearchController(searchController: UISearchController) {
        // Remove the thumb index when displaying the search controller. This works because the delegate method checks whether the search controller is active before displaying.
        tableView.reloadSectionIndexTitles()
    }

    func willDismissSearchController(searchController: UISearchController) {
        // Unhide the part of the navigation bar with the sort button.
        view.removeConstraint(topConstraintInsideSearch)
        view.addConstraint(topConstraintOutsideSearch)
        extendedNavigationBarView.hidden = false
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        // Reset the table back to no search predicate, and reload the data.
        updateFetchedResults()
    }
    
}

// MARK: UISearchResultsUpdating
extension MonstersViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let text = searchController.searchBar.text!
        updateFetchedResults(search: text)
    }
    
}

// MARK: - 

class MonsterCell: UITableViewCell {
    
    var monster: Monster? {
        didSet {
            textLabel?.text = monster!.name
        }
    }

}


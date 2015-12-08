//
//  MonstersViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/4/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import CoreData

class MonstersViewController: UIViewController {
    
    @IBOutlet var extendedNavigationBarView: ExtendedNavigationBarView!
    @IBOutlet var sortControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var topConstraintOutsideSearch: NSLayoutConstraint!
    @IBOutlet var topConstraintInsideSearch: NSLayoutConstraint!

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
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        let color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        navigationController?.navigationBar.shadowImage = UIGraphicsGetImageFromCurrentImageContext()
        
        let bgColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        CGContextSetFillColorWithColor(context, bgColor.CGColor)
        CGContextFillRect(context, rect)
        
        navigationController?.navigationBar.setBackgroundImage(UIGraphicsGetImageFromCurrentImageContext(), forBarMetrics: .Default)
        
        UIGraphicsEndImageContext()

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
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
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
            if hiddenBooks != nil {
                let bookNames = hiddenBooks!.map { book -> String in
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
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        // Load previously saved hidden books. Handled here rather than in viewDidLoad because this happens first, and reloading data straight after would be ugly.
        let defaults = NSUserDefaults.standardUserDefaults()
        if let hiddenBookNames = defaults.objectForKey("HiddenBooks") as? [String] {
            let fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entity(Model.Book, inManagedObjectContext: managedObjectContext)
            fetchRequest.entity = entity
            
            fetchRequest.predicate = NSPredicate(format: "name in %@", hiddenBookNames)
            
            do {
                let books = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Book]
                hiddenBooks = Set<Book>(books)
            } catch {
                let error = error as NSError
                print("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
        
        // Create and execute the fetch request.
        updateFetchRequestController()

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
    
    func updateFetchRequestController(search search: String? = nil) {
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entity(Model.Monster, inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
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
            let primarySortDescriptor = NSSortDescriptor(key: "cr", ascending: true)
            let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
            
            sectionNameKeyPath = "cr"
        }
        
        // Set the filter based on both the hidden books, and the search pattern.
        var booksPredicate: NSPredicate?
        var searchPredicate: NSPredicate?
        
        if let hiddenBooks = hiddenBooks {
            booksPredicate = NSPredicate(format: "SUBQUERY(sources, $s, $s.book IN %@).@count < sources.@count", hiddenBooks)
        }
        
        if let search = search {
            searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@ OR type CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", search, search, search)
        }
        
        if booksPredicate != nil && searchPredicate != nil {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [booksPredicate!, searchPredicate!])
        } else if booksPredicate != nil {
            fetchRequest.predicate = booksPredicate
        } else if searchPredicate != nil {
            fetchRequest.predicate = searchPredicate
        }
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            let error = error as NSError
            print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }
    
    func updateFetchedResults(search search: String? = nil) {
        updateFetchRequestController(search: search)
        tableView.reloadData()
    }

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
        let monster = sectionInfo.objects!.first as! Monster
        
        let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
        switch sort {
        case .ByName:
            return monster.nameInitial
        case .ByCrXp:
            return monster.challenge
        }
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard !searchController!.active else { return nil }
        let sort = MonstersSort(rawValue: sortControl.selectedSegmentIndex)!
        return fetchedResultsController.sections!.map { sectionInfo in
            let monster = sectionInfo.objects!.first as! Monster

            switch sort {
            case .ByName:
                return monster.nameInitial
            case .ByCrXp:
                //return "\(monster.cr)"
                if monster.cr > 0.9 {
                    let cr = Int(monster.cr)
                    return "\(cr)"
                } else if monster.cr > 0.4 {
                    return "½"
                } else if monster.cr > 0.2 {
                    return "¼"
                } else if monster.cr > 0.1 {
                    return "⅛"
                } else {
                    return "0"
                }
            }
        }
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


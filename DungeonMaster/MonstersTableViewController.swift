//
//  MonstersTableViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/4/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import CoreData

class MonstersTableViewController: UITableViewController {
    
    var searchController: UISearchController?
    var hiddenBooks: Set<Book>?

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
        if let splitViewController = splitViewController {
            clearsSelectionOnViewWillAppear = splitViewController.collapsed
        }        
        super.viewWillAppear(animated)

        // Shift the table down to hide the search bar.
        tableView.contentOffset.y += searchController!.searchBar.frame.size.height
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MonsterDetailSegue" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let monster = self.fetchedResultsController.objectAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = monster
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        } else if segue.identifier == "BooksPopoverSegue" {
            let booksTableViewController = (segue.destinationViewController as! UINavigationController).topViewController as! BooksTableViewController
            booksTableViewController.hiddenBooks = hiddenBooks
        }
    }
    
    @IBAction func unwindFromBooks(segue: UIStoryboardSegue) {
        let booksTableViewController = segue.sourceViewController as! BooksTableViewController
        if booksTableViewController.hiddenBooks != hiddenBooks {
            hiddenBooks = booksTableViewController.hiddenBooks
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

        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entity(Model.Monster, inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Sorting by name is enough for section handling by initial to work.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchRequest.predicate = fetchResultsPredicate()
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "nameInitial", cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            let error = error as NSError
            print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
    
    func fetchResultsPredicate(search search: String? = nil) -> NSPredicate? {
        var booksPredicate: NSPredicate?
        var searchPredicate: NSPredicate?
        
        if let hiddenBooks = hiddenBooks {
            booksPredicate = NSPredicate(format: "SUBQUERY(sources, $s, $s.book IN %@).@count < sources.@count", hiddenBooks)
        }
        
        if let search = search {
            searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@ OR type CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", search, search, search)
        }
        
        if booksPredicate != nil && searchPredicate != nil {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [booksPredicate!, searchPredicate!])
        } else if booksPredicate != nil {
            return booksPredicate
        } else if searchPredicate != nil {
            return searchPredicate
        } else {
            return nil
        }
    }

    func updateFetchedResults(search search: String? = nil) {
        _fetchedResultsController?.fetchRequest.predicate = fetchResultsPredicate(search: search)
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            let error = error as NSError
            print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        tableView.reloadData()
    }

}

// MARK: UITableViewDataSource
extension MonstersTableViewController {
    
    // MARK: Sections

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchController!.active else { return nil }
        let sectionInfo = fetchedResultsController.sections![section]
        let monster = sectionInfo.objects!.first as! Monster
        return monster.nameInitial
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard !searchController!.active else { return nil }
        return fetchedResultsController.sections!.map { sectionInfo in
            let monster = sectionInfo.objects!.first as! Monster
            return monster.nameInitial
        }
    }
    
    // MARK: Rows

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MonstersTableViewCell", forIndexPath: indexPath) as! MonstersTableViewCell
        let monster = fetchedResultsController.objectAtIndexPath(indexPath) as! Monster
        cell.monster = monster        
        return cell
    }

}

// MARK: UITableViewDelegate
extension MonstersTableViewController {

}

// MARK: NSFetchedResultsControllerDelegate
extension MonstersTableViewController: NSFetchedResultsControllerDelegate {

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
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! MonstersTableViewCell
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
extension MonstersTableViewController: UISearchControllerDelegate {

    func didPresentSearchController(searchController: UISearchController) {
        // Remove the thumb index when displaying the search controller. This works because the delegate method checks whether the search controller is active before displaying.
        tableView.reloadSectionIndexTitles()
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        // Reset the table back to no search predicate, and reload the data.
        updateFetchedResults()
    }
    
}

// MARK: UISearchResultsUpdating
extension MonstersTableViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let text = searchController.searchBar.text!
        updateFetchedResults(search: text)
    }
    
}


// MARK: - 
class MonstersTableViewCell: UITableViewCell {
    
    var monster: Monster? {
        didSet {
            textLabel?.text = monster!.name
        }
    }

}


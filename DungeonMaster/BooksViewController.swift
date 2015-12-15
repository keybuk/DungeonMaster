//
//  BooksViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/6/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import CoreData

class BooksViewController: UITableViewController {

    var hiddenBooks: Set<Book>?

    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entity(Model.Book, inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
        
        let typeSortDescriptor = NSSortDescriptor(key: "rawType", ascending: true)
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [ typeSortDescriptor, nameSortDescriptor ]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "rawType", cacheName: nil)
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

    // MARK: Cell layout

    func updateCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) {
        let book = fetchedResultsController.objectAtIndexPath(indexPath) as! Book
        
        cell.textLabel?.text = book.name
        if hiddenBooks != nil && hiddenBooks!.contains(book) {
            cell.accessoryType = .None
        } else {
            cell.accessoryType = .Checkmark
        }
    }

}

// MARK: UITableViewDataSource
extension BooksViewController {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        let book = sectionInfo.objects?[0] as? Book
        guard book != nil else { return nil }
        
        switch book!.type {
        case .CoreRulebook:
            return "Core Rulebooks"
        case .OfficialAdventure:
            return "Official Adventures"
        case .OnlineSupplement:
            return "Online Supplements"
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BookCell", forIndexPath: indexPath)
        updateCell(cell, forIndexPath: indexPath)
        return cell
    }

}

// MARK: UITableViewDelegate
extension BooksViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let book = fetchedResultsController.objectAtIndexPath(indexPath) as! Book

        if hiddenBooks == nil {
            hiddenBooks = [ book ]
        } else if hiddenBooks!.contains(book) {
            hiddenBooks!.remove(book)
            if hiddenBooks!.count == 0 {
                hiddenBooks = nil
            }
        } else {
            hiddenBooks!.insert(book)
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        updateCell(cell!, forIndexPath: indexPath)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}

// MARK: NSFetchedResultsControllerDelegate
extension BooksViewController: NSFetchedResultsControllerDelegate {
    
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
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
                updateCell(cell, forIndexPath: indexPath!)
            }
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

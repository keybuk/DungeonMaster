//
//  BooksViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/6/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class BooksViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var hiddenBooks: Set<Book>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Book)
        
        let typeSortDescriptor = NSSortDescriptor(key: "rawType", ascending: true)
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [ typeSortDescriptor, nameSortDescriptor ]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "rawType", cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    // MARK: Cell layout

    func updateCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) {
        let book = fetchedResultsController.objectAtIndexPath(indexPath) as! Book
        
        cell.textLabel?.text = book.name
        if let hiddenBooks = hiddenBooks where hiddenBooks.contains(book) {
            cell.accessoryType = .None
        } else {
            cell.accessoryType = .Checkmark
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        
        let bookType = BookType(rawValue: Int(sectionInfo.name)!)!
        return "\(bookType.stringValue)s"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BookCell", forIndexPath: indexPath)
        updateCell(cell, forIndexPath: indexPath)
        return cell
    }

    // MARK: UITableViewDelegate

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

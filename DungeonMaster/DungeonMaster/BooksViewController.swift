//
//  BooksViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/6/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class BooksViewController : UITableViewController, NSFetchedResultsControllerDelegate {

    var hiddenBooks: Set<Book>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController<Book> = { [unowned self] in
        let fetchRequest = NSFetchRequest<Book>(entity: Model.Book)
        
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

    func updateCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath) {
        let book = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = book.name
        if let hiddenBooks = hiddenBooks, hiddenBooks.contains(book) {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .checkmark
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        
        let bookType = BookType(rawValue: Int(sectionInfo.name)!)!
        return "\(bookType.stringValue)s"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath)
        updateCell(cell, forIndexPath: indexPath)
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let book = fetchedResultsController.object(at: indexPath) 

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
        
        let cell = tableView.cellForRow(at: indexPath)
        updateCell(cell!, forIndexPath: indexPath)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) {
                updateCell(cell, forIndexPath: indexPath!)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}

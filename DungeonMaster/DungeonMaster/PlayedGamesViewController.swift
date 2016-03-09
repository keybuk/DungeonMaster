//
//  PlayedGamesViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/22/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

/// View controller that displays the log entries for a specific player's played games.
///
/// In its normal mode the view uses a query on the `LogEntry`s themselves, sorted and grouped by the `PlayedGame` relationship. The purpose being to display something of a "quest log" for the player concerned.
///
/// In edit mode the view becomes more complex, instead showing all of the `PlayedGame`s for the player, combining both queries, and allowing the addition of new log entries, as well as moving log entries around and even between games.
class PlayedGamesViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    /// Player whose log entries to show.
    var player: Player!
    
    /// Specific game the view was instantiated from.
    ///
    /// This currently has no effect on the view, but it might in future.
    var game: Game?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "GameHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GameHeaderView")

        tableView.sectionHeaderHeight = 60.0
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        let oldEditing = self.editing
        super.setEditing(editing, animated: animated)
        
        if editing != oldEditing {
            // Invalidate the sections map so it will get rebuilt.
            sectionsInResults = nil

            // Insert a section where one doesn't exist in the results, otherwise insert a row.
            let sections = NSMutableIndexSet()
            var indexPaths: [NSIndexPath] = []

            for (section, playedGame) in playedGames.enumerate() {
                if let _ = sectionsInResults[section] {
                    // Row insertions seem to get processed after section insertions, so use section rather than sectionsInResults[section] here.
                    let row = playedGame.logEntries.count
                    indexPaths.append(NSIndexPath(forRow: row, inSection: section))
                } else {
                    sections.addIndex(section)
                }
            }
            
            tableView.beginUpdates()
            if editing {
                tableView.insertSections(sections, withRowAnimation: .Automatic)
                tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            } else {
                tableView.deleteSections(sections, withRowAnimation: .Automatic)
                tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
            tableView.endUpdates()
        }
        
        if oldEditing && !editing {
            playedGames = nil
            sectionsInResults = nil
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddLogEntrySegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let viewController = segue.destinationViewController as! AddLogEntryViewController
                viewController.playedGame = playedGame(forSectionInTable: indexPath.section)
                
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    // MARK: Fetched results controller
    
    /// Fetched results are the set of `LogEntry` for the player, grouped by the ObjectID of the `PlayedGame` relationship.
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.LogEntry)
        fetchRequest.predicate = NSPredicate(format: "playedGame.player == %@", self.player)
        
        let gameDateSortDescriptor = NSSortDescriptor(key: "playedGame.game.date", ascending: false)
        let indexSortDescriptor = NSSortDescriptor(key: "rawIndex", ascending: true)
        fetchRequest.sortDescriptors = [gameDateSortDescriptor, indexSortDescriptor]
        
        // The section name key path here seems pretty hacky, but it's the best way I can think of to section on a relationship.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "playedGame.objectID.URIRepresentation", cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()
    
    /// The complete set of `PlayedGame`s for the player, sorted by date to match `fetchedResultsController`.
    var playedGames: [PlayedGame]! {
        get {
            if let playedGames = _playedGames {
                return playedGames
            }
            
            let fetchRequest = NSFetchRequest(entity: Model.PlayedGame)
            fetchRequest.predicate = NSPredicate(format: "player == %@", self.player)
            
            let gameDateSortDescriptor = NSSortDescriptor(key: "game.date", ascending: false)
            fetchRequest.sortDescriptors = [gameDateSortDescriptor]

            _playedGames = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [PlayedGame]
            
            return _playedGames
        }
        
        set(newPlayedGames) {
            _playedGames = newPlayedGames
        }
    }
    private var _playedGames: [PlayedGame]?
    
    /// Map of table sections to the underlying fetched results sections.
    var sectionsInResults: [Int: Int]! {
        get {
            if let sectionsInResults = _sectionsInResults {
                return sectionsInResults
            }
            
            // Rebuild the sections map.
            let existingPlayedGames = fetchedResultsController.sections!.indices.map({ playedGame(forSectionInResults: $0) })
            
            _sectionsInResults = [:]
            for (section, playedGame) in playedGames.enumerate() {
                if let existingSection = existingPlayedGames.indexOf(playedGame) {
                    _sectionsInResults![section] = existingSection
                }
            }
            
            return _sectionsInResults
        }
        
        set(newSectionsInResults) {
            _sectionsInResults = newSectionsInResults
        }
    }
    private var _sectionsInResults: [Int: Int]?

    /// Returns the `PlayedGame` object for the given `section` in the results.
    func playedGame(forSectionInResults section: Int) -> PlayedGame {
        let sectionInfo = fetchedResultsController.sections![section]
        let objectID = persistentStoreCoordinator.managedObjectIDForURIRepresentation(NSURL(string: sectionInfo.name)!)!
        let playedGame = try! managedObjectContext.existingObjectWithID(objectID) as! PlayedGame

        return playedGame
    }
    
    /// Returns the `PlayedGame` object for the given `section` in the table view.
    func playedGame(forSectionInTable section: Int) -> PlayedGame {
        if editing {
            return playedGames[section]
        } else {
            return playedGame(forSectionInResults: section)
        }
    }
    
    /// Returns `indexPath` translated from the table view, to the results.
    func indexPathInResults(forIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if editing {
            let playedGame = playedGames[indexPath.section]
            if indexPath.row == playedGame.logEntries.count {
                return nil
            } else if let section = sectionsInResults[indexPath.section] {
                return NSIndexPath(forRow: indexPath.row, inSection: section)
            } else {
                return nil
            }
        } else {
            return indexPath
        }
    }
    
    /// Returns `indexPath` translated from the results, to the table view.
    func indexPath(forIndexPathInResults indexPath: NSIndexPath) -> NSIndexPath {
        if editing {
            let section = sectionsInResults[sectionsInResults.indexOf({ $0.1 == indexPath.section })!].0
            return NSIndexPath(forRow: indexPath.row, inSection: section)
        } else {
            return indexPath
        }
    }
    
    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if editing {
            return playedGames.count
        } else {
            return fetchedResultsController.sections?.count ?? 0
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if editing {
            let playedGame = playedGames[section]
            return playedGame.logEntries.count + 1
        } else {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let indexPath = indexPathInResults(forIndexPath: indexPath) {
            switch fetchedResultsController.objectAtIndexPath(indexPath) {
            case let xpAward as XPAward:
                let cell = tableView.dequeueReusableCellWithIdentifier("XPAwardCell", forIndexPath: indexPath) as! XPAwardCell
                cell.xpAward = xpAward
                return cell
            case let logEntryNote as LogEntryNote:
                let cell = tableView.dequeueReusableCellWithIdentifier("LogEntryNoteCell", forIndexPath: indexPath) as! LogEntryNoteCell
                cell.logEntryNote = logEntryNote
                return cell
            default:
                fatalError("Unexpected LogEntry subclass")
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("AddLogEntryCell", forIndexPath: indexPath) as! AddLogEntryCell
            return cell
        }
    }
    
    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            guard let indexPath = indexPathInResults(forIndexPath: indexPath) else { fatalError("Unexpected index path outside of results") }

            let logEntry = fetchedResultsController.objectAtIndexPath(indexPath) as! LogEntry
            let playedGame = logEntry.playedGame
            let index = logEntry.index
            
            managedObjectContext.deleteObject(logEntry)
        
            // Reindex the rest of the entries in the same game
            for case let remainingEntry as LogEntry in playedGame.logEntries {
                if remainingEntry.index > index {
                    remainingEntry.index -= 1
                }
            }
            
            try! managedObjectContext.save()

        } else if editingStyle == .Insert {
            tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            performSegueWithIdentifier("AddLogEntrySegue", sender: self)
        }
    }
    
    // MARK: Move support
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let _ = indexPathInResults(forIndexPath: indexPath) {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        let playedGame = self.playedGame(forSectionInTable: proposedDestinationIndexPath.section)
        if sourceIndexPath.section == proposedDestinationIndexPath.section && proposedDestinationIndexPath.row >= playedGame.logEntries.count {
            // Within the same section, we don't want to even reach the "last row", since it's a re-order, always return the previous.
            let indexPath = NSIndexPath(forRow: playedGame.logEntries.count - 1, inSection: proposedDestinationIndexPath.section)
            return indexPath
        } else if proposedDestinationIndexPath.row > playedGame.logEntries.count {
            // Within different sections, it's okay to reach it and go on the end, but not replace the "add entry" marker.
            let indexPath = NSIndexPath(forRow: playedGame.logEntries.count, inSection: proposedDestinationIndexPath.section)
            return indexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    var changeIsUserDriven = false

    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        guard let fromIndexPath = indexPathInResults(forIndexPath: fromIndexPath) else { fatalError("Index path being moved is not in results") }
        let logEntry = fetchedResultsController.objectAtIndexPath(fromIndexPath) as! LogEntry
        let oldPlayedGame = logEntry.playedGame, oldIndex = logEntry.index

        let newPlayedGame = self.playedGame(forSectionInTable: toIndexPath.section)
        if toIndexPath.row < newPlayedGame.logEntries.count {
            // Moving within the set of results, which means that we have an existing log entry that we're displacing.
            guard let toIndexPath = indexPathInResults(forIndexPath: toIndexPath) else { fatalError("Destination index path is not in results") }
            let displacedLogEntry = fetchedResultsController.objectAtIndexPath(toIndexPath) as! LogEntry
            let newIndex = displacedLogEntry.index
            assert(displacedLogEntry.playedGame == newPlayedGame, "Played game mismatched at destination")
            
            // Renumber the entries in the "old" played game to make as if the moving entry is no longer there.
            for case let futureEntry as LogEntry in oldPlayedGame.logEntries {
                if futureEntry.index >= oldIndex {
                    futureEntry.index -= 1
                }
            }

            // Renumber the entries in the "new" played game to make room for the moving entry.
            for case let futureEntry as LogEntry in newPlayedGame.logEntries {
                if futureEntry.index >= newIndex {
                    futureEntry.index += 1
                }
            }

            // Now renumber the entry that we're moving.
            logEntry.playedGame = newPlayedGame
            logEntry.index = newIndex

        } else {
            // Moving outside the set of normal results, either to the end of a different game that has results, or to a game that doesn't yet have any results. Handle as a special case, especially since `toIndexPath` may not be translatable directly into results.
            logEntry.playedGame = newPlayedGame
            logEntry.index = newPlayedGame.logEntries.count // Includes the new entry, which is fine since we're 1-indexed.
            
            // Renumber the entries in the old played game to make as if the moving entry is no longer there.
            for case let futureEntry as LogEntry in oldPlayedGame.logEntries {
                if futureEntry.index >= oldIndex {
                    futureEntry.index -= 1
                }
            }
        }

        changeIsUserDriven = true

        try! managedObjectContext.save()
    }

    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // The "section name" is the URI Representation of the Object ID of the PlayedGame object.
        let playedGame = self.playedGame(forSectionInTable: section)
        
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("GameHeaderView") as! GameHeaderView
        header.game = playedGame.game
                
        return header
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if let _ = indexPathInResults(forIndexPath: indexPath) {
            return .Delete
        } else {
            return .Insert
        }
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if let indexPath = indexPathInResults(forIndexPath: indexPath) {
            return editing ? nil : indexPath
        } else {
            return indexPath
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        // Changes to the set of sections requires rebuilding the sectionsInResults map, so invalidate it here.
        sectionsInResults = nil
        
        // Skip the rest of this method if the change was used driven (table already matches the result of the change), or if in editing mode (all sections already exist).
        guard !changeIsUserDriven else { return }
        guard !editing else { return }
        
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        guard !changeIsUserDriven else { return }
        
        // Unlike every other case, `indexPath` and `newIndexPath` refer to an index in the results and need to be translated to an index in the table.
        let indexPath = indexPath.map({ self.indexPath(forIndexPathInResults: $0) })
        let newIndexPath = newIndexPath.map({ self.indexPath(forIndexPathInResults: $0) })

        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            switch anObject {
            case let xpAward as XPAward:
                if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? XPAwardCell {
                    cell.xpAward = xpAward
                }
            case let logEntryNote as LogEntryNote:
                if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LogEntryNoteCell {
                    cell.logEntryNote = logEntryNote
                }
            default:
                fatalError("Unexpected LogEntry subclass")
            }
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            switch anObject {
            case let xpAward as XPAward:
                if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? XPAwardCell {
                    cell.xpAward = xpAward
                }
            case let logEntryNote as LogEntryNote:
                if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LogEntryNoteCell {
                    cell.logEntryNote = logEntryNote
                }
            default:
                fatalError("Unexpected LogEntry subclass")
            }

            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        
        changeIsUserDriven = false
    }
    
}

class GameHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    var game: Game! {
        didSet {
            numberLabel.text = game.title
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .NoStyle
            
            dateLabel.text = dateFormatter.stringFromDate(game.date)
        }
    }
    
}

class XPAwardCell: UITableViewCell {
    
    @IBOutlet var xpLabel: UILabel!
    @IBOutlet var reasonLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var xpAward: XPAward! {
        didSet {
            let xpFormatter = NSNumberFormatter()
            xpFormatter.numberStyle = .DecimalStyle
            
            let xpString = xpFormatter.stringFromNumber(xpAward.xp)!
            xpLabel.text = "\(xpString) XP"
            
            reasonLabel.text = xpAward.reason
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        xpLabel.font = xpLabel.font.monospacedDigitFont
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

class LogEntryNoteCell: UITableViewCell {
    
    @IBOutlet var noteLabel: UILabel!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var logEntryNote: LogEntryNote! {
        didSet {
            noteLabel.text = logEntryNote.note
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

class AddLogEntryCell: UITableViewCell {

    @IBOutlet var label: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.tintColor = tintColor
    }
}

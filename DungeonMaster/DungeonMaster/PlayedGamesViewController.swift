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
class PlayedGamesViewController : UITableViewController, NSFetchedResultsControllerDelegate {

    /// Player whose log entries to show.
    var player: Player!
    
    /// Specific game the view was instantiated from.
    ///
    /// This currently has no effect on the view, but it might in future.
    var game: Game?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "GameHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GameHeaderView")

        tableView.sectionHeaderHeight = 60.0
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let oldEditing = self.isEditing
        super.setEditing(editing, animated: animated)
        
        if editing != oldEditing {
            // Invalidate the sections map so it will get rebuilt.
            sectionsInResults = nil

            // Insert a section where one doesn't exist in the results, otherwise insert a row.
            let sections = NSMutableIndexSet()
            var indexPaths: [IndexPath] = []

            for (section, playedGame) in playedGames.enumerated() {
                if let _ = sectionsInResults[section] {
                    // Row insertions seem to get processed after section insertions, so use section rather than sectionsInResults[section] here.
                    let row = playedGame.logEntries.count
                    indexPaths.append(IndexPath(row: row, section: section))
                } else {
                    sections.add(section)
                }
            }
            
            tableView.beginUpdates()
            if editing {
                tableView.insertSections(sections as IndexSet, with: .automatic)
                tableView.insertRows(at: indexPaths, with: .automatic)
            } else {
                tableView.deleteSections(sections as IndexSet, with: .automatic)
                tableView.deleteRows(at: indexPaths, with: .automatic)
            }
            tableView.endUpdates()
        }
        
        if oldEditing && !editing {
            playedGames = nil
            sectionsInResults = nil
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddLogEntrySegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let viewController = segue.destination as! AddLogEntryViewController
                viewController.playedGame = playedGame(forSectionInTable: (indexPath as NSIndexPath).section)
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: Fetched results controller
    
    /// Fetched results are the set of `LogEntry` for the player, grouped by the ObjectID of the `PlayedGame` relationship.
    lazy var fetchedResultsController: NSFetchedResultsController<LogEntry> = { [unowned self] in
        let fetchRequest = NSFetchRequest<LogEntry>(entity: Model.LogEntry)
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
            
            let fetchRequest = NSFetchRequest<PlayedGame>(entity: Model.PlayedGame)
            fetchRequest.predicate = NSPredicate(format: "player == %@", self.player)
            
            let gameDateSortDescriptor = NSSortDescriptor(key: "game.date", ascending: false)
            fetchRequest.sortDescriptors = [gameDateSortDescriptor]

            _playedGames = try! managedObjectContext.fetch(fetchRequest)
            
            return _playedGames
        }
        
        set(newPlayedGames) {
            _playedGames = newPlayedGames
        }
    }
    fileprivate var _playedGames: [PlayedGame]?
    
    /// Map of table sections to the underlying fetched results sections.
    var sectionsInResults: [Int: Int]! {
        get {
            if let sectionsInResults = _sectionsInResults {
                return sectionsInResults
            }
            
            // Rebuild the sections map.
            let existingPlayedGames = fetchedResultsController.sections!.indices.map({ playedGame(forSectionInResults: $0) })
            
            _sectionsInResults = [:]
            for (section, playedGame) in playedGames.enumerated() {
                if let existingSection = existingPlayedGames.index(of: playedGame) {
                    _sectionsInResults![section] = existingSection
                }
            }
            
            return _sectionsInResults
        }
        
        set(newSectionsInResults) {
            _sectionsInResults = newSectionsInResults
        }
    }
    fileprivate var _sectionsInResults: [Int: Int]?

    /// Returns the `PlayedGame` object for the given `section` in the results.
    func playedGame(forSectionInResults section: Int) -> PlayedGame {
        let sectionInfo = fetchedResultsController.sections![section]
        let objectID = persistentStoreCoordinator.managedObjectID(forURIRepresentation: URL(string: sectionInfo.name)!)!
        let playedGame = try! managedObjectContext.existingObject(with: objectID) as! PlayedGame

        return playedGame
    }
    
    /// Returns the `PlayedGame` object for the given `section` in the table view.
    func playedGame(forSectionInTable section: Int) -> PlayedGame {
        if isEditing {
            return playedGames[section]
        } else {
            return playedGame(forSectionInResults: section)
        }
    }
    
    /// Returns `indexPath` translated from the table view, to the results.
    func indexPathInResults(forIndexPath indexPath: IndexPath) -> IndexPath? {
        if isEditing {
            let playedGame = playedGames[(indexPath as NSIndexPath).section]
            if (indexPath as NSIndexPath).row == playedGame.logEntries.count {
                return nil
            } else if let section = sectionsInResults[(indexPath as NSIndexPath).section] {
                return IndexPath(row: (indexPath as NSIndexPath).row, section: section)
            } else {
                return nil
            }
        } else {
            return indexPath
        }
    }
    
    /// Returns `indexPath` translated from the results, to the table view.
    func indexPath(forIndexPathInResults indexPath: IndexPath) -> IndexPath {
        if isEditing {
            let section = sectionsInResults[sectionsInResults.index(where: { $0.1 == (indexPath as NSIndexPath).section })!].0
            return IndexPath(row: (indexPath as NSIndexPath).row, section: section)
        } else {
            return indexPath
        }
    }
    
    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isEditing {
            return playedGames.count
        } else {
            return fetchedResultsController.sections?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isEditing {
            let playedGame = playedGames[section]
            return playedGame.logEntries.count + 1
        } else {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let indexPath = indexPathInResults(forIndexPath: indexPath) {
            switch fetchedResultsController.object(at: indexPath) {
            case let xpAward as XPAward:
                let cell = tableView.dequeueReusableCell(withIdentifier: "XPAwardCell", for: indexPath) as! XPAwardCell
                cell.xpAward = xpAward
                return cell
            case let logEntryNote as LogEntryNote:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LogEntryNoteCell", for: indexPath) as! LogEntryNoteCell
                cell.logEntryNote = logEntryNote
                return cell
            default:
                fatalError("Unexpected LogEntry subclass")
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddLogEntryCell", for: indexPath) as! AddLogEntryCell
            return cell
        }
    }
    
    // MARK: Edit support
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let indexPath = indexPathInResults(forIndexPath: indexPath) else { fatalError("Unexpected index path outside of results") }

            let logEntry = fetchedResultsController.object(at: indexPath)
            let playedGame = logEntry.playedGame
            let index = logEntry.index
            
            managedObjectContext.delete(logEntry)
        
            // Reindex the rest of the entries in the same game
            for case let remainingEntry as LogEntry in playedGame.logEntries {
                if remainingEntry.index > index {
                    remainingEntry.index -= 1
                }
            }
            
            try! managedObjectContext.save()

        } else if editingStyle == .insert {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            performSegue(withIdentifier: "AddLogEntrySegue", sender: self)
        }
    }
    
    // MARK: Move support
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if let _ = indexPathInResults(forIndexPath: indexPath) {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let playedGame = self.playedGame(forSectionInTable: (proposedDestinationIndexPath as NSIndexPath).section)
        if (sourceIndexPath as NSIndexPath).section == (proposedDestinationIndexPath as NSIndexPath).section && (proposedDestinationIndexPath as NSIndexPath).row >= playedGame.logEntries.count {
            // Within the same section, we don't want to even reach the "last row", since it's a re-order, always return the previous.
            let indexPath = IndexPath(row: playedGame.logEntries.count - 1, section: (proposedDestinationIndexPath as NSIndexPath).section)
            return indexPath
        } else if (proposedDestinationIndexPath as NSIndexPath).row > playedGame.logEntries.count {
            // Within different sections, it's okay to reach it and go on the end, but not replace the "add entry" marker.
            let indexPath = IndexPath(row: playedGame.logEntries.count, section: (proposedDestinationIndexPath as NSIndexPath).section)
            return indexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    var changeIsUserDriven = false

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        guard let fromIndexPath = indexPathInResults(forIndexPath: fromIndexPath) else { fatalError("Index path being moved is not in results") }
        let logEntry = fetchedResultsController.object(at: fromIndexPath) 
        let oldPlayedGame = logEntry.playedGame, oldIndex = logEntry.index

        let newPlayedGame = self.playedGame(forSectionInTable: (toIndexPath as NSIndexPath).section)
        if (toIndexPath as NSIndexPath).row < newPlayedGame.logEntries.count {
            // Moving within the set of results, which means that we have an existing log entry that we're displacing.
            guard let toIndexPath = indexPathInResults(forIndexPath: toIndexPath) else { fatalError("Destination index path is not in results") }
            let displacedLogEntry = fetchedResultsController.object(at: toIndexPath) 
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // The "section name" is the URI Representation of the Object ID of the PlayedGame object.
        let playedGame = self.playedGame(forSectionInTable: section)
        
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GameHeaderView") as! GameHeaderView
        header.game = playedGame.game
                
        return header
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if let _ = indexPathInResults(forIndexPath: indexPath) {
            return .delete
        } else {
            return .insert
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let indexPath = indexPathInResults(forIndexPath: indexPath) {
            return isEditing ? nil : indexPath
        } else {
            return indexPath
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard !changeIsUserDriven else { return }

        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        // Changes to the set of sections requires rebuilding the sectionsInResults map, so invalidate it here.
        sectionsInResults = nil
        
        // Skip the rest of this method if the change was used driven (table already matches the result of the change), or if in editing mode (all sections already exist).
        guard !changeIsUserDriven else { return }
        guard !isEditing else { return }
        
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
        guard !changeIsUserDriven else { return }
        
        // Unlike every other case, `indexPath` and `newIndexPath` refer to an index in the results and need to be translated to an index in the table.
        let indexPath = indexPath.map({ self.indexPath(forIndexPathInResults: $0) })
        let newIndexPath = newIndexPath.map({ self.indexPath(forIndexPathInResults: $0) })

        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            switch anObject {
            case let xpAward as XPAward:
                if let cell = tableView.cellForRow(at: indexPath!) as? XPAwardCell {
                    cell.xpAward = xpAward
                }
            case let logEntryNote as LogEntryNote:
                if let cell = tableView.cellForRow(at: indexPath!) as? LogEntryNoteCell {
                    cell.logEntryNote = logEntryNote
                }
            default:
                fatalError("Unexpected LogEntry subclass")
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard !changeIsUserDriven else {
            changeIsUserDriven = false
            return
        }

        tableView.endUpdates()
    }
    
}

// MARK: -

class GameHeaderView : UITableViewHeaderFooterView {
    
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    var game: Game! {
        didSet {
            numberLabel.text = game.title
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            
            dateLabel.text = dateFormatter.string(from: game.date as Date)
        }
    }
    
}

class XPAwardCell : UITableViewCell {
    
    @IBOutlet var xpLabel: UILabel!
    @IBOutlet var reasonLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var xpAward: XPAward! {
        didSet {
            xpLabel.text = xpAward.xpString
            reasonLabel.text = xpAward.reason
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        xpLabel.font = xpLabel.font.monospacedDigitFont
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

class LogEntryNoteCell : UITableViewCell {
    
    @IBOutlet var noteLabel: UILabel!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var logEntryNote: LogEntryNote! {
        didSet {
            noteLabel.text = logEntryNote.note
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

class AddLogEntryCell : UITableViewCell {

    @IBOutlet var label: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.tintColor = tintColor
    }
}

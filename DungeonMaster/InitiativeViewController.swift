//
//  InitiativeViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/4/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class InitiativeViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var encounter: Encounter!
    var game: Game!

    @IBOutlet var doneButtonItem: UIBarButtonItem!
    
    var beginGameOnDone = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // When this is the first initiative roll, we use it to indicate that the game is to be begun.
        if encounter.round == 0 {
            addPlayersFromGame()
            encounter.round = 1
            beginGameOnDone = true
        }
        
        // Roll initiative for any monster without it.
        rollInitiative()
        
        // Always in editing mode.
        setEditing(true, animated: false)
        validateEncounter()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addPlayersFromGame() {
        for case let playedGame as PlayedGame in game.playedGames {
            let _ = Combatant(encounter: encounter, player: playedGame.player, inManagedObjectContext: managedObjectContext)
        }
    }
    
    func rollInitiative() {
        var rolled = false

        // Gather the pre-rolled initiative values for monsters.
        var prerolledInitiative: [Monster: Int] = [:]
        for case let combatant as Combatant in encounter.combatants {
            guard combatant.role != .Player else { continue }
            guard let monster = combatant.monster else { continue }
            guard let initiative = combatant.initiative else { continue }
            
            prerolledInitiative[monster] = initiative
        }
        
        // Now go back and roll initiative where we need to, making sure we use the same new roll for all monsters of the same type too.
        var initiativeDice = [Monster: DiceCombo]()
        for case let combatant as Combatant in encounter.combatants {
            guard combatant.role != .Player else { continue }
            guard let monster = combatant.monster else { continue }
            guard combatant.initiative == nil else { continue }
            
            if let initiative = prerolledInitiative[monster] {
                combatant.initiative = initiative
            } else if let combo = initiativeDice[monster] {
                combatant.initiative = combo.value
            } else {
                let combo = monster.initiativeDice.reroll()
                initiativeDice[monster] = combo
                combatant.initiative = combo.value
                rolled = true
            }
        }
        
        if rolled {
            PlaySound(.Initiative)
        }
    }
    
    func validateEncounter() {
        for case let combatant as Combatant in encounter.combatants {
            if combatant.initiative == nil {
                doneButtonItem.enabled = false
                return
            }
        }
        
        doneButtonItem.enabled = true
    }
    
    // MARK: Actions
    
    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        if beginGameOnDone {
            let combatant = fetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! Combatant
            combatant.isCurrentTurn = true
        }
        
        encounter.lastModified = NSDate()
        try! managedObjectContext.save()

        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        }
        
        let fetchRequest = NSFetchRequest(entity: Model.Combatant)
        fetchRequest.predicate = NSPredicate(format: "encounter == %@", encounter)
        
        let initiativeSortDescriptor = NSSortDescriptor(key: "rawInitiative", ascending: false)
        let initiativeOrderSortDescriptor = NSSortDescriptor(key: "rawInitiativeOrder", ascending: true)
        let monsterDexSortDescriptor = NSSortDescriptor(key: "monster.rawDexterityScore", ascending: false)
        let dateCreatedSortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: true)
        fetchRequest.sortDescriptors = [initiativeSortDescriptor, initiativeOrderSortDescriptor, monsterDexSortDescriptor, dateCreatedSortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
    
    /// The set of Players that are not participating in this encounter.
    ///
    /// This is generated by using the standard results controller, and has to be invalidated using `invalidateMissingPlayers` whenever that changes.
    var missingPlayers: [Player] {
        if let missingPlayers = _missingPlayers {
            return missingPlayers
        }
        
        // Ideally we'd use something like "NONE combatants.encounter == %@" here, but that doesn't work.
        let fetchRequest = NSFetchRequest(entity: Model.Player)
        let players = fetchedResultsController.fetchedObjects!.flatMap({ ($0 as! Combatant).player })
        fetchRequest.predicate = NSPredicate(format: "ANY playedGames.game == %@ AND NOT SELF IN %@", game, players)

        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
        _missingPlayers = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Player]
        return _missingPlayers!
    }
    var _missingPlayers: [Player]?
    
    /// Invalidate the set of missing players.
    func invalidateMissingPlayers() {
        _missingPlayers = nil
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (fetchedResultsController.sections?.count ?? 0) + 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if section < addSection {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        } else {
            return missingPlayers.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            // Combatant in the encounter.
            let cell = tableView.dequeueReusableCellWithIdentifier("InitiativeCombatantCell", forIndexPath: indexPath) as! InitiativeCombatantCell
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            cell.combatant = combatant
            return cell
        } else {
            // Player not in the encounter.
            let cell = tableView.dequeueReusableCellWithIdentifier("InitiativeMissingPlayerCell", forIndexPath: indexPath) as! InitiativeMissingPlayerCell
            let player = missingPlayers[indexPath.row]
            cell.player = player
            return cell
        }
        
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            managedObjectContext.deleteObject(combatant)
        } else if editingStyle == .Insert {
            let player = missingPlayers[indexPath.row]
            let _ = Combatant(encounter: encounter, player: player, inManagedObjectContext: managedObjectContext)
        }
    }
    
    // MARK: Move support
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            return combatant.initiative != nil
        } else {
            return false
        }
    }
    
    var changeIsUserDriven = false
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let combatant = fetchedResultsController.objectAtIndexPath(fromIndexPath) as! Combatant
        let displacedCombatant = fetchedResultsController.objectAtIndexPath(toIndexPath) as! Combatant

        combatant.initiativeOrder = displacedCombatant.initiativeOrder! + 1
    
        var startRow = toIndexPath.row
        if fromIndexPath.row < toIndexPath.row {
            startRow += 1
        }
        
        for row in startRow..<fetchedResultsController.sections![toIndexPath.section].numberOfObjects {
            let indexPath = NSIndexPath(forRow: row, inSection: toIndexPath.section)
            let adjustCombatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            
            // Only adjust combatants with the same initiative value, and skip the combatant we're moving!
            guard adjustCombatant.initiative == combatant.initiative else { break }
            guard adjustCombatant != combatant else { continue }
            
            adjustCombatant.initiativeOrder = adjustCombatant.initiativeOrder! + 2
        }
        
        changeIsUserDriven = true
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let addSection = fetchedResultsController.sections?.count ?? 0
        if indexPath.section < addSection {
            let combatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
            return combatant.player != nil ? .Delete : .None
        } else {
            return .Insert
        }
    }

    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        let combatant = fetchedResultsController.objectAtIndexPath(sourceIndexPath) as! Combatant
        let appendRow = fetchedResultsController.sections![0].numberOfObjects

        // First make sure we're not trying to move into the "missing players" section, and adjust the destination to the end of the combatants section if that's the case.
        var indexPath = proposedDestinationIndexPath
        if indexPath.section != 0 || indexPath.row == appendRow {
            indexPath = NSIndexPath(forRow: appendRow - 1, inSection: 0)
        }
        
        // It's okay to move to an index path that's occupied by a combatant with the same initiative.
        let displacedCombatant = fetchedResultsController.objectAtIndexPath(indexPath) as! Combatant
        if combatant.initiative == displacedCombatant.initiative {
            return indexPath
        } else {
            return sourceIndexPath
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    var oldMissingPlayers: [Player]?
    var selectIndexPath: NSIndexPath?
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // Clear or reset the cache of missing players, keeping the old cache around for insertion checking.
        oldMissingPlayers = editing ? missingPlayers : nil
        invalidateMissingPlayers()
        
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
        guard !changeIsUserDriven else { return }
    
        switch type {
        case .Insert:
            let combatant = anObject as! Combatant
            if let player = combatant.player, oldIndex = oldMissingPlayers?.indexOf(player) {
                let oldIndexPath = NSIndexPath(forRow: oldIndex, inSection: 1)
                tableView.deleteRowsAtIndexPaths([ oldIndexPath ], withRowAnimation: .Top)
                
                if combatant.initiative == nil {
                    selectIndexPath = newIndexPath
                }
            }
            
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Bottom)
        case .Delete:
            // The combatant object will have already had its player relationship invalidated, so we cheat and store it in the cell.
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! InitiativeCombatantCell
            if let player = cell.player, newIndex = missingPlayers.indexOf(player) {
                let newIndexPath = NSIndexPath(forRow: newIndex, inSection: 1)
                tableView.insertRowsAtIndexPaths([ newIndexPath ], withRowAnimation: .Top)
            }
            
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Bottom)
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! InitiativeCombatantCell
            let combatant = anObject as! Combatant
            cell.combatant = combatant
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! InitiativeCombatantCell
            let combatant = anObject as! Combatant
            cell.combatant = combatant
            
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        
        changeIsUserDriven = false
        
        if let indexPath = selectIndexPath, cell = tableView.cellForRowAtIndexPath(indexPath) as? InitiativeCombatantCell {
            cell.initiativeTextField.becomeFirstResponder()
            selectIndexPath = nil
        }

        validateEncounter()
    }

}

class InitiativeCombatantCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var initiativeTextField: UITextField!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var combatant: Combatant! {
        didSet {
            player = combatant.player

            if let monster = combatant.monster {
                nameLabel.text = monster.name
            } else if let player = combatant.player {
                nameLabel.text = player.name
            }
            
            initiativeTextField.text = combatant.initiative.map({ "\($0)" })
        }
    }
    var player: Player?
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        if let text = sender.text where text != "" {
            combatant.initiative = Int(text)!
        } else {
            combatant.initiative = nil
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let validSet = NSCharacterSet.decimalDigitCharacterSet()
        for character in string.unicodeScalars {
            if !validSet.longCharacterIsMember(character.value) {
                return false
            }
        }
        return true
    }

}

class InitiativeMissingPlayerCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!

    var player: Player! {
        didSet {
            nameLabel.text = player.name
        }
    }

}

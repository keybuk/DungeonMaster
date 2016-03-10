//
//  PlayerViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class PlayerViewController: UITableViewController, ManagedObjectObserverDelegate {
    
    /// Player to be edited.
    var player: Player!
    
    /// Block to execute when editing is complete.
    var completionBlock: ((cancelled: Bool, player: Player?) -> Void)?

    @IBOutlet var cancelButtonItem: UIBarButtonItem!

    var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem()
        
        // When called with a new player, immediately enter editing mode.
        if player.inserted {
            setEditing(true, animated: false)
        }
        
        // If presented modally, add a cancel button.
        if let _ = presentingViewController {
            navigationItem.leftBarButtonItem = cancelButtonItem
        }
    
        observer = ManagedObjectObserver(object: player, delegate: self)
    }
    
    var nameBecomesFirstResponder = true
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // On first appearance with a new player, make the name field the first responder. We only do this once because we don't want to do it coming back from selecting things like race, class, etc.
        if player.inserted && nameBecomesFirstResponder {
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? PlayerNameCell {
                cell.textField.becomeFirstResponder()
                nameBecomesFirstResponder = false
            }
        }
    }
    
    /// Validate whether the player can be saved in its current state.
    ///
    /// Updates the "Done" button item to be enabled or disabled appropriately.
    func validatePlayer() {
        guard editing else { return }

        do {
            if player.inserted {
                try player.validateForInsert()
            } else {
                try player.validateForUpdate()
            }
            
            navigationItem.rightBarButtonItem?.enabled = true
        } catch {
            navigationItem.rightBarButtonItem?.enabled = false
        }
    }

    override func setEditing(editing: Bool, animated: Bool) {
        let oldEditing = self.editing, tableViewLoaded = self.tableViewLoaded
        super.setEditing(editing, animated: animated)

        // Only update the table when the editing state is actually changing, and if the table view data was loaded prior to the view being set to editing.
        if editing != oldEditing && tableViewLoaded {
            // Insert/remove the "add saving throws/skills" row.
            let savingThrowsIndexPath = NSIndexPath(forRow: player.savingThrows.count, inSection: 3)
            let skillsIndexPath = NSIndexPath(forRow: player.skills.count, inSection: 4)
            if editing {
                tableView.insertRowsAtIndexPaths([savingThrowsIndexPath, skillsIndexPath], withRowAnimation: .Automatic)
            } else {
                tableView.deleteRowsAtIndexPaths([savingThrowsIndexPath, skillsIndexPath], withRowAnimation: .Automatic)
            }
            
            // Toggle the editingTable state of the text and selection rows.
            let nameIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(nameIndexPath) as? PlayerNameCell {
                cell.editingTable = editing
            }
            
            let playerNameIndexPath = NSIndexPath(forRow: 1, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(playerNameIndexPath) as? PlayerPlayerNameCell {
                cell.editingTable = editing
            }

            let raceIndexPath = NSIndexPath(forRow: 0, inSection: 1)
            if let cell = tableView.cellForRowAtIndexPath(raceIndexPath) as? PlayerRaceCell {
                cell.editingTable = editing
            }

            let characterClassIndexPath = NSIndexPath(forRow: 1, inSection: 1)
            if let cell = tableView.cellForRowAtIndexPath(characterClassIndexPath) as? PlayerCharacterClassCell {
                cell.editingTable = editing
            }

            let backgroundIndexPath = NSIndexPath(forRow: 2, inSection: 1)
            if let cell = tableView.cellForRowAtIndexPath(backgroundIndexPath) as? PlayerBackgroundCell {
                cell.editingTable = editing
            }

            let alignmentIndexPath = NSIndexPath(forRow: 3, inSection: 1)
            if let cell = tableView.cellForRowAtIndexPath(alignmentIndexPath) as? PlayerAlignmentCell {
                cell.editingTable = editing
            }
            
            // Reload the XP/PP section with a fade so that it appears the table is just changing.
            tableView.beginUpdates()
            let xpIndexPath = NSIndexPath(forRow: 0, inSection: 2)
            let ppIndexPath = NSIndexPath(forRow: 1, inSection: 2)
            tableView.deleteRowsAtIndexPaths([xpIndexPath, ppIndexPath], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([xpIndexPath, ppIndexPath], withRowAnimation: .Fade)
            tableView.endUpdates()
        }

        if editing {
            // Make sure the "Done" button is disabled if the player can't be immediately saved.
            validatePlayer()
        }
        if oldEditing && !editing {
            try! managedObjectContext.save()
            completionBlock?(cancelled: false, player: player)
        }
    }

    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Selecting one of the options should be equivalent to changing edit field, so resign the responder status from any existing edit field.
        tableView.endEditing(false)

        if segue.identifier == "RaceSegue" {
            let viewController = segue.destinationViewController as! RaceViewController
            if let _ = player.primitiveValueForKey("rawRace") {
                viewController.selectedRace = player.race
            }
        } else if segue.identifier == "CharacterClassSegue" {
            let viewController = segue.destinationViewController as! CharacterClassViewController
            if let _ = player.primitiveValueForKey("rawCharacterClass") {
                viewController.selectedCharacterClass = player.characterClass
            }
        } else if segue.identifier == "BackgroundSegue" {
            let viewController = segue.destinationViewController as! BackgroundViewController
            if let _ = player.primitiveValueForKey("rawBackground") {
                viewController.selectedBackground = player.background
            }
        } else if segue.identifier == "AlignmentSegue" {
            let viewController = segue.destinationViewController as! AlignmentViewController
            if let _ = player.primitiveValueForKey("rawAlignment") {
                viewController.selectedAlignment = player.alignment
            }
        } else if segue.identifier == "AddSavingThrowSegue" {
            let viewController = segue.destinationViewController as! SavingThrowViewController
            viewController.existingSavingThrows = player.savingThrows.map({ ($0 as! PlayerSavingThrow).savingThrow })
        } else if segue.identifier == "AddSkillSegue" {
            let viewController = segue.destinationViewController as! SkillViewController
            viewController.existingSkills = player.skills.map({ ($0 as! PlayerSkill).skill })
        }
    }
    
    @IBAction func unwindFromRace(segue: UIStoryboardSegue) {
        let viewController = segue.sourceViewController as! RaceViewController
        player.race = viewController.selectedRace!
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 1)
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PlayerRaceCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromCharacterClass(segue: UIStoryboardSegue) {
        let viewController = segue.sourceViewController as! CharacterClassViewController
        player.characterClass = viewController.selectedCharacterClass!
        
        let indexPath = NSIndexPath(forRow: 1, inSection: 1)
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PlayerCharacterClassCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromBackground(segue: UIStoryboardSegue) {
        let viewController = segue.sourceViewController as! BackgroundViewController
        player.background = viewController.selectedBackground!
        
        let indexPath = NSIndexPath(forRow: 2, inSection: 1)
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PlayerBackgroundCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromAlignment(segue: UIStoryboardSegue) {
        let viewController = segue.sourceViewController as! AlignmentViewController
        player.alignment = viewController.selectedAlignment!
        
        let indexPath = NSIndexPath(forRow: 3, inSection: 1)
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PlayerAlignmentCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromSavingThrow(segue: UIStoryboardSegue) {
        let viewController = segue.sourceViewController as! SavingThrowViewController
        
        var newSavingThrows: [PlayerSavingThrow] = []
        for selectedSavingThrow in viewController.selectedSavingThrows {
            let savingThrow = PlayerSavingThrow(player: player, savingThrow: selectedSavingThrow, inManagedObjectContext: managedObjectContext)
            newSavingThrows.append(savingThrow)
        }
        
        sortedSavingThrows = nil

        let indexPaths = newSavingThrows.map({ NSIndexPath(forRow: sortedSavingThrows.indexOf($0)!, inSection: 3) })
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Top)
    }
    
    @IBAction func unwindFromSkill(segue: UIStoryboardSegue) {
        let viewController = segue.sourceViewController as! SkillViewController
        
        var newSkills: [PlayerSkill] = []
        for selectedSkill in viewController.selectedSkills {
            let skill = PlayerSkill(player: player, skill: selectedSkill, inManagedObjectContext: managedObjectContext)
            newSkills.append(skill)
        }
        
        sortedSkills = nil
        
        let indexPaths = newSkills.map({ NSIndexPath(forRow: sortedSkills.indexOf($0)!, inSection: 4) })
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Top)
    }

    // MARK: Actions

    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        if player.inserted {
            managedObjectContext.deleteObject(player)
        } else {
            managedObjectContext.refreshObject(player, mergeChanges: false)
        }

        completionBlock?(cancelled: true, player: nil)
    }
    
    // MARK: Caching for relationships
    
    var sortedSavingThrows: [PlayerSavingThrow]! {
        get {
            if _sortedSavingThrows == nil {
                let sortDescriptor = NSSortDescriptor(key: "rawSavingThrow", ascending: true)
                _sortedSavingThrows = player.savingThrows.sortedArrayUsingDescriptors([ sortDescriptor ]).map({ $0 as! PlayerSavingThrow })
            }
            
            return _sortedSavingThrows!
        }
        
        set(newSortedSavingThrows) {
            _sortedSavingThrows = newSortedSavingThrows
        }
    }
    private var _sortedSavingThrows: [PlayerSavingThrow]?
    
    var sortedSkills: [PlayerSkill]! {
        get {
            if _sortedSkills == nil {
                let abilitySortDescriptor = NSSortDescriptor(key: "rawAbility", ascending: true)
                let skillSortDescriptor = NSSortDescriptor(key: "rawSkill", ascending: true)
                _sortedSkills = player.skills.sortedArrayUsingDescriptors([ abilitySortDescriptor, skillSortDescriptor ]).map({ $0 as! PlayerSkill })
            }
            
            return _sortedSkills!
        }
        
        set(newSortedSkills) {
            _sortedSkills = newSortedSkills
        }
    }
    private var _sortedSkills: [PlayerSkill]?
    
    // MARK: UITableViewDataSource
    
    var tableViewLoaded = false
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        tableViewLoaded = true
        return 5
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // Character name, Player name
            return 2
        case 1:
            // Race, Class, Background, Alignment
            return 4
        case 2:
            // XP
            return 2
        case 3:
            // Saving Throws
            return player.savingThrows.count + (editing ? 1 : 0)
        case 4:
            // Skills
            return player.skills.count + (editing ? 1 : 0)
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0, 1, 2:
            return nil
        case 3:
            return "Saving Throw proficiencies"
        case 4:
            return "Skill proficiencies"
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerNameCell", forIndexPath: indexPath) as! PlayerNameCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = editing
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerPlayerNameCell", forIndexPath: indexPath) as! PlayerPlayerNameCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = editing
                return cell
            default:
                abort()
            }
        case 1:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerRaceCell", forIndexPath: indexPath) as! PlayerRaceCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = editing
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerCharacterClassCell", forIndexPath: indexPath) as! PlayerCharacterClassCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = editing
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerBackgroundCell", forIndexPath: indexPath) as! PlayerBackgroundCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = editing
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerAlignmentCell", forIndexPath: indexPath) as! PlayerAlignmentCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = editing
                return cell
            default:
                abort()
            }
        case 2:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier(editing ? "EditPlayerXPCell" : "PlayerXPCell", forIndexPath: indexPath) as! PlayerXPCell
                cell.player = player
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier(editing ? "EditPlayerPassivePerceptionCell" : "PlayerPassivePerceptionCell", forIndexPath: indexPath) as! PlayerPassivePerceptionCell
                cell.player = player
                return cell
            default:
                abort()
            }
        case 3:
            switch indexPath.row {
            case player.savingThrows.count:
                let cell = tableView.dequeueReusableCellWithIdentifier("AddPlayerSavingThrowCell", forIndexPath: indexPath)
                return cell
            default:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerSavingThrowCell", forIndexPath: indexPath) as! PlayerSavingThrowCell
                cell.playerSavingThrow = sortedSavingThrows[indexPath.row]
                return cell
            }
        case 4:
            switch indexPath.row {
            case player.skills.count:
                let cell = tableView.dequeueReusableCellWithIdentifier("AddPlayerSkillCell", forIndexPath: indexPath)
                return cell
            default:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerSkillCell", forIndexPath: indexPath) as! PlayerSkillCell
                cell.playerSkill = sortedSkills[indexPath.row]
                return cell
            }
        default:
            abort()
        }
    }
    
    // MARK: Editing support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch indexPath.section {
        case 0, 1, 2:
            // Return false to stop these cells being indented.
            return false
        case 3, 4:
            return true
        default:
            abort()
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if editing {
            return indexPath
        } else {
            return nil
        }
    }
    
    // MARK: Editing support
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        switch indexPath.section {
        case 0, 1, 2:
            return .None
        case 3:
            switch indexPath.row {
            case player.savingThrows.count:
                return .Insert
            default:
                return .Delete
            }
        case 4:
            switch indexPath.row {
            case player.skills.count:
                return .Insert
            default:
                return .Delete
            }
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .Delete else { return }

        switch indexPath.section {
        case 0, 1, 2:
            break
        case 3:
            switch indexPath.row {
            case player.savingThrows.count:
                break
            default:
                let savingThrow = sortedSavingThrows[indexPath.row]
                
                // FIXME this is a hack because we're not using a real fetched results controller.
                player.mutableSetValueForKey("savingThrows").removeObject(savingThrow)
                managedObjectContext.deleteObject(savingThrow)

                sortedSavingThrows = nil
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case 4:
            switch indexPath.row {
            case player.skills.count:
                break
            default:
                let skill = sortedSkills[indexPath.row]
                
                // FIXME this is a hack because we're not using a real fetched results controller.
                player.mutableSetValueForKey("skills").removeObject(skill)
                managedObjectContext.deleteObject(skill)
                
                sortedSkills = nil
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        default:
            break
        }
    }

    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(object: Player, changedForType type: ManagedObjectChangeType) {
        validatePlayer()
    }

}

// MARK: -

class PlayerNameCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var textField: UITextField!
    
    var player: Player! {
        didSet {
            textField.text = player.name
        }
    }
    
    var editingTable = false

    @IBAction func textFieldEditingChanged(sender: UITextField) {
        player.name = sender.text!
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return editingTable
    }

}

class PlayerPlayerNameCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var textField: UITextField!

    var player: Player! {
        didSet {
            textField.text = player.playerName
        }
    }

    var editingTable = false

    @IBAction func textFieldEditingChanged(sender: UITextField) {
        player.playerName = sender.text!
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return editingTable
    }
    
}

class PlayerRaceCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    
    var player: Player! {
        didSet {
            if let _ = player.primitiveValueForKey("rawRace") {
                label.text = player.race.stringValue
                label.textColor = UIColor.blackColor()
            } else {
                label.text = "Race"
                label.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .DisclosureIndicator : .None
            selectionStyle = editingTable ? .Default : .None
        }
    }
    
}

class PlayerCharacterClassCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if let _ = player.primitiveValueForKey("rawCharacterClass") {
                label.text = player.characterClass.stringValue
                label.textColor = UIColor.blackColor()
            } else {
                label.text = "Class"
                label.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .DisclosureIndicator : .None
            selectionStyle = editingTable ? .Default : .None
        }
    }

}

class PlayerBackgroundCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if let _ = player.primitiveValueForKey("rawBackground") {
                label.text = player.background.stringValue
                label.textColor = UIColor.blackColor()
            } else {
                label.text = "Background"
                label.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .DisclosureIndicator : .None
            selectionStyle = editingTable ? .Default : .None
        }
    }

}

class PlayerAlignmentCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if let _ = player.primitiveValueForKey("rawAlignment") {
                label?.text = player.alignment.stringValue
                label?.textColor = UIColor.blackColor()
            } else {
                label?.text = "Alignment"
                label?.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .DisclosureIndicator : .None
            selectionStyle = editingTable ? .Default : .None
        }
    }

}

class PlayerXPCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var xpCaptionLabel: UILabel?
    @IBOutlet var xpLabel: UILabel?
    @IBOutlet var levelCaptionLabel: UILabel?
    @IBOutlet var levelLabel: UILabel?
    @IBOutlet var captionLabel: UILabel?
    @IBOutlet var textField: UITextField?
    
    var player: Player! {
        didSet {
            xpLabel?.text = player.xpString
            levelLabel?.text = "\(player.level)"

            textField?.text = "\(player.xp)"
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let label = xpCaptionLabel {
            label.textColor = tintColor
        }
        if let label = levelCaptionLabel {
            label.textColor = tintColor
        }
        if let label = captionLabel {
            label.textColor = tintColor
        }
    }
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        if let text = sender.text where text != "" {
            player.xp = Int(text)!
        } else {
            player.xp = 0
        }
    }
    
    @IBAction func textFieldEditingDidEnd(sender: UITextField) {
        sender.text = "\(player.xp)"
    }
    
    // MARK: UITextFieldDelegate

    func textFieldShouldClear(textField: UITextField) -> Bool {
        return player.inserted && player.xp == 0
    }

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

class PlayerPassivePerceptionCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var captionLabel: UILabel!
    @IBOutlet var label: UILabel?
    @IBOutlet var textField: UITextField?
    
    var player: Player! {
        didSet {
            label?.text = "\(player.passivePerception)"
            textField?.text = "\(player.passivePerception)"
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        captionLabel.textColor = tintColor
    }

    @IBAction func textFieldEditingChanged(sender: UITextField) {
        if let text = sender.text where text != "" {
            player.passivePerception = Int(text)!
        } else {
            player.passivePerception = 10
        }
    }

    @IBAction func textFieldEditingDidEnd(sender: UITextField) {
        sender.text = "\(player.passivePerception)"
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldClear(textField: UITextField) -> Bool {
        return player.inserted && player.passivePerception == 10
    }
    
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

class PlayerSavingThrowCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var playerSavingThrow: PlayerSavingThrow! {
        didSet {
            label.text = playerSavingThrow.savingThrow.stringValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }
    
}

class AddPlayerSavingThrowCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        label.textColor = tintColor
    }

}

class PlayerSkillCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var playerSkill: PlayerSkill! {
        didSet {
            label.text = playerSkill.skill.longStringValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }
    
}

class AddPlayerSkillCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        label.textColor = tintColor
    }

}

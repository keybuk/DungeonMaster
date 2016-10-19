//
//  PlayerViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class PlayerViewController : UITableViewController, ManagedObjectObserverDelegate {
    
    /// Player to be edited.
    var player: Player!
    
    /// Block to execute when editing is complete.
    var completionBlock: ((_ cancelled: Bool, _ player: Player?) -> Void)?

    @IBOutlet var cancelButtonItem: UIBarButtonItem!

    var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        // When called with a new player, immediately enter editing mode.
        if player.isInserted {
            setEditing(true, animated: false)
        }
        
        // If presented modally, add a cancel button.
        if let _ = presentingViewController {
            navigationItem.leftBarButtonItem = cancelButtonItem
        }
    
        observer = ManagedObjectObserver(object: player, delegate: self)
    }
    
    var nameBecomesFirstResponder = true
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // On first appearance with a new player, make the name field the first responder. We only do this once because we don't want to do it coming back from selecting things like race, class, etc.
        if player.isInserted && nameBecomesFirstResponder {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PlayerNameCell {
                cell.textField.becomeFirstResponder()
                nameBecomesFirstResponder = false
            }
        }
    }
    
    /// Validate whether the player can be saved in its current state.
    ///
    /// Updates the "Done" button item to be enabled or disabled appropriately.
    func validatePlayer() {
        guard isEditing else { return }

        do {
            if player.isInserted {
                try player.validateForInsert()
            } else {
                try player.validateForUpdate()
            }
            
            navigationItem.rightBarButtonItem?.isEnabled = true
        } catch {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let oldEditing = self.isEditing, tableViewLoaded = self.tableViewLoaded
        super.setEditing(editing, animated: animated)

        // Only update the table when the editing state is actually changing, and if the table view data was loaded prior to the view being set to editing.
        if editing != oldEditing && tableViewLoaded {
            // Insert/remove the "add saving throws/skills" row.
            let savingThrowsIndexPath = IndexPath(row: player.savingThrows.count, section: 3)
            let skillsIndexPath = IndexPath(row: player.skills.count, section: 4)
            if editing {
                tableView.insertRows(at: [savingThrowsIndexPath, skillsIndexPath], with: .automatic)
            } else {
                tableView.deleteRows(at: [savingThrowsIndexPath, skillsIndexPath], with: .automatic)
            }
            
            // Toggle the editingTable state of the text and selection rows.
            let nameIndexPath = IndexPath(row: 0, section: 0)
            if let cell = tableView.cellForRow(at: nameIndexPath) as? PlayerNameCell {
                cell.editingTable = editing
            }
            
            let playerNameIndexPath = IndexPath(row: 1, section: 0)
            if let cell = tableView.cellForRow(at: playerNameIndexPath) as? PlayerPlayerNameCell {
                cell.editingTable = editing
            }

            let raceIndexPath = IndexPath(row: 0, section: 1)
            if let cell = tableView.cellForRow(at: raceIndexPath) as? PlayerRaceCell {
                cell.editingTable = editing
            }

            let characterClassIndexPath = IndexPath(row: 1, section: 1)
            if let cell = tableView.cellForRow(at: characterClassIndexPath) as? PlayerCharacterClassCell {
                cell.editingTable = editing
            }

            let backgroundIndexPath = IndexPath(row: 2, section: 1)
            if let cell = tableView.cellForRow(at: backgroundIndexPath) as? PlayerBackgroundCell {
                cell.editingTable = editing
            }

            let alignmentIndexPath = IndexPath(row: 3, section: 1)
            if let cell = tableView.cellForRow(at: alignmentIndexPath) as? PlayerAlignmentCell {
                cell.editingTable = editing
            }
            
            // Reload the XP/PP section with a fade so that it appears the table is just changing.
            tableView.beginUpdates()
            let xpIndexPath = IndexPath(row: 0, section: 2)
            let ppIndexPath = IndexPath(row: 1, section: 2)
            tableView.deleteRows(at: [xpIndexPath, ppIndexPath], with: .fade)
            tableView.insertRows(at: [xpIndexPath, ppIndexPath], with: .fade)
            tableView.endUpdates()
        }

        if editing {
            // Make sure the "Done" button is disabled if the player can't be immediately saved.
            validatePlayer()
        }
        if oldEditing && !editing {
            try! managedObjectContext.save()
            completionBlock?(false, player)
        }
    }

    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Selecting one of the options should be equivalent to changing edit field, so resign the responder status from any existing edit field.
        tableView.endEditing(false)

        if segue.identifier == "RaceSegue" {
            let viewController = segue.destination as! RaceViewController
            if let _ = player.primitiveValue(forKey: "rawRace") {
                viewController.selectedRace = player.race
            }
        } else if segue.identifier == "CharacterClassSegue" {
            let viewController = segue.destination as! CharacterClassViewController
            if let _ = player.primitiveValue(forKey: "rawCharacterClass") {
                viewController.selectedCharacterClass = player.characterClass
            }
        } else if segue.identifier == "BackgroundSegue" {
            let viewController = segue.destination as! BackgroundViewController
            if let _ = player.primitiveValue(forKey: "rawBackground") {
                viewController.selectedBackground = player.background
            }
        } else if segue.identifier == "AlignmentSegue" {
            let viewController = segue.destination as! AlignmentViewController
            if let _ = player.primitiveValue(forKey: "rawAlignment") {
                viewController.selectedAlignment = player.alignment
            }
        } else if segue.identifier == "AddSavingThrowSegue" {
            let viewController = segue.destination as! SavingThrowViewController
            viewController.existingSavingThrows = player.savingThrows.map({ ($0 as! PlayerSavingThrow).savingThrow })
        } else if segue.identifier == "AddSkillSegue" {
            let viewController = segue.destination as! SkillViewController
            viewController.existingSkills = player.skills.map({ ($0 as! PlayerSkill).skill })
        }
    }
    
    @IBAction func unwindFromRace(_ segue: UIStoryboardSegue) {
        let viewController = segue.source as! RaceViewController
        player.race = viewController.selectedRace!
        
        let indexPath = IndexPath(row: 0, section: 1)
        if let cell = tableView.cellForRow(at: indexPath) as? PlayerRaceCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromCharacterClass(_ segue: UIStoryboardSegue) {
        let viewController = segue.source as! CharacterClassViewController
        player.characterClass = viewController.selectedCharacterClass!
        
        let indexPath = IndexPath(row: 1, section: 1)
        if let cell = tableView.cellForRow(at: indexPath) as? PlayerCharacterClassCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromBackground(_ segue: UIStoryboardSegue) {
        let viewController = segue.source as! BackgroundViewController
        player.background = viewController.selectedBackground!
        
        let indexPath = IndexPath(row: 2, section: 1)
        if let cell = tableView.cellForRow(at: indexPath) as? PlayerBackgroundCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromAlignment(_ segue: UIStoryboardSegue) {
        let viewController = segue.source as! AlignmentViewController
        player.alignment = viewController.selectedAlignment!
        
        let indexPath = IndexPath(row: 3, section: 1)
        if let cell = tableView.cellForRow(at: indexPath) as? PlayerAlignmentCell {
            cell.player = player
        }
    }
    
    @IBAction func unwindFromSavingThrow(_ segue: UIStoryboardSegue) {
        let viewController = segue.source as! SavingThrowViewController
        
        var newSavingThrows: [PlayerSavingThrow] = []
        for selectedSavingThrow in viewController.selectedSavingThrows {
            let savingThrow = PlayerSavingThrow(player: player, savingThrow: selectedSavingThrow, insertInto: managedObjectContext)
            newSavingThrows.append(savingThrow)
        }
        
        sortedSavingThrows = nil

        let indexPaths = newSavingThrows.map({ IndexPath(row: sortedSavingThrows.index(of: $0)!, section: 3) })
        tableView.insertRows(at: indexPaths, with: .top)
    }
    
    @IBAction func unwindFromSkill(_ segue: UIStoryboardSegue) {
        let viewController = segue.source as! SkillViewController
        
        var newSkills: [PlayerSkill] = []
        for selectedSkill in viewController.selectedSkills {
            let skill = PlayerSkill(player: player, skill: selectedSkill, insertInto: managedObjectContext)
            newSkills.append(skill)
        }
        
        sortedSkills = nil
        
        let indexPaths = newSkills.map({ IndexPath(row: sortedSkills.index(of: $0)!, section: 4) })
        tableView.insertRows(at: indexPaths, with: .top)
    }

    // MARK: Actions

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        if player.isInserted {
            managedObjectContext.delete(player)
        } else {
            managedObjectContext.refresh(player, mergeChanges: false)
        }

        completionBlock?(true, nil)
    }
    
    // MARK: Caching for relationships
    
    var sortedSavingThrows: [PlayerSavingThrow]! {
        get {
            if _sortedSavingThrows == nil {
                let sortDescriptor = NSSortDescriptor(key: "rawSavingThrow", ascending: true)
                _sortedSavingThrows = player.savingThrows.sortedArray(using: [ sortDescriptor ]).map({ $0 as! PlayerSavingThrow })
            }
            
            return _sortedSavingThrows!
        }
        
        set(newSortedSavingThrows) {
            _sortedSavingThrows = newSortedSavingThrows
        }
    }
    fileprivate var _sortedSavingThrows: [PlayerSavingThrow]?
    
    var sortedSkills: [PlayerSkill]! {
        get {
            if _sortedSkills == nil {
                let abilitySortDescriptor = NSSortDescriptor(key: "rawAbility", ascending: true)
                let skillSortDescriptor = NSSortDescriptor(key: "rawSkill", ascending: true)
                _sortedSkills = player.skills.sortedArray(using: [ abilitySortDescriptor, skillSortDescriptor ]).map({ $0 as! PlayerSkill })
            }
            
            return _sortedSkills!
        }
        
        set(newSortedSkills) {
            _sortedSkills = newSortedSkills
        }
    }
    fileprivate var _sortedSkills: [PlayerSkill]?
    
    // MARK: UITableViewDataSource
    
    var tableViewLoaded = false
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableViewLoaded = true
        return 5
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
            return player.savingThrows.count + (isEditing ? 1 : 0)
        case 4:
            // Skills
            return player.skills.count + (isEditing ? 1 : 0)
        default:
            abort()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath as NSIndexPath).section {
        case 0:
            switch (indexPath as NSIndexPath).row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerNameCell", for: indexPath) as! PlayerNameCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = isEditing
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerPlayerNameCell", for: indexPath) as! PlayerPlayerNameCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = isEditing
                return cell
            default:
                abort()
            }
        case 1:
            switch (indexPath as NSIndexPath).row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerRaceCell", for: indexPath) as! PlayerRaceCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = isEditing
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCharacterClassCell", for: indexPath) as! PlayerCharacterClassCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = isEditing
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerBackgroundCell", for: indexPath) as! PlayerBackgroundCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = isEditing
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerAlignmentCell", for: indexPath) as! PlayerAlignmentCell
                cell.player = player
                // Cell is not editable itself, so inform it whether or not the table is.
                cell.editingTable = isEditing
                return cell
            default:
                abort()
            }
        case 2:
            switch (indexPath as NSIndexPath).row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: isEditing ? "EditPlayerXPCell" : "PlayerXPCell", for: indexPath) as! PlayerXPCell
                cell.player = player
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: isEditing ? "EditPlayerPassivePerceptionCell" : "PlayerPassivePerceptionCell", for: indexPath) as! PlayerPassivePerceptionCell
                cell.player = player
                return cell
            default:
                abort()
            }
        case 3:
            switch (indexPath as NSIndexPath).row {
            case player.savingThrows.count:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddPlayerSavingThrowCell", for: indexPath)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerSavingThrowCell", for: indexPath) as! PlayerSavingThrowCell
                cell.playerSavingThrow = sortedSavingThrows[(indexPath as NSIndexPath).row]
                return cell
            }
        case 4:
            switch (indexPath as NSIndexPath).row {
            case player.skills.count:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddPlayerSkillCell", for: indexPath)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerSkillCell", for: indexPath) as! PlayerSkillCell
                cell.playerSkill = sortedSkills[(indexPath as NSIndexPath).row]
                return cell
            }
        default:
            abort()
        }
    }
    
    // MARK: Editing support
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch (indexPath as NSIndexPath).section {
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
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if isEditing {
            return indexPath
        } else {
            return nil
        }
    }
    
    // MARK: Editing support
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        switch (indexPath as NSIndexPath).section {
        case 0, 1, 2:
            return .none
        case 3:
            switch (indexPath as NSIndexPath).row {
            case player.savingThrows.count:
                return .insert
            default:
                return .delete
            }
        case 4:
            switch (indexPath as NSIndexPath).row {
            case player.skills.count:
                return .insert
            default:
                return .delete
            }
        default:
            abort()
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        switch (indexPath as NSIndexPath).section {
        case 0, 1, 2:
            break
        case 3:
            switch (indexPath as NSIndexPath).row {
            case player.savingThrows.count:
                break
            default:
                let savingThrow = sortedSavingThrows[(indexPath as NSIndexPath).row]
                
                // FIXME this is a hack because we're not using a real fetched results controller.
                player.mutableSetValue(forKey: "savingThrows").remove(savingThrow)
                managedObjectContext.delete(savingThrow)

                sortedSavingThrows = nil
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case 4:
            switch (indexPath as NSIndexPath).row {
            case player.skills.count:
                break
            default:
                let skill = sortedSkills[(indexPath as NSIndexPath).row]
                
                // FIXME this is a hack because we're not using a real fetched results controller.
                player.mutableSetValue(forKey: "skills").remove(skill)
                managedObjectContext.delete(skill)
                
                sortedSkills = nil
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        default:
            break
        }
    }

    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(_ object: Player, changedForType type: ManagedObjectChangeType) {
        validatePlayer()
    }

}

// MARK: -

class PlayerNameCell : UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var textField: UITextField!
    
    var player: Player! {
        didSet {
            textField.text = player.name
        }
    }
    
    var editingTable = false

    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        player.name = sender.text!
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return editingTable
    }

}

class PlayerPlayerNameCell : UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var textField: UITextField!

    var player: Player! {
        didSet {
            textField.text = player.playerName
        }
    }

    var editingTable = false

    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        player.playerName = sender.text!
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return editingTable
    }
    
}

class PlayerRaceCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!
    
    var player: Player! {
        didSet {
            if let _ = player.primitiveValue(forKey: "rawRace") {
                label.text = player.race.stringValue
                label.textColor = UIColor.black
            } else {
                label.text = "Race"
                label.textColor = UIColor.lightGray
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .disclosureIndicator : .none
            selectionStyle = editingTable ? .default : .none
        }
    }
    
}

class PlayerCharacterClassCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if let _ = player.primitiveValue(forKey: "rawCharacterClass") {
                label.text = player.characterClass.stringValue
                label.textColor = UIColor.black
            } else {
                label.text = "Class"
                label.textColor = UIColor.lightGray
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .disclosureIndicator : .none
            selectionStyle = editingTable ? .default : .none
        }
    }

}

class PlayerBackgroundCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if let _ = player.primitiveValue(forKey: "rawBackground") {
                label.text = player.background.stringValue
                label.textColor = UIColor.black
            } else {
                label.text = "Background"
                label.textColor = UIColor.lightGray
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .disclosureIndicator : .none
            selectionStyle = editingTable ? .default : .none
        }
    }

}

class PlayerAlignmentCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if let _ = player.primitiveValue(forKey: "rawAlignment") {
                label?.text = player.alignment.stringValue
                label?.textColor = UIColor.black
            } else {
                label?.text = "Alignment"
                label?.textColor = UIColor.lightGray
            }
        }
    }
    
    var editingTable = false {
        didSet {
            accessoryType = editingTable ? .disclosureIndicator : .none
            selectionStyle = editingTable ? .default : .none
        }
    }

}

class PlayerXPCell : UITableViewCell, UITextFieldDelegate {
    
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
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if let text = sender.text, text != "" {
            player.xp = Int(text)!
        } else {
            player.xp = 0
        }
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        sender.text = "\(player.xp)"
    }
    
    // MARK: UITextFieldDelegate

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return player.isInserted && player.xp == 0
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let validSet = CharacterSet.decimalDigits
        for character in string.unicodeScalars {
            if !validSet.contains(UnicodeScalar(character.value)!) {
                return false
            }
        }
        return true
    }

}

class PlayerPassivePerceptionCell : UITableViewCell, UITextFieldDelegate {
    
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

    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if let text = sender.text, text != "" {
            player.passivePerception = Int(text)!
        } else {
            player.passivePerception = 10
        }
    }

    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        sender.text = "\(player.passivePerception)"
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return player.isInserted && player.passivePerception == 10
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let validSet = CharacterSet.decimalDigits
        for character in string.unicodeScalars {
            if !validSet.contains(UnicodeScalar(character.value)!) {
                return false
            }
        }
        return true
    }
    
}

class PlayerSavingThrowCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var playerSavingThrow: PlayerSavingThrow! {
        didSet {
            label.text = playerSavingThrow.savingThrow.stringValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }
    
}

class AddPlayerSavingThrowCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        label.textColor = tintColor
    }

}

class PlayerSkillCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var playerSkill: PlayerSkill! {
        didSet {
            label.text = playerSkill.skill.longStringValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = isEditing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }
    
}

class AddPlayerSkillCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        label.textColor = tintColor
    }

}

//
//  PlayerViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class PlayerViewController: UITableViewController {
    
    @IBOutlet var cancelButtonItem: UIBarButtonItem!

    /// Player to be edited.
    var player: Player!
    
    /// When true, the player name field becomes the first responder when the view appears.
    var playerNameBecomesFirstResponder = false

    var notificationObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Monitor changes in the object to enable/disable the "Done" button based on its validity.
        notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: nil) { notification in
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
                if updatedObjects.containsObject(self.player) {
                    self.validatePlayer()
                }
            }
        }
        
        validatePlayer()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if playerNameBecomesFirstResponder {
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? PlayerNameCell {
                cell.textField.becomeFirstResponder()
            }
            playerNameBecomesFirstResponder = false
        }
    }
    
    var pushToSubview = false
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if tableView.editing && !pushToSubview {
            if validatePlayer() {
                saveContext()
            } else {
                undoChanges()
            }
        }
        
        pushToSubview = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        if let notificationObserver = notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(notificationObserver)
        }
    }
    
    // MARK: Caching for relationships

    var sortedSavingThrows: [PlayerSavingThrow] {
        if _sortedSavingThrows == nil {
            let sortDescriptor = NSSortDescriptor(key: "rawSavingThrow", ascending: true)
            _sortedSavingThrows = player.savingThrows.sortedArrayUsingDescriptors([ sortDescriptor ]).map({ $0 as! PlayerSavingThrow })
        }
        
        return _sortedSavingThrows!
    }
    var _sortedSavingThrows: [PlayerSavingThrow]?
    
    var sortedSkills: [PlayerSkill] {
        if _sortedSkills == nil {
            let abilitySortDescriptor = NSSortDescriptor(key: "rawAbility", ascending: true)
            let skillSortDescriptor = NSSortDescriptor(key: "rawSkill", ascending: true)
            _sortedSkills = player.skills.sortedArrayUsingDescriptors([ abilitySortDescriptor, skillSortDescriptor ]).map({ $0 as! PlayerSkill })
        }
        
        return _sortedSkills!
    }
    var _sortedSkills: [PlayerSkill]?
    
    // MARK: Edit handling

    var oldLeftBarButtonItem: UIBarButtonItem?
    var oldLeftItemsSupplementBackButton: Bool?
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.beginUpdates()
        
        let savingThrowsIndexPath = NSIndexPath(forRow: player.savingThrows.count, inSection: 3)
        let skillsIndexPath = NSIndexPath(forRow: player.skills.count, inSection: 4)
        if editing {
            tableView.insertRowsAtIndexPaths([savingThrowsIndexPath, skillsIndexPath], withRowAnimation: .Fade)
        } else {
            tableView.deleteRowsAtIndexPaths([savingThrowsIndexPath, skillsIndexPath], withRowAnimation: .Fade)
        }
        
        tableView.endUpdates()
        
        tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, 3)), withRowAnimation: .Fade)
        
        if editing {
            oldLeftBarButtonItem = navigationItem.leftBarButtonItem
            oldLeftItemsSupplementBackButton = navigationItem.leftItemsSupplementBackButton

            navigationItem.leftBarButtonItem = cancelButtonItem
            navigationItem.leftItemsSupplementBackButton = false
        } else {
            navigationItem.leftBarButtonItem = oldLeftBarButtonItem
            navigationItem.leftItemsSupplementBackButton = oldLeftItemsSupplementBackButton!
            
            saveContext()
        }
    }

    func validatePlayer() -> Bool {
        do {
            if player.inserted {
                try player.validateForInsert()
            } else {
                try player.validateForUpdate()
            }
            
            navigationItem.rightBarButtonItem?.enabled = true
            return true
        } catch {
            navigationItem.rightBarButtonItem?.enabled = false
            return false
        }
    }
    
    func undoChanges() {
        if player.inserted {
            managedObjectContext.deleteObject(player)
        } else {
            managedObjectContext.refreshObject(player, mergeChanges: false)
        }
    }
    
    @IBAction func cancelButton(sender: UIBarButtonItem) {
        undoChanges()
        setEditing(false, animated: true)
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        pushToSubview = true
        
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? PlayerNameCell {
            cell.textField.resignFirstResponder()
        }
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as? PlayerPlayerNameCell {
            cell.textField.resignFirstResponder()
        }
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as? PlayerXPCell {
            cell.textField.resignFirstResponder()
        }
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 2)) as? PlayerPassivePerceptionCell {
            cell.textField.resignFirstResponder()
        }

        if segue.identifier == "PlayerRaceSegue" {
            let playerRaceViewController = segue.destinationViewController as! PlayerRaceViewController
            if player.primitiveValueForKey("rawRace") != nil {
                playerRaceViewController.selectedRace = player.race
            }
        } else if segue.identifier == "PlayerCharacterClassSegue" {
            let playerCharacterClassViewController = segue.destinationViewController as! PlayerCharacterClassViewController
            if player.primitiveValueForKey("rawCharacterClass") != nil {
                playerCharacterClassViewController.selectedCharacterClass = player.characterClass
            }
        } else if segue.identifier == "PlayerBackgroundSegue" {
            let playerBackgroundViewController = segue.destinationViewController as! PlayerBackgroundViewController
            if player.primitiveValueForKey("rawBackground") != nil {
                playerBackgroundViewController.selectedBackground = player.background
            }
        } else if segue.identifier == "PlayerAlignmentSegue" {
            let playerAlignmentViewController = segue.destinationViewController as! PlayerAlignmentViewController
            if player.primitiveValueForKey("rawAlignment") != nil {
                playerAlignmentViewController.selectedAlignment = player.alignment
            }
        } else if segue.identifier == "AddPlayerSavingThrowSegue" {
            let playerSavingThrowViewController = segue.destinationViewController as! PlayerSavingThrowViewController
            playerSavingThrowViewController.player = player
        } else if segue.identifier == "AddPlayerSkillSegue" {
            let playerSkillViewController = segue.destinationViewController as! PlayerSkillViewController
            playerSkillViewController.player = player
        }
    }
    
    @IBAction func unwindFromPlayerRace(segue: UIStoryboardSegue) {
        let playerRaceViewController = segue.sourceViewController as! PlayerRaceViewController
        player.race = playerRaceViewController.selectedRace!
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 1)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    @IBAction func unwindFromPlayerCharacterClass(segue: UIStoryboardSegue) {
        let playerCharacterClassViewController = segue.sourceViewController as! PlayerCharacterClassViewController
        player.characterClass = playerCharacterClassViewController.selectedCharacterClass!
        
        let indexPath = NSIndexPath(forRow: 1, inSection: 1)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    @IBAction func unwindFromPlayerBackground(segue: UIStoryboardSegue) {
        let playerBackgroundViewController = segue.sourceViewController as! PlayerBackgroundViewController
        player.background = playerBackgroundViewController.selectedBackground!
        
        let indexPath = NSIndexPath(forRow: 2, inSection: 1)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    @IBAction func unwindFromPlayerAlignment(segue: UIStoryboardSegue) {
        let playerAlignmentViewController = segue.sourceViewController as! PlayerAlignmentViewController
        player.alignment = playerAlignmentViewController.selectedAlignment!
        
        let indexPath = NSIndexPath(forRow: 3, inSection: 1)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    @IBAction func unwindFromPlayerSavingThrow(segue: UIStoryboardSegue) {
        let playerSavingThrowViewController = segue.sourceViewController as! PlayerSavingThrowViewController
        
        let savingThrow = PlayerSavingThrow(player: player, savingThrow: playerSavingThrowViewController.selectedSavingThrow!, inManagedObjectContext: managedObjectContext)
        _sortedSavingThrows = nil
        
        let indexPath = NSIndexPath(forRow: sortedSavingThrows.indexOf(savingThrow)!, inSection: 3)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    @IBAction func unwindFromPlayerSkill(segue: UIStoryboardSegue) {
        let playerSkillViewController = segue.sourceViewController as! PlayerSkillViewController
        
        let skill = PlayerSkill(player: player, skill: playerSkillViewController.selectedSkill!, inManagedObjectContext: managedObjectContext)
        _sortedSkills = nil

        let indexPath = NSIndexPath(forRow: sortedSkills.indexOf(skill)!, inSection: 4)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

}

// MARK: UITableViewDataSource
extension PlayerViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
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
            return player.savingThrows.count + (tableView.editing ? 1 : 0)
        case 4:
            // Skills
            return player.skills.count + (tableView.editing ? 1 : 0)
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
                let cell = tableView.dequeueReusableCellWithIdentifier(tableView.editing ? "EditPlayerNameCell" : "PlayerNameCell", forIndexPath: indexPath) as! PlayerNameCell
                cell.player = player
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier(tableView.editing ? "EditPlayerPlayerNameCell" : "PlayerPlayerNameCell", forIndexPath: indexPath) as! PlayerPlayerNameCell
                cell.player = player
                return cell
            default:
                abort()
            }
        case 1:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerRaceCell", forIndexPath: indexPath) as! PlayerRaceCell
                cell.player = player
                cell.accessoryType = editing ? .DisclosureIndicator : .None
                cell.selectionStyle = editing ? .Default : .None
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerCharacterClassCell", forIndexPath: indexPath) as! PlayerCharacterClassCell
                cell.player = player
                cell.accessoryType = editing ? .DisclosureIndicator : .None
                cell.selectionStyle = editing ? .Default : .None
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerBackgroundCell", forIndexPath: indexPath) as! PlayerBackgroundCell
                cell.player = player
                cell.accessoryType = editing ? .DisclosureIndicator : .None
                cell.selectionStyle = editing ? .Default : .None
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("PlayerAlignmentCell", forIndexPath: indexPath) as! PlayerAlignmentCell
                cell.player = player
                cell.accessoryType = editing ? .DisclosureIndicator : .None
                cell.selectionStyle = editing ? .Default : .None
                return cell
            default:
                abort()
            }
        case 2:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier(tableView.editing ? "EditPlayerXPCell" : "PlayerXPCell", forIndexPath: indexPath) as! PlayerXPCell
                cell.player = player
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier(tableView.editing ? "EditPlayerPassivePerceptionCell" : "PlayerPassivePerceptionCell", forIndexPath: indexPath) as! PlayerPassivePerceptionCell
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
            return false
        case 3, 4:
            return true
        default:
            abort()
        }
    }
    
}

// MARK: UITableViewDelegate
extension PlayerViewController {
    
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
                
                player.mutableSetValueForKey("savingThrows").removeObject(savingThrow)
                managedObjectContext.deleteObject(savingThrow)

                _sortedSavingThrows = nil
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case 4:
            switch indexPath.row {
            case player.skills.count:
                break
            default:
                let skill = sortedSkills[indexPath.row]
                
                player.mutableSetValueForKey("skills").removeObject(skill)
                managedObjectContext.deleteObject(skill)
                
                _sortedSkills = nil
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        default:
            break
        }
    }

}

// MARK: -

class PlayerNameCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextField!
    
    var player: Player! {
        didSet {
            label?.text = player.name
            textField?.text = player.name
        }
    }

    @IBAction func textFieldEditingChanged(sender: UITextField) {
        player.name = sender.text!
    }

}

class PlayerPlayerNameCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextField!

    var player: Player! {
        didSet {
            label?.text = player.playerName
            textField?.text = player.playerName
        }
    }

    @IBAction func textFieldEditingChanged(sender: UITextField) {
        player.playerName = sender.text!
    }
    
}

class PlayerRaceCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    
    var player: Player! {
        didSet {
            if player.primitiveValueForKey("rawRace") != nil {
                label?.text = player.race.stringValue
                label?.textColor = UIColor.blackColor()
            } else {
                label?.text = "Race"
                label?.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
}

class PlayerCharacterClassCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if player.primitiveValueForKey("rawCharacterClass") != nil {
                label?.text = player.characterClass.stringValue
                label?.textColor = UIColor.blackColor()
            } else {
                label?.text = "Class"
                label?.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
}

class PlayerBackgroundCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if player.primitiveValueForKey("rawBackground") != nil {
                label?.text = player.background.stringValue
                label?.textColor = UIColor.blackColor()
            } else {
                label?.text = "Background"
                label?.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
}

class PlayerAlignmentCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!

    var player: Player! {
        didSet {
            if player.primitiveValueForKey("rawAlignment") != nil {
                label?.text = player.alignment.stringValue
                label?.textColor = UIColor.blackColor()
            } else {
                label?.text = "Alignment"
                label?.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
}

class PlayerXPCell: UITableViewCell {
    
    @IBOutlet var xpLabel: UILabel!
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet var textField: UITextField!
    
    var player: Player! {
        didSet {
            let xpFormatter = NSNumberFormatter()
            xpFormatter.numberStyle = .DecimalStyle
            
            let xpString = xpFormatter.stringFromNumber(player.XP)!
            xpLabel?.text = xpString

            levelLabel?.text = "\(player.level)"
            
            textField?.text = "\(player.XP)"
        }
    }
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        if sender.text! == "" {
            player.XP = 0
        } else {
            player.XP = Int(sender.text!)!
        }
    }
    
    @IBAction func textFieldEditingDidEnd(sender: UITextField) {
        sender.text = "\(player.XP)"
    }

}

extension PlayerXPCell: UITextFieldDelegate {
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return player.inserted && player.XP == 0
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

class PlayerPassivePerceptionCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextField!
    
    var player: Player! {
        didSet {
            label?.text = "\(player.passivePerception)"
            textField?.text = "\(player.passivePerception)"
        }
    }

    @IBAction func textFieldEditingChanged(sender: UITextField) {
        if sender.text! == "" {
            player.passivePerception = 10
        } else {
            player.passivePerception = Int(sender.text!)!
        }
    }

    @IBAction func textFieldEditingDidEnd(sender: UITextField) {
        sender.text = "\(player.passivePerception)"
    }

}

extension PlayerPassivePerceptionCell: UITextFieldDelegate {
    
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
    
    override func setEditing(editing: Bool, animated: Bool) {
        leadingConstraint.constant = editing ? 0.0 : 7.0
        super.setEditing(editing, animated: animated)
    }
    
    var playerSavingThrow: PlayerSavingThrow! {
        didSet {
            label?.text = playerSavingThrow.savingThrow.stringValue
        }
    }

}

class PlayerSkillCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    override func setEditing(editing: Bool, animated: Bool) {
        leadingConstraint.constant = editing ? 0.0 : 7.0
        super.setEditing(editing, animated: animated)
    }

    var playerSkill: PlayerSkill! {
        didSet {
            label?.text = playerSkill.skill.longStringValue
        }
    }

}

//
//  CombatantViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class CombatantViewController: UITableViewController {

    /// The encounter combatant being shown and manipulated.
    var combatant: Combatant!
    
    var notificationObserver: NSObjectProtocol?
    
    var ignoreNextUpdate = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = self.editButtonItem()

        notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: nil) { notification in
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
                if updatedObjects.containsObject(self.combatant) {
                    self.combatantUpdated()
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.toolbarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.toolbarHidden = true
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
    
    // MARK: Data handling.
    
    func combatantUpdated() {
        if !ignoreNextUpdate {
            tableView.reloadData()
        }
        ignoreNextUpdate = false
    }

    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MonsterDetailSegue" {
            /*let detailViewController = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            if let index = detailViewController.navigationItem.rightBarButtonItems?.indexOf(detailViewController.addButton) {
                detailViewController.navigationItem.rightBarButtonItems?.removeAtIndex(index)
            }
            detailViewController.monster = combatant.monster*/
        } else if segue.identifier == "RoleSegue" {
            let combatantRoleViewController = segue.destinationViewController as! CombatantRoleViewController
            combatantRoleViewController.role = combatant.role
        }
    }

    @IBAction func unwindFromRole(segue: UIStoryboardSegue) {
        let combatantRoleViewController = segue.sourceViewController as! CombatantRoleViewController
        
        combatant.role = combatantRoleViewController.role!
        saveContext()
    }
    
    @IBAction func unwindFromCondition(segue: UIStoryboardSegue) {
        let conditionViewController = segue.sourceViewController as! ConditionViewController
        
        let _ = CombatantCondition(target: combatant, type: conditionViewController.type!, inManagedObjectContext: managedObjectContext)
        saveContext()
    }

    @IBAction func unwindFromDamage(segue: UIStoryboardSegue) {
        let damageViewController = segue.sourceViewController as! DamageViewController
        
        let damage = CombatantDamage(target: combatant, points: damageViewController.points!, type: damageViewController.type!, inManagedObjectContext: managedObjectContext)
        
        combatant.damagePoints += damage.points
        saveContext()
    }
    
    @IBAction func unwindFromDetail(segue: UIStoryboardSegue) {
    }

    // MARK: Actions
    
    @IBAction func hitPointsEditingChanged(sender: UITextField) {
        if let hitPoints = Int(sender.text!) {
            ignoreNextUpdate = true
            combatant.hitPoints = hitPoints
            saveContext()
            sender.textColor = nil
        } else {
            sender.textColor = UIColor.redColor()
        }
    }

    @IBAction func initiativeEditingChanged(sender: UITextField) {
        if let initiative = Int(sender.text!) {
            ignoreNextUpdate = true
            combatant.initiative = initiative
            saveContext()
            sender.textColor = nil
        } else {
            sender.textColor = UIColor.redColor()
        }
    }
    
}

// MARK: UITableViewDataSource
extension CombatantViewController {
    
    // MARK: Sections
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return combatant.role != .Player ? 4 : 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // Name, Role, Initiative, Hit Points if DM.
            return combatant.role != .Player ? 4 : 3
        case 1:
            return combatant.conditions.count + 1
        case 2 where combatant.role != .Player:
            return combatant.damages.count + 1
        case 2 where combatant.role == .Player, 3 where combatant.role != .Player:
            return 1
        default:
            abort()
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Conditions"
        case 2 where combatant.role != .Player:
            return "Damage"
        case 2 where combatant.role == .Player, 3 where combatant.role != .Player:
            return "Notes"
        default:
            abort()
        }
    }
    
    // MARK: Rows
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("CombatantNameCell", forIndexPath: indexPath) as! CombatantNameCell
                cell.nameLabel.text = combatant.monster != nil ? combatant.monster!.name : combatant.player!.name
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("RoleCell", forIndexPath: indexPath)
                switch combatant.role {
                case .Foe:
                    cell.textLabel?.text = "Foe"
                case .Friend:
                    cell.textLabel?.text = "Friend"
                case .Player:
                    cell.textLabel?.text = "Player"
                }
                if let _ = combatant.monster {
                    cell.accessoryType = .DisclosureIndicator
                } else {
                    cell.accessoryType = .None
                }
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("DiceRollCell", forIndexPath: indexPath) as! DiceRollCell
                if combatant.role != .Player {
                    cell.diceCombo = combatant.monster!.initiativeDice
                } else {
                    cell.diceCombo = nil
                }
                cell.label.text = "Initiative"
                if let initiative = combatant.initiative {
                    cell.textField.text = "\(initiative)"
                } else {
                    cell.textField.text = "—"
                }
                cell.textField.addTarget(self, action: "initiativeEditingChanged:", forControlEvents: .EditingChanged)
                return cell
            case 3 where combatant.role != .Player:
                let cell = tableView.dequeueReusableCellWithIdentifier("DiceRollCell", forIndexPath: indexPath) as! DiceRollCell
                cell.diceCombo = combatant.monster!.hitDice
                cell.label.text = "Hit Points"
                cell.textField.text = "\(combatant.hitPoints)"
                // Should read up on control events and figure out if this is right or not.
                cell.textField.addTarget(self, action: "hitPointsEditingChanged:", forControlEvents: .EditingChanged)
                return cell
            default:
                abort()
            }
        case 1:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("AddConditionCell", forIndexPath: indexPath)
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("CombatantConditionCell", forIndexPath: indexPath) as! CombatantConditionCell
                let condition = combatant.conditions.objectAtIndex(indexPath.row - 1) as! CombatantCondition
                cell.condition = condition
                return cell
            }
        case 2 where combatant.role != .Player:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("AddDamageCell", forIndexPath: indexPath) as! AddDamageCell
                let hitPoints = combatant.hitPoints - combatant.damagePoints
                cell.hitPointsLabel.text = "\(hitPoints)"
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("CombatantDamageCell", forIndexPath: indexPath) as! CombatantDamageCell
                let damageIndex = combatant.damages.count - indexPath.row
                let damage = combatant.damages.objectAtIndex(damageIndex) as! CombatantDamage
                cell.damage = damage
                
                var hitPoints = combatant.hitPoints
                for index in 0..<damageIndex {
                    let damage = combatant.damages.objectAtIndex(index) as! CombatantDamage
                    hitPoints -= damage.points
                }
                hitPoints = max(hitPoints, 0)
                
                cell.hitPointsLabel.attributedText = NSAttributedString(string: "\(hitPoints)", attributes: [NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
                
                return cell
            }
        case 2 where combatant.role == .Player, 3 where combatant.role != .Player:
            let cell = tableView.dequeueReusableCellWithIdentifier("NotesCell", forIndexPath: indexPath) as! NotesCell
            cell.textView.text = combatant.notes
            return cell
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0, 1, 2 where combatant.role != .Player:
            return 44.0
        case 2 where combatant.role == .Player, 3 where combatant.role != .Player:
            return 144.0
        default:
            abort()
        }
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch indexPath.section {
        case 1, 2 where combatant.role != .Player:
            return indexPath.row > 0
        case 0, 2 where combatant.role == .Player, 3 where combatant.role != .Player:
            return false
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 1:
            if indexPath.row > 0 {
                let condition = combatant.conditions.objectAtIndex(indexPath.row - 1) as! CombatantCondition
                managedObjectContext.deleteObject(condition)
                saveContext()
            }
        case 2 where combatant.role != .Player:
            if indexPath.row > 0 {
                let damage = combatant.damages.objectAtIndex(combatant.damages.count - indexPath.row) as! CombatantDamage
                let points = damage.points
                managedObjectContext.deleteObject(damage)
                
                combatant.damagePoints -= points
                saveContext()
            }
        default:
            break
        }
    }

}

// MARK: UITableViewDelegate
extension CombatantViewController {
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 1:
            if indexPath.row > 0 {
                let cell = tableView.cellForRowAtIndexPath(indexPath)! as! CombatantConditionCell
                let condition = cell.condition.type

                
                let conditionRulesViewController = storyboard?.instantiateViewControllerWithIdentifier("ConditionRulesViewController") as! ConditionRulesViewController
                conditionRulesViewController.modalPresentationStyle = .Popover
                
                conditionRulesViewController.popoverPresentationController?.sourceView = cell.contentView
                conditionRulesViewController.popoverPresentationController?.sourceRect = CGRect(x: cell.contentView.frame.size.width, y: 0.0, width: 0.0, height: cell.frame.size.height)

                conditionRulesViewController.condition = condition
                presentViewController(conditionRulesViewController, animated: true, completion: nil)
            }
        default:
            break
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 2, 3 where combatant.role != .Player:
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! DiceRollCell
                cell.textField.becomeFirstResponder()
            default:
                break
            }
        case 1, 2 where combatant.role != .Player:
            // Handled by a segue action in the storyboard.
            break
        case 2 where combatant.role == .Player, 3 where combatant.role != .Player:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! NotesCell
            cell.textView.becomeFirstResponder()
        default:
            break
        }
    }

}

// MARK: UITextViewDelegate
extension CombatantViewController: UITextViewDelegate {
    
    func textViewDidChange(textView: UITextView) {
        ignoreNextUpdate = true
        combatant.notes = textView.text
        saveContext()
    }

}

// MARK: -

class CombatantNameCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    
}

class DiceRollCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextField!
    @IBOutlet var button: UIButton!
    
    var diceCombo: DiceCombo? {
        didSet {
            if let diceCombo = diceCombo {
                button.setTitle("\(diceCombo.description)", forState: .Normal)
                button.hidden = false
            } else {
                button.hidden = true
            }
        }
    }
    
    @IBAction func buttonTapped(sender: UIButton) {
        PlaySound(.Dice)
        diceCombo = diceCombo!.reroll()
        textField.text = "\(diceCombo!.value)"
        // This seems a very hacky way to do this...
        textField.sendActionsForControlEvents(.EditingChanged)
    }
    
}

class NotesCell: UITableViewCell {
    
    @IBOutlet var textView: UITextView!

}

class CombatantConditionCell: UITableViewCell {

    var condition: CombatantCondition! {
        didSet {
            textLabel?.text = condition.type.stringValue
        }
    }

}

class AddDamageCell: UITableViewCell {
    
    @IBOutlet var hitPointsLabel: UILabel!

}

class CombatantDamageCell: UITableViewCell {
    
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var hitPointsLabel: UILabel!
    
    var damage: CombatantDamage! {
        didSet {
            pointsLabel.text = "\(damage.points)"
            typeLabel.text = damage.type.stringValue
        }
    }

}
//
//  CombatantViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import CoreData

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
            let detailViewController = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            if let index = detailViewController.navigationItem.rightBarButtonItems?.indexOf(detailViewController.addButton) {
                detailViewController.navigationItem.rightBarButtonItems?.removeAtIndex(index)
            }
            detailViewController.detailItem = combatant.monster
        }
    }

    @IBAction func unwindFromCondition(segue: UIStoryboardSegue) {
        let conditionViewController = segue.sourceViewController as! ConditionViewController
        
        let _ = Condition(target: combatant, type: conditionViewController.type!, inManagedObjectContext: managedObjectContext)
        saveContext()
    }

    @IBAction func unwindFromDamage(segue: UIStoryboardSegue) {
        let damageViewController = segue.sourceViewController as! DamageViewController
        
        let damage = Damage(target: combatant, points: damageViewController.points!, type: damageViewController.type!, inManagedObjectContext: managedObjectContext)
        
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
    
    enum TableSections: Int {
        case Details
        case Conditions
        case Damages
        case Notes
        case SectionCount
    }
    
    enum TableDetailsRows: Int {
        case MonsterName
        case HitPoints
        case Initiative
        case RowCount
    }
    
    // MARK: Sections
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.SectionCount.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSections(rawValue: section)! {
        case .Details:
            return TableDetailsRows.RowCount.rawValue
        case .Conditions:
            return combatant.conditions.count + 1
        case .Damages:
            return combatant.damages.count + 1
        case .Notes:
            return 1
        default:
            abort()
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch TableSections(rawValue: section)! {
        case .Details:
            return nil
        case .Conditions:
            return "Conditions"
        case .Damages:
            return "Damage"
        case .Notes:
            return "Notes"
        default:
            abort()
        }
    }
    
    // MARK: Rows
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch TableSections(rawValue: indexPath.section)! {
        case .Details:
            let tableRow = TableDetailsRows(rawValue: indexPath.row)!
            switch tableRow {
            case .MonsterName:
                let cell = tableView.dequeueReusableCellWithIdentifier("CombatantNameCell", forIndexPath: indexPath) as! CombatantNameCell
                cell.nameLabel.text = combatant.monster.name
                return cell
            case .HitPoints:
                let cell = tableView.dequeueReusableCellWithIdentifier("DiceRollCell", forIndexPath: indexPath) as! DiceRollCell
                cell.diceCombo = combatant.monster.hitDice
                cell.label.text = "Hit Points"
                cell.textField.text = "\(combatant.hitPoints)"
                // Should read up on control events and figure out if this is right or not.
                cell.textField.addTarget(self, action: "hitPointsEditingChanged:", forControlEvents: .EditingChanged)
                return cell
            case .Initiative:
                let cell = tableView.dequeueReusableCellWithIdentifier("DiceRollCell", forIndexPath: indexPath) as! DiceRollCell
                cell.diceCombo = combatant.monster.initiativeDice
                cell.label.text = "Initiative"
                if let initiative = combatant.initiative {
                    cell.textField.text = "\(initiative)"
                } else {
                    cell.textField.text = "—"
                }
                cell.textField.addTarget(self, action: "initiativeEditingChanged:", forControlEvents: .EditingChanged)
                return cell
            default:
                abort()
            }
        case .Conditions:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("AddConditionCell", forIndexPath: indexPath)
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("ConditionCell", forIndexPath: indexPath) as! ConditionCell
                let condition = combatant.conditions.objectAtIndex(indexPath.row - 1) as! Condition
                cell.condition = condition
                return cell
            }
        case .Damages:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("AddDamageCell", forIndexPath: indexPath) as! AddDamageCell
                let hitPoints = combatant.hitPoints - combatant.damagePoints
                cell.hitPointsLabel.text = "\(hitPoints)"
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("DamageCell", forIndexPath: indexPath) as! DamageCell
                let damageIndex = combatant.damages.count - indexPath.row
                let damage = combatant.damages.objectAtIndex(damageIndex) as! Damage
                cell.damage = damage
                
                var hitPoints = combatant.hitPoints
                for index in 0..<damageIndex {
                    let damage = combatant.damages.objectAtIndex(index) as! Damage
                    hitPoints -= damage.points
                }
                hitPoints = max(hitPoints, 0)
                
                cell.hitPointsLabel.attributedText = NSAttributedString(string: "\(hitPoints)", attributes: [NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
                
                return cell
            }
        case .Notes:
            let cell = tableView.dequeueReusableCellWithIdentifier("NotesCell", forIndexPath: indexPath) as! NotesCell
            cell.textView.text = combatant.notes
            return cell
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch TableSections(rawValue: indexPath.section)! {
        case .Details:
            return 44.0
        case .Conditions:
            return 44.0
        case .Damages:
            return 44.0
        case .Notes:
            return 144.0
        default:
            abort()
        }
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch TableSections(rawValue: indexPath.section)! {
        case .Details:
            return false
        case .Conditions:
            return indexPath.row > 0
        case .Damages:
            return indexPath.row > 0
        case .Notes:
            return false
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch TableSections(rawValue: indexPath.section)! {
        case .Conditions:
            if indexPath.row > 0 {
                let condition = combatant.conditions.objectAtIndex(indexPath.row - 1) as! Condition
                managedObjectContext.deleteObject(condition)
                saveContext()
            } else {
                abort()
            }
        case .Damages:
            if indexPath.row > 0 {
                let damage = combatant.damages.objectAtIndex(combatant.damages.count - indexPath.row) as! Damage
                let points = damage.points
                managedObjectContext.deleteObject(damage)
                
                combatant.damagePoints -= points
                saveContext()
            } else {
                abort()
            }
        default:
            abort()
        }
    }

}

// MARK: UITableViewDelegate
extension CombatantViewController {
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        switch TableSections(rawValue: indexPath.section)! {
        case .Conditions:
            if indexPath.row > 0 {
                let cell = tableView.cellForRowAtIndexPath(indexPath)! as! ConditionCell
                let condition = cell.condition.type

                
                let conditionRulesViewController = storyboard?.instantiateViewControllerWithIdentifier("ConditionRulesViewController") as! ConditionRulesViewController
                conditionRulesViewController.modalPresentationStyle = .Popover
                
                conditionRulesViewController.popoverPresentationController?.sourceView = cell.contentView
                conditionRulesViewController.popoverPresentationController?.sourceRect = CGRect(x: cell.contentView.frame.size.width, y: 0.0, width: 0.0, height: cell.frame.size.height)

                conditionRulesViewController.condition = condition
                presentViewController(conditionRulesViewController, animated: true, completion: nil)
            } else {
                abort()
            }
        default:
            abort()
        }

    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch TableSections(rawValue: indexPath.section)! {
        case .Details:
            let tableRow = TableDetailsRows(rawValue: indexPath.row)!
            switch tableRow {
            case .HitPoints, .Initiative:
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! DiceRollCell
                cell.textField.becomeFirstResponder()
            default:
                break
            }
        case .Conditions:
            // Handled by a segue action in the storyboard.
            break
        case .Damages:
            // Handled by a segue action in the storyboard.
            break
        case .Notes:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! NotesCell
            cell.textView.becomeFirstResponder()
        default:
            abort()
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
    
    var diceCombo: DiceCombo! {
        didSet {
            button.setTitle("\(diceCombo.description)", forState: .Normal)
        }
    }
    
    @IBAction func buttonTapped(sender: UIButton) {
        PlaySound(.Dice)
        diceCombo = diceCombo.reroll()
        textField.text = "\(diceCombo.value)"
        // This seems a very hacky way to do this...
        textField.sendActionsForControlEvents(.EditingChanged)
    }
    
}

class NotesCell: UITableViewCell {
    
    @IBOutlet var textView: UITextView!

}

class ConditionCell: UITableViewCell {

    var condition: Condition! {
        didSet {
            textLabel?.text = condition.type.stringValue
        }
    }

}

class AddDamageCell: UITableViewCell {
    
    @IBOutlet var hitPointsLabel: UILabel!

}

class DamageCell: UITableViewCell {
    
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var hitPointsLabel: UILabel!
    
    var damage: Damage! {
        didSet {
            pointsLabel.text = "\(damage.points)"
            typeLabel.text = damage.type.stringValue
        }
    }

}
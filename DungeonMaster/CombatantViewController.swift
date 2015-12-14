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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: nil) { notification in
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
                if updatedObjects.containsObject(self.combatant) {
                    self.combatantUpdated()
                }
            }
        }
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
        tableView.reloadData()
    }

    // MARK: Navigation

    @IBAction func unwindFromDamage(segue: UIStoryboardSegue) {
        let damageViewController = segue.sourceViewController as! DamageViewController
        
        let damage = Damage(target: combatant, inManagedObjectContext: managedObjectContext)
        damage.points = damageViewController.points!
        damage.type = damageViewController.type!
        
        combatant.damagePoints += damage.points
    }

}

// MARK: UITableViewDataSource
extension CombatantViewController {
    
    enum TableSections: Int {
        case Details
        case Damage
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
        case .Damage:
            return combatant.damage.count + 1
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
        case .Damage:
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
                return cell
            default:
                abort()
            }
        case .Damage:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("AddDamageCell", forIndexPath: indexPath) as! AddDamageCell
                let hitPoints = combatant.hitPoints - combatant.damagePoints
                cell.hitPointsLabel.text = "\(hitPoints)"
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("DamageCell", forIndexPath: indexPath) as! DamageCell
                let damageIndex = combatant.damage.count - indexPath.row
                let damage = combatant.damage.objectAtIndex(damageIndex) as! Damage
                cell.damage = damage
                
                var hitPoints = combatant.hitPoints
                for index in 0..<damageIndex {
                    let damage = combatant.damage.objectAtIndex(index) as! Damage
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
        case .Damage:
            return 44.0
        case .Notes:
            return 144.0
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
        case .Damage:
            // Handled by a segue action in the storyboard.
            break
        case .Notes:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! NotesCell
            cell.textView.becomeFirstResponder()
        default:
            abort()
        }
    }

    // MARK: Edit support
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch TableSections(rawValue: indexPath.section)! {
        case .Details:
            return false
        case .Damage:
            return indexPath.row > 0
        case .Notes:
            return false
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch TableSections(rawValue: indexPath.section)! {
        case .Damage:
            if indexPath.row > 0 {
                let damage = combatant.damage.objectAtIndex(combatant.damage.count - indexPath.row) as! Damage
                let points = damage.points
                managedObjectContext.deleteObject(damage)
                
                combatant.damagePoints -= points
            } else {
                abort()
            }
        default:
            abort()
        }
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
    }
    
}

class NotesCell: UITableViewCell {
    
    @IBOutlet var textView: UITextView!

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
            typeLabel.text = damage.type.rawValue.capitalizedString
        }
    }

}
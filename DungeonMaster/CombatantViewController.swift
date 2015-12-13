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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: UITableViewDataSource
extension CombatantViewController {
    
    enum TableSections: Int {
        case Details
        case Notes
        case SectionCount
    }
    
    enum TableDetailsRows: Int {
        case MonsterName
        case HitPoints
        case Initiative
        case RowCount
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.SectionCount.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSections(rawValue: section)! {
        case .Details:
            return TableDetailsRows.RowCount.rawValue
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
        case .Notes:
            return "Notes"
        default:
            abort()
        }
    }
    
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
                cell.textField.text = "\(combatant.initiative)"
                return cell
            default:
                abort()
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
        case .Notes:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! NotesCell
            cell.textView.becomeFirstResponder()
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
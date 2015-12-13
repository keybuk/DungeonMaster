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
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: nil) { notification in
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
                if updatedObjects.containsObject(self.combatant) {
                    self.combatantUpdated()
                }
            }
        }
    }
    
    deinit {
        if let notificationObserver = notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(notificationObserver)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func combatantUpdated() {
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource
extension CombatantViewController {
    
    enum TableRows: Int {
        case MonsterName
        case HitPoints
        case Initiative
        case RowCount
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return TableRows.RowCount.rawValue
        case 1:
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
            return "Notes"
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let tableRow = TableRows(rawValue: indexPath.row)!
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
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("NotesCell", forIndexPath: indexPath) as! NotesCell
            cell.textView.text = combatant.notes
            return cell
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 44.0
        case 1:
            return 144.0
        default:
            abort()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            let tableRow = TableRows(rawValue: indexPath.row)!
            switch tableRow {
            case .HitPoints, .Initiative:
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! DiceRollCell
                cell.textField.becomeFirstResponder()
            default:
                break
            }
        case 1:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! NotesCell
            cell.textView.becomeFirstResponder()
        default:
            abort()
        }
    }

}

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
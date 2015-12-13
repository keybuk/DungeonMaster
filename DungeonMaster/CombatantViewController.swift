//
//  CombatantViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class CombatantViewController: UITableViewController {

    /// The encounter combatant being shown and manipulated.
    var combatant: Combatant!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableRows.RowCount.rawValue
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
            cell.diceCombo = try! DiceCombo(description: "1d20 + \(combatant.monster.dexterityModifier)") // modifier can be negative, use a better init
            cell.label.text = "Initiative"
            cell.textField.text = "\(combatant.initiative)"
            return cell
        default:
            abort()
        }
    }
    
    /*override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }*/
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tableRow = TableRows(rawValue: indexPath.row)!
        switch tableRow {
        case .HitPoints, .Initiative:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! DiceRollCell
            cell.textField.becomeFirstResponder()
        default:
            break
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
        DiceRollSound()
        diceCombo = diceCombo.reroll()
        textField.text = "\(diceCombo.value)"
    }
    
}
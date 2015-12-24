//
//  PlayerSavingThrowViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class PlayerSavingThrowViewController: UITableViewController {
    
    var player: Player!
    var selectedSavingThrow: Ability?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UITableViewDataSource
extension PlayerSavingThrowViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Ability.cases.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SavingThrowCell", forIndexPath: indexPath)
        
        let ability = Ability(rawValue: indexPath.row)!
        
        cell.textLabel?.text = ability.stringValue
    
        if player.isProficient(savingThrow: ability) {
            cell.accessoryType = .Checkmark
            cell.textLabel?.enabled = false
        } else {
            cell.accessoryType = .None
            cell.textLabel?.enabled = true
        }
        
        return cell
    }
    
}

// MARK: UITableViewDelegate
extension PlayerSavingThrowViewController {
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let ability = Ability(rawValue: indexPath.row)!
        if player.isProficient(savingThrow: ability) {
            return nil
        } else {
            selectedSavingThrow = Ability(rawValue: indexPath.row)!
            return indexPath
        }
    }
    
}

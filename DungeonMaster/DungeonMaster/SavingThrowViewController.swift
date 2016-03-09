//
//  SavingThrowViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class SavingThrowViewController: UITableViewController {

    var existingSavingThrows: [Ability] = []
    var selectedSavingThrows: [Ability] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
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
        
        if existingSavingThrows.contains(ability) {
            cell.accessoryType = .Checkmark
            cell.textLabel?.enabled = false
        } else if selectedSavingThrows.contains(ability) {
            cell.accessoryType = .Checkmark
            cell.textLabel?.enabled = true
        } else {
            cell.accessoryType = .None
            cell.textLabel?.enabled = true
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        let ability = Ability(rawValue: indexPath.row)!
        if existingSavingThrows.contains(ability) {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let ability = Ability(rawValue: indexPath.row)!
        if existingSavingThrows.contains(ability) {
            return
        } else if let index = selectedSavingThrows.indexOf(ability) {
            selectedSavingThrows.removeAtIndex(index)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                cell.accessoryType = .None
            }
        } else {
            selectedSavingThrows.append(ability)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                cell.accessoryType = .Checkmark
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}

//
//  CombatantRoleViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/24/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class CombatantRoleViewController: UITableViewController {
    
    var role: CombatRole?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        cell.accessoryType = indexPath.row == role?.rawValue ? .Checkmark : .None
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        role = CombatRole(rawValue: indexPath.row)
        return indexPath
    }
    
}
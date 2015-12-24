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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension CombatantRoleViewController {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        cell.accessoryType = indexPath.row == role?.rawValue ? .Checkmark : .None
        return cell
    }
    
}

// MARK: UITableViewDelegate
extension CombatantRoleViewController {
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        role = CombatRole(rawValue: indexPath.row)
        return indexPath
    }
    
}
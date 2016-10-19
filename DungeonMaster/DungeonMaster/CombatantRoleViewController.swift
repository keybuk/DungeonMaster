//
//  CombatantRoleViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/24/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class CombatantRoleViewController : UITableViewController {
    
    var role: CombatRole?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.accessoryType = (indexPath as NSIndexPath).row == role?.rawValue ? .checkmark : .none
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        role = CombatRole(rawValue: (indexPath as NSIndexPath).row)
        return indexPath
    }
    
}

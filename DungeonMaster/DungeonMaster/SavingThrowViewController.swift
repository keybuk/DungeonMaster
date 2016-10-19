//
//  SavingThrowViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class SavingThrowViewController : UITableViewController {

    var existingSavingThrows: [Ability] = []
    var selectedSavingThrows: [Ability] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Ability.cases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavingThrowCell", for: indexPath)
        
        let ability = Ability(rawValue: (indexPath as NSIndexPath).row)!
        
        cell.textLabel?.text = ability.stringValue
        
        if existingSavingThrows.contains(ability) {
            cell.accessoryType = .checkmark
            cell.textLabel?.isEnabled = false
        } else if selectedSavingThrows.contains(ability) {
            cell.accessoryType = .checkmark
            cell.textLabel?.isEnabled = true
        } else {
            cell.accessoryType = .none
            cell.textLabel?.isEnabled = true
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        let ability = Ability(rawValue: (indexPath as NSIndexPath).row)!
        if existingSavingThrows.contains(ability) {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ability = Ability(rawValue: (indexPath as NSIndexPath).row)!
        if existingSavingThrows.contains(ability) {
            return
        } else if let index = selectedSavingThrows.index(of: ability) {
            selectedSavingThrows.remove(at: index)
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = .none
            }
        } else {
            selectedSavingThrows.append(ability)
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = .checkmark
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

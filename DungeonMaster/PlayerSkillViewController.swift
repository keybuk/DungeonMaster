//
//  PlayerSkillViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class PlayerSkillViewController: UITableViewController {
    
    var player: Player!
    var selectedSkill: Skill?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UITableViewDataSource
extension PlayerSkillViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sharedRules.ability.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedRules.skill[section].count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sharedRules.ability[section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SkillCell", forIndexPath: indexPath)
        
        let skill = Skill(rawAbilityValue: indexPath.section, rawSkillValue: indexPath.row)!

        cell.textLabel?.text = skill.stringValue
        
        if player.isProficient(skill: skill) {
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
extension PlayerSkillViewController {
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let skill = Skill(rawAbilityValue: indexPath.section, rawSkillValue: indexPath.row)!
        if player.isProficient(skill: skill) {
            return nil
        } else {
            selectedSkill = Skill(rawAbilityValue: indexPath.section, rawSkillValue: indexPath.row)!
            return indexPath
        }
    }
    
}

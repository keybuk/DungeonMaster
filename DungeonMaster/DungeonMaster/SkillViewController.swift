//
//  SkillViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class SkillViewController: UITableViewController {
    
    var existingSkills = [Skill]()
    var selectedSkills = [Skill]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Ability.cases.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Skill.cases.filter({ $0.rawAbilityValue == section }).count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Ability(rawValue: section)!.stringValue
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SkillCell", forIndexPath: indexPath)
        
        let skill = Skill(rawAbilityValue: indexPath.section, rawSkillValue: indexPath.row)!

        cell.textLabel?.text = skill.stringValue
        
        if existingSkills.contains(skill) {
            cell.accessoryType = .Checkmark
            cell.textLabel?.enabled = false
        } else if selectedSkills.contains(skill) {
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
        let skill = Skill(rawAbilityValue: indexPath.section, rawSkillValue: indexPath.row)!
        if existingSkills.contains(skill) {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let skill = Skill(rawAbilityValue: indexPath.section, rawSkillValue: indexPath.row)!
        if existingSkills.contains(skill) {
            return
        } else if let index = selectedSkills.indexOf(skill) {
            selectedSkills.removeAtIndex(index)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                cell.accessoryType = .None
            }
        } else {
            selectedSkills.append(skill)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                cell.accessoryType = .Checkmark
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}

//
//  SkillViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class SkillViewController : UITableViewController {
    
    var existingSkills: [Skill] = []
    var selectedSkills: [Skill] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Ability.cases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Skill.cases.filter({ $0.rawAbilityValue == section }).count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Ability(rawValue: section)!.stringValue
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SkillCell", for: indexPath)
        
        let skill = Skill(rawAbilityValue: (indexPath as NSIndexPath).section, rawSkillValue: (indexPath as NSIndexPath).row)!

        cell.textLabel?.text = skill.stringValue
        
        if existingSkills.contains(skill) {
            cell.accessoryType = .checkmark
            cell.textLabel?.isEnabled = false
        } else if selectedSkills.contains(skill) {
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
        let skill = Skill(rawAbilityValue: (indexPath as NSIndexPath).section, rawSkillValue: (indexPath as NSIndexPath).row)!
        if existingSkills.contains(skill) {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let skill = Skill(rawAbilityValue: (indexPath as NSIndexPath).section, rawSkillValue: (indexPath as NSIndexPath).row)!
        if existingSkills.contains(skill) {
            return
        } else if let index = selectedSkills.index(of: skill) {
            selectedSkills.remove(at: index)
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = .none
            }
        } else {
            selectedSkills.append(skill)
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = .checkmark
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

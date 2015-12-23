//
//  PlayerCharacterClassController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class PlayerCharacterClassViewController: UITableViewController {
    
    var selectedCharacterClass: CharacterClass?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UITableViewDataSource
extension PlayerCharacterClassViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedRules.characterClass.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CharacterClassCell", forIndexPath: indexPath)
        
        let characterClass = CharacterClass(rawValue: indexPath.row)!
        
        cell.textLabel?.text = characterClass.stringValue
        
        if selectedCharacterClass != nil && indexPath.row == selectedCharacterClass!.rawValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    
}

// MARK: UITableViewDelegate
extension PlayerCharacterClassViewController {
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        selectedCharacterClass = CharacterClass(rawValue: indexPath.row)!
        return indexPath
    }

}
//
//  CharacterClassController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class CharacterClassViewController: UITableViewController {
    
    var selectedCharacterClass: CharacterClass?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CharacterClass.cases.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CharacterClassCell", forIndexPath: indexPath)
        
        let characterClass = CharacterClass(rawValue: indexPath.row)!
        
        cell.textLabel?.text = characterClass.stringValue
        
        if let selectedCharacterClass = selectedCharacterClass where indexPath.row == selectedCharacterClass.rawValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        selectedCharacterClass = CharacterClass(rawValue: indexPath.row)!
        return indexPath
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.accessoryType = .Checkmark
        }
        
        if let selectedCharacterClass = selectedCharacterClass {
            let oldIndexPath = NSIndexPath(forRow: selectedCharacterClass.rawValue, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(oldIndexPath) {
                cell.accessoryType = .None
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
//
//  CharacterClassController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class CharacterClassViewController : UITableViewController {
    
    var selectedCharacterClass: CharacterClass?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CharacterClass.cases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CharacterClassCell", for: indexPath)
        
        let characterClass = CharacterClass(rawValue: (indexPath as NSIndexPath).row)!
        
        cell.textLabel?.text = characterClass.stringValue
        
        if let selectedCharacterClass = selectedCharacterClass, (indexPath as NSIndexPath).row == selectedCharacterClass.rawValue {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        selectedCharacterClass = CharacterClass(rawValue: (indexPath as NSIndexPath).row)!
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        
        if let selectedCharacterClass = selectedCharacterClass {
            let oldIndexPath = IndexPath(row: selectedCharacterClass.rawValue, section: 0)
            if let cell = tableView.cellForRow(at: oldIndexPath) {
                cell.accessoryType = .none
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

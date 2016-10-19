//
//  BackgroundViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class BackgroundViewController : UITableViewController {
    
    var selectedBackground: Background?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Background.cases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BackgroundCell", for: indexPath)
        
        let background = Background(rawValue: (indexPath as NSIndexPath).row)!
        
        cell.textLabel?.text = background.stringValue
        
        if let selectedBackground = selectedBackground, (indexPath as NSIndexPath).row == selectedBackground.rawValue {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        selectedBackground = Background(rawValue: (indexPath as NSIndexPath).row)!
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        
        if let selectedBackground = selectedBackground {
            let oldIndexPath = IndexPath(row: selectedBackground.rawValue, section: 0)
            if let cell = tableView.cellForRow(at: oldIndexPath) {
                cell.accessoryType = .none
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

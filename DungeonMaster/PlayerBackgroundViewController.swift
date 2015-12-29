//
//  PlayerBackgroundViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class PlayerBackgroundViewController: UITableViewController {
    
    var selectedBackground: Background?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UITableViewDataSource
extension PlayerBackgroundViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Background.cases.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BackgroundCell", forIndexPath: indexPath)
        
        let background = Background(rawValue: indexPath.row)!
        
        cell.textLabel?.text = background.stringValue
        
        if let selectedBackground = selectedBackground where indexPath.row == selectedBackground.rawValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    
}

// MARK: UITableViewDelegate
extension PlayerBackgroundViewController {
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        selectedBackground = Background(rawValue: indexPath.row)!
        return indexPath
    }
    
}
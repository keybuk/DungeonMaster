//
//  BackgroundViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class BackgroundViewController: UITableViewController {
    
    var selectedBackground: Background?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
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
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        selectedBackground = Background(rawValue: indexPath.row)!
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.accessoryType = .Checkmark
        }
        
        if let selectedBackground = selectedBackground {
            let oldIndexPath = NSIndexPath(forRow: selectedBackground.rawValue, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(oldIndexPath) {
                cell.accessoryType = .None
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
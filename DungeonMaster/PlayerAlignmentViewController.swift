//
//  PlayerAlignmentViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class PlayerAlignmentViewController: UITableViewController {
    
    var selectedAlignment: Alignment?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UITableViewDataSource
extension PlayerAlignmentViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Alignment.cases.count - 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AlignmentCell", forIndexPath: indexPath)
        
        let alignment = Alignment(rawValue: indexPath.row + 1)!
        
        cell.textLabel?.text = alignment.stringValue
        
        if selectedAlignment != nil && indexPath.row == selectedAlignment!.rawValue - 1 {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    
}

// MARK: UITableViewDelegate
extension PlayerAlignmentViewController {
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        selectedAlignment = Alignment(rawValue: indexPath.row + 1)!
        return indexPath
    }
    
}

//
//  AlignmentViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class AlignmentViewController: UITableViewController {
    
    var selectedAlignment: Alignment?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
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
        
        if let selectedAlignment = selectedAlignment where indexPath.row == selectedAlignment.rawValue - 1 {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        selectedAlignment = Alignment(rawValue: indexPath.row + 1)!
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.accessoryType = .Checkmark
        }
        
        if let selectedAlignment = selectedAlignment {
            let oldIndexPath = NSIndexPath(forRow: selectedAlignment.rawValue - 1, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(oldIndexPath) {
                cell.accessoryType = .None
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}

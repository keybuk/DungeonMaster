//
//  AlignmentViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class AlignmentViewController : UITableViewController {
    
    var selectedAlignment: Alignment?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Alignment.cases.count - 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlignmentCell", for: indexPath)
        
        let alignment = Alignment(rawValue: (indexPath as NSIndexPath).row + 1)!
        
        cell.textLabel?.text = alignment.stringValue
        
        if let selectedAlignment = selectedAlignment, (indexPath as NSIndexPath).row == selectedAlignment.rawValue - 1 {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        selectedAlignment = Alignment(rawValue: (indexPath as NSIndexPath).row + 1)!
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        
        if let selectedAlignment = selectedAlignment {
            let oldIndexPath = IndexPath(row: selectedAlignment.rawValue - 1, section: 0)
            if let cell = tableView.cellForRow(at: oldIndexPath) {
                cell.accessoryType = .none
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

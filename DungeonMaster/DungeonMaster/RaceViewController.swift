//
//  RaceViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class RaceViewController: UITableViewController {
    
    var selectedRace: Race?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Set(Race.cases.map({ $0.rawRaceValue })).count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Race.cases.filter({ $0.rawRaceValue == section }).count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Race.stringValue(forRawRaceValue: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RaceCell", forIndexPath: indexPath)
        
        let race: Race
        if Race.cases.filter({ $0.rawRaceValue == indexPath.section }).count > 1 {
            race = Race(rawRaceValue: indexPath.section, rawSubraceValue: indexPath.row)!
        } else {
            race = Race(rawRaceValue: indexPath.section, rawSubraceValue: nil)!
        }
        
        cell.textLabel?.text = race.stringValue
        
        if let selectedRace = selectedRace where indexPath.section == selectedRace.rawRaceValue && indexPath.row == selectedRace.rawSubraceValue ?? 0 {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        if Race.cases.filter({ $0.rawRaceValue == indexPath.section }).count > 1 {
            selectedRace = Race(rawRaceValue: indexPath.section, rawSubraceValue: indexPath.row)!
        } else {
            selectedRace = Race(rawRaceValue: indexPath.section, rawSubraceValue: nil)!
        }
        
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.accessoryType = .Checkmark
        }
        
        if let race = selectedRace {
            let oldIndexPath = NSIndexPath(forRow: race.rawSubraceValue ?? 0, inSection: race.rawRaceValue)
            if let cell = tableView.cellForRowAtIndexPath(oldIndexPath) {
                cell.accessoryType = .None
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
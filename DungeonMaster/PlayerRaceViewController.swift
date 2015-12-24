//
//  PlayerRaceViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class PlayerRaceViewController: UITableViewController {
    
    var selectedRace: Race?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UITableViewDataSource
extension PlayerRaceViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Set(Race.cases.map({ $0.rawRaceValue })).count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(Race.cases.filter({ $0.rawRaceValue == section }).count, 1)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Race.stringValue(rawRaceValue: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RaceCell", forIndexPath: indexPath)
        
        let race: Race
        if Race.cases.filter({ $0.rawRaceValue == indexPath.section }).count > 0 {
            race = Race(rawRaceValue: indexPath.section, rawSubraceValue: indexPath.row)!
        } else {
            race = Race(rawRaceValue: indexPath.section, rawSubraceValue: nil)!
        }
        
        cell.textLabel?.text = race.stringValue
        
        if selectedRace != nil && indexPath.section == selectedRace!.rawRaceValue && indexPath.row == selectedRace!.rawSubraceValue ?? 0 {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }
    
}

// MARK: UITableViewDelegate
extension PlayerRaceViewController {
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if Race.cases.filter({ $0.rawRaceValue == indexPath.section }).count > 0 {
            selectedRace = Race(rawRaceValue: indexPath.section, rawSubraceValue: indexPath.row)!
        } else {
            selectedRace = Race(rawRaceValue: indexPath.section, rawSubraceValue: nil)!
        }

        return indexPath
    }

}
//
//  RaceViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class RaceViewController : UITableViewController {
    
    var selectedRace: Race?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Set(Race.cases.map({ $0.rawRaceValue })).count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Race.cases.filter({ $0.rawRaceValue == section }).count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Race.stringValue(forRawRaceValue: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RaceCell", for: indexPath)
        
        let race: Race
        if Race.cases.filter({ $0.rawRaceValue == (indexPath as NSIndexPath).section }).count > 1 {
            race = Race(rawRaceValue: (indexPath as NSIndexPath).section, rawSubraceValue: (indexPath as NSIndexPath).row)!
        } else {
            race = Race(rawRaceValue: (indexPath as NSIndexPath).section, rawSubraceValue: nil)!
        }
        
        cell.textLabel?.text = race.stringValue
        
        if let selectedRace = selectedRace, (indexPath as NSIndexPath).section == selectedRace.rawRaceValue && (indexPath as NSIndexPath).row == selectedRace.rawSubraceValue ?? 0 {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Will select, rather than did, so we update before the exit segue.
        if Race.cases.filter({ $0.rawRaceValue == (indexPath as NSIndexPath).section }).count > 1 {
            selectedRace = Race(rawRaceValue: (indexPath as NSIndexPath).section, rawSubraceValue: (indexPath as NSIndexPath).row)!
        } else {
            selectedRace = Race(rawRaceValue: (indexPath as NSIndexPath).section, rawSubraceValue: nil)!
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        
        if let race = selectedRace {
            let oldIndexPath = IndexPath(row: race.rawSubraceValue ?? 0, section: race.rawRaceValue)
            if let cell = tableView.cellForRow(at: oldIndexPath) {
                cell.accessoryType = .none
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

//
//  AddLogEntryViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class AddLogEntryViewController: UINavigationController {
    
    var game: Game?
    var encounter: Encounter?
    var playedGame: PlayedGame?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let encounter = encounter, game = game {
            let viewController = storyboard?.instantiateViewControllerWithIdentifier("LogEntryCombatantsViewController") as! LogEntryCombatantsViewController
            viewController.logEntryType = XPAward.self
            viewController.encounter = encounter
            viewController.game = game
            
            setViewControllers([ viewController ], animated: false)
        } else {
            let viewController = topViewController as! LogEntryTypeViewController
            viewController.game = game
            viewController.playedGame = playedGame
        }
    }

}

//
//  GameDateViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class GameDateViewController: UIViewController {
    
    var game: Game!

    @IBOutlet var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        datePicker.date = game.date
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func datePickerValueChanged(sender: UIDatePicker) {
        game.date = sender.date
        // This is only visible when the game view is editing, and that view handles saving the context and updating the Adventure `lastModified` when editing finishes.
    }

}

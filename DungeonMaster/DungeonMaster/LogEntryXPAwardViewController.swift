//
//  LogEntryXPAwardViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class LogEntryXPAwardViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var playedGames: Set<PlayedGame>!
    
    var encounter: Encounter?
    var combatants: Set<Combatant>?

    @IBOutlet var doneButtonItem: UIBarButtonItem!
    @IBOutlet var xpTextField: UITextField!
    @IBOutlet var reasonTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let encounter = encounter, combatants = combatants {
            var xp = 0
            
            for combatant in combatants {
                if let monster = combatant.monster {
                    xp += monster.XP
                }
            }
            
            xp = Int(floor(Double(xp) / Double(playedGames.count)))
            if xp > 0 {
                xpTextField.text = "\(xp)"
                reasonTextView.text = "for defeating the \(encounter.title)."
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if xpTextField.text == "" {
            xpTextField.becomeFirstResponder()
        } else {
            reasonTextView.becomeFirstResponder()
        }
    }
    
    func configureView() {
        doneButtonItem.enabled = (xpTextField.text != "" && reasonTextView.text != "")
    }
    
    func createLogEntry() {
        let xp = Int(xpTextField.text!)!

        for playedGame in playedGames {
            let xpAward = XPAward(playedGame: playedGame, inManagedObjectContext: managedObjectContext)
            xpAward.xp = xp
            xpAward.reason = reasonTextView.text
            
            playedGame.player.xp += xp
        }
        
        try! managedObjectContext.save()

        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Actions
    
    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        createLogEntry()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        reasonTextView.becomeFirstResponder()
        return false
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let validSet = NSCharacterSet.decimalDigitCharacterSet()
        for character in string.unicodeScalars {
            if !validSet.longCharacterIsMember(character.value) {
                return false
            }
        }
        return true
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        configureView()
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if textView.text != "" {
                textView.editable = false
                createLogEntry()
            }
            return false
        } else {
            return true
        }
    }

}

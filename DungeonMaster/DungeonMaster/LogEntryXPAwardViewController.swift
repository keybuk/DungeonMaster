//
//  LogEntryXPAwardViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class LogEntryXPAwardViewController : UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var playedGames: Set<PlayedGame>!
    
    var encounter: Encounter?
    var combatants: Set<Combatant>?

    @IBOutlet var doneButtonItem: UIBarButtonItem!
    @IBOutlet var xpTextField: UITextField!
    @IBOutlet var reasonTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let encounter = encounter, let combatants = combatants {
            var xp = 0
            
            for combatant in combatants {
                if let monster = combatant.monster {
                    xp += monster.xp
                }
            }
            
            xp = Int(floor(Double(xp) / Double(playedGames.count)))
            if xp > 0 {
                xpTextField.text = "\(xp)"
                reasonTextView.text = "for defeating the \(encounter.title)."
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if xpTextField.text == "" {
            xpTextField.becomeFirstResponder()
        } else {
            reasonTextView.becomeFirstResponder()
        }
    }
    
    func configureView() {
        doneButtonItem.isEnabled = (xpTextField.text != "" && reasonTextView.text != "")
    }
    
    func createLogEntry() {
        let xp = Int(xpTextField.text!)!

        for playedGame in playedGames {
            let xpAward = XPAward(playedGame: playedGame, insertInto: managedObjectContext)
            xpAward.xp = xp
            xpAward.reason = reasonTextView.text
            
            playedGame.player.xp += xp
        }
        
        try! managedObjectContext.save()

        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        createLogEntry()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        reasonTextView.becomeFirstResponder()
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let validSet = CharacterSet.decimalDigits
        for character in string.unicodeScalars {
            if !validSet.contains(UnicodeScalar(character.value)!) {
                return false
            }
        }
        return true
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        configureView()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if textView.text != "" {
                textView.isEditable = false
                createLogEntry()
            }
            return false
        } else {
            return true
        }
    }

}

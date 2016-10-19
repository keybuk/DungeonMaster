//
//  LogEntryNoteViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class LogEntryNoteViewController : UITableViewController, UITextViewDelegate {

    var playedGames: Set<PlayedGame>!

    @IBOutlet var doneButtonItem: UIBarButtonItem!
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.becomeFirstResponder()
    }
    
    func configureView() {
        doneButtonItem.isEnabled = textView.text != ""
    }
    
    func createLogEntry() {
        for playedGame in playedGames {
            let logEntry = LogEntryNote(playedGame: playedGame, insertInto: managedObjectContext)
            logEntry.note = textView.text
        }
        
        try! managedObjectContext.save()

        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Actions

    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        createLogEntry()
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

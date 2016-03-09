//
//  LogEntryNoteViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class LogEntryNoteViewController: UITableViewController, UITextViewDelegate {

    var playedGames: Set<PlayedGame>!

    @IBOutlet var doneButtonItem: UIBarButtonItem!
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.becomeFirstResponder()
    }
    
    func configureView() {
        doneButtonItem.enabled = textView.text != ""
    }
    
    func createLogEntry() {
        for playedGame in playedGames {
            let logEntry = LogEntryNote(playedGame: playedGame, inManagedObjectContext: managedObjectContext)
            logEntry.note = textView.text
        }
        
        try! managedObjectContext.save()

        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Actions

    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        createLogEntry()
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

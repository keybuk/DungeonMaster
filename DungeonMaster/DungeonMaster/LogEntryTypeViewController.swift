//
//  LogEntryTypeViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class LogEntryTypeViewController : UICollectionViewController {
    
    var game: Game?
    var playedGame: PlayedGame?
    
    var logEntryType: LogEntry.Type?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickPlayersSegue" {
            let viewController = segue.destination as! LogEntryPlayersViewController
            viewController.game = game
            viewController.logEntryType = logEntryType
        } else if segue.identifier == "NoteSegue" {
            let viewController = segue.destination as! LogEntryNoteViewController
            viewController.playedGames = [ playedGame! ]
        } else if segue.identifier == "XPAwardSegue" {
            let viewController = segue.destination as! LogEntryXPAwardViewController
            viewController.playedGames = [ playedGame! ]
        }
    }

    // MARK: Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogEntryTypeCell", for: indexPath) as! LogEntryTypeCell
        
        switch (indexPath as NSIndexPath).row {
        case 0:
            cell.imageView.image = UIImage(named: "XPButton")
        case 1:
            cell.imageView.image = UIImage(named: "NoteButton")
        default:
            break
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let _ = playedGame {
            switch (indexPath as NSIndexPath).row {
            case 0:
                performSegue(withIdentifier: "XPAwardSegue", sender: collectionView)
            case 1:
                performSegue(withIdentifier: "NoteSegue", sender: collectionView)
            default:
                break
            }
        } else {
            switch (indexPath as NSIndexPath).row {
            case 0:
                logEntryType = XPAward.self
            case 1:
                logEntryType = LogEntryNote.self
            default:
                break
            }

            performSegue(withIdentifier: "PickPlayersSegue", sender: collectionView)
        }
    }

}

class LogEntryTypeCell : UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    
}

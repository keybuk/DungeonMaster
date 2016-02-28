//
//  LogEntryTypeViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/25/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class LogEntryTypeViewController: UICollectionViewController {
    
    var game: Game?
    var playedGame: PlayedGame?
    
    var logEntryType: LogEntry.Type?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions

    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickPlayersSegue" {
            let viewController = segue.destinationViewController as! LogEntryPlayersViewController
            viewController.game = game
            viewController.logEntryType = logEntryType
        } else if segue.identifier == "NoteSegue" {
            let viewController = segue.destinationViewController as! LogEntryNoteViewController
            viewController.playedGames = [ playedGame! ]
        } else if segue.identifier == "XPAwardSegue" {
            let viewController = segue.destinationViewController as! LogEntryXPAwardViewController
            viewController.playedGames = [ playedGame! ]
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LogEntryTypeCell", forIndexPath: indexPath) as! LogEntryTypeCell
        
        switch indexPath.row {
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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if let _ = playedGame {
            switch indexPath.row {
            case 0:
                performSegueWithIdentifier("XPAwardSegue", sender: collectionView)
            case 1:
                performSegueWithIdentifier("NoteSegue", sender: collectionView)
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 0:
                logEntryType = XPAward.self
            case 1:
                logEntryType = LogEntryNote.self
            default:
                break
            }

            performSegueWithIdentifier("PickPlayersSegue", sender: collectionView)
        }
    }

}

class LogEntryTypeCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    
}

//
//  GameViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/21/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class GameViewController : UIViewController, ManagedObjectObserverDelegate {
    
    var game: Game!

    @IBOutlet var dateLabel: UILabel!
    
    var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Put the edit button in, with space between it and the compendium buttons.
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = 40.0
            
        navigationItem.rightBarButtonItems?.insert(fixedSpace, atIndex: 0)
        navigationItem.rightBarButtonItems?.insert(editButtonItem(), atIndex: 0)

        configureView()
    
        observer = ManagedObjectObserver(object: game, delegate: self)

        if game.inserted {
            setEditing(true, animated: false)
        }
    }

    func configureView() {
        // Set the view title.
        navigationItem.title = game.title
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        dateLabel.text = dateFormatter.stringFromDate(game.date)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    override func setEditing(editing: Bool, animated: Bool) {
        let oldEditing = self.editing
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = editing
        
        dateLabel.textColor = editing ? dateLabel.tintColor : UIColor.blackColor()
        dateLabel.userInteractionEnabled = editing
        
        playersViewController.setEditing(editing, animated: animated)
        encountersViewController.setEditing(editing, animated: animated)

        if oldEditing && !editing {
            game.adventure.lastModified = NSDate()
            try! managedObjectContext.save()
        }
    }
    
    // MARK: Navigation
    
    var playersViewController: GamePlayersViewController!
    var encountersViewController: GameEncountersViewController!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlayersEmbedSegue" {
            playersViewController = segue.destinationViewController as! GamePlayersViewController
            playersViewController.game = game
        } else if segue.identifier == "EncountersEmbedSegue" {
            encountersViewController = segue.destinationViewController as! GameEncountersViewController
            encountersViewController.game = game
        } else if segue.identifier == "CompendiumMonstersSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = game.adventure.books.allObjects as! [Book]
            viewController.showMonsters()
        } else if segue.identifier == "CompendiumSpellsSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = game.adventure.books.allObjects as! [Book]
            viewController.showSpells()
        } else if segue.identifier == "CompendiumMagicItemsSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = game.adventure.books.allObjects as! [Book]
            viewController.showMagicItems()
        } else if segue.identifier == "DatePopoverSegue" {
            let viewController = segue.destinationViewController as! GameDateViewController
            viewController.game = game

            if let presentation = viewController.popoverPresentationController, sourceView = presentation.sourceView {
                presentation.sourceRect = sourceView.bounds
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func shareButtonTapped(sender: UIBarButtonItem) {
        let fileManager = NSFileManager.defaultManager()
        if let cachesUrl = try? fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true) {
            let filename = "\(game.title).txt"
            let url = cachesUrl.URLByAppendingPathComponent(filename)
            
            let description = game.descriptionForExport()
            do {
                try description.writeToURL(url, atomically: false, encoding: NSUTF8StringEncoding)
                
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                    try! fileManager.removeItemAtURL(url)
                }
                
                if let presentation = activityViewController.popoverPresentationController {
                    presentation.barButtonItem = sender
                }
                
                presentViewController(activityViewController, animated: true, completion: nil)
            } catch {
            }
        }
    }
    
    
    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(object: Game, changedForType type: ManagedObjectChangeType) {
        configureView()
    }
    
}

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
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 40.0
            
        navigationItem.rightBarButtonItems?.insert(fixedSpace, at: 0)
        navigationItem.rightBarButtonItems?.insert(editButtonItem, at: 0)

        configureView()
    
        observer = ManagedObjectObserver(object: game, delegate: self)

        if game.isInserted {
            setEditing(true, animated: false)
        }
    }

    func configureView() {
        // Set the view title.
        navigationItem.title = game.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: game.date as Date)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let oldEditing = self.isEditing
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = editing
        
        dateLabel.textColor = editing ? dateLabel.tintColor : UIColor.black
        dateLabel.isUserInteractionEnabled = editing
        
        playersViewController.setEditing(editing, animated: animated)
        encountersViewController.setEditing(editing, animated: animated)

        if oldEditing && !editing {
            game.adventure.lastModified = Date()
            try! managedObjectContext.save()
        }
    }
    
    // MARK: Navigation
    
    var playersViewController: GamePlayersViewController!
    var encountersViewController: GameEncountersViewController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlayersEmbedSegue" {
            playersViewController = segue.destination as! GamePlayersViewController
            playersViewController.game = game
        } else if segue.identifier == "EncountersEmbedSegue" {
            encountersViewController = segue.destination as! GameEncountersViewController
            encountersViewController.game = game
        } else if segue.identifier == "CompendiumMonstersSegue" {
            let viewController = segue.destination as! CompendiumViewController
            viewController.books = game.adventure.books.allObjects as! [Book]
            viewController.showMonsters()
        } else if segue.identifier == "CompendiumSpellsSegue" {
            let viewController = segue.destination as! CompendiumViewController
            viewController.books = game.adventure.books.allObjects as! [Book]
            viewController.showSpells()
        } else if segue.identifier == "CompendiumMagicItemsSegue" {
            let viewController = segue.destination as! CompendiumViewController
            viewController.books = game.adventure.books.allObjects as! [Book]
            viewController.showMagicItems()
        } else if segue.identifier == "DatePopoverSegue" {
            let viewController = segue.destination as! GameDateViewController
            viewController.game = game

            if let presentation = viewController.popoverPresentationController, let sourceView = presentation.sourceView {
                presentation.sourceRect = sourceView.bounds
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        let fileManager = FileManager.default
        if let cachesUrl = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let filename = "\(game.title).txt"
            let url = cachesUrl.appendingPathComponent(filename)
            
            let description = game.descriptionForExport()
            do {
                try description.write(to: url, atomically: false, encoding: String.Encoding.utf8)
                
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                    try! fileManager.removeItem(at: url)
                }
                
                if let presentation = activityViewController.popoverPresentationController {
                    presentation.barButtonItem = sender
                }
                
                present(activityViewController, animated: true, completion: nil)
            } catch {
            }
        }
    }
    
    
    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(_ object: Game, changedForType type: ManagedObjectChangeType) {
        configureView()
    }
    
}

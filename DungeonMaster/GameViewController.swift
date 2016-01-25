//
//  GameViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/21/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    
    var game: Game!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Put the edit button in, with space between it and the compendium buttons.
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = 40.0
            
        navigationItem.rightBarButtonItems?.insert(fixedSpace, atIndex: 0)
        navigationItem.rightBarButtonItems?.insert(editButtonItem(), atIndex: 0)

        // Set the view title.
        let numberFormatter = RomanNumeralFormatter()
        let number = numberFormatter.stringFromNumber(game.number)!
        navigationItem.title = "\(game.adventure.name) \(number)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = editing
        
        playersViewController.setEditing(editing, animated: animated)
    }
    
    // MARK: Navigation
    
    var playersViewController: GamePlayersViewController!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlayersEmbedSegue" {
            playersViewController = segue.destinationViewController as! GamePlayersViewController
            playersViewController.game = game
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
        }
    }

}

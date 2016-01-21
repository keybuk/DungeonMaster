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

        let numberFormatter = RomanNumeralFormatter()
        let number = numberFormatter.stringFromNumber(game.number)!
        navigationItem.title = "\(game.adventure.name) \(number)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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

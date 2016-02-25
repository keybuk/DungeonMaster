//
//  PlayerRootViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/22/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class PlayerRootViewController: UIViewController, ManagedObjectObserverDelegate {
    
    var player: Player!
    
    var playedGame: PlayedGame? {
        didSet {
            guard let playedGame = playedGame else { return }
            player = playedGame.player
        }
    }
    
    var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = editButtonItem()

        observer = ManagedObjectObserver(object: player, delegate: self)
        
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        navigationItem.title = player.name
        if editing {
            navigationItem.rightBarButtonItem?.enabled = (try? player.validateForUpdate()) != nil ? true : false
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let playerTable = playerViewController.view as! UIScrollView
        let playedGamesTable = playedGamesViewController.view as! UIScrollView
        
        playedGamesTable.contentInset = playerTable.contentInset
        playedGamesTable.scrollIndicatorInsets = playerTable.scrollIndicatorInsets
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = editing
        
        playerViewController.setEditing(editing, animated: animated)
        playedGamesViewController.setEditing(editing, animated: animated)
    }
    
    // MARK: Navigation
    
    var playerViewController: PlayerViewController!
    var playedGamesViewController: PlayedGamesViewController!

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlayerEmbedSegue" {
            playerViewController = segue.destinationViewController as! PlayerViewController
            playerViewController.player = player
        } else if segue.identifier == "PlayedGamesEmbedSegue" {
            playedGamesViewController = segue.destinationViewController as! PlayedGamesViewController
            playedGamesViewController.player = player
            playedGamesViewController.game = playedGame?.game
        }
    }
    
    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(object: Player, changedForType type: ManagedObjectChangeType) {
        configureView()
    }

}

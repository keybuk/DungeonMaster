//
//  EncounterViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/2/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class EncounterViewController: UIViewController, ManagedObjectObserverDelegate {
    
    var encounter: Encounter!

    var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Put the edit button in, with space between it and the compendium buttons.
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = 40.0
        
        navigationItem.rightBarButtonItems?.insert(fixedSpace, atIndex: 0)
        navigationItem.rightBarButtonItems?.insert(editButtonItem(), atIndex: 0)

        configureView()
        
        observer = ManagedObjectObserver(object: encounter, delegate: self)
        
        if encounter.inserted {
            setEditing(true, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        navigationItem.title = encounter.title
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        let oldEditing = self.editing
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = editing
        
        combatantsViewController.setEditing(editing, animated: animated)
        
        if oldEditing && !editing {
            encounter.adventure.lastModified = NSDate()
            try! managedObjectContext.save()
        }
    }
    
    // MARK: Navigation
    
    var combatantsViewController: EncounterCombatantsViewController!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CombatantsEmbedSegue" {
            combatantsViewController = segue.destinationViewController as! EncounterCombatantsViewController
            combatantsViewController.encounter = encounter
        } else if segue.identifier == "CompendiumMonstersSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = encounter.adventure.books.allObjects as! [Book]
            viewController.showMonsters()
        } else if segue.identifier == "CompendiumSpellsSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = encounter.adventure.books.allObjects as! [Book]
            viewController.showSpells()
        } else if segue.identifier == "CompendiumMagicItemsSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = encounter.adventure.books.allObjects as! [Book]
            viewController.showMagicItems()
        }
    }

    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(object: Encounter, changedForType type: ManagedObjectChangeType) {
        configureView()
    }

}

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
    var game: Game?

    @IBOutlet var leftContainerView: UIView!
    @IBOutlet var middleContainerView: UIView!
    @IBOutlet var rightContainerView: UIView!
    
    @IBOutlet var nextButtonItem: UIBarButtonItem!
    @IBOutlet var initiativeButtonItem: UIBarButtonItem!
    @IBOutlet var awardXPButtonItem: UIBarButtonItem!
    @IBOutlet var tabletopButtonItem: UIBarButtonItem!
    
    var observer: NSObjectProtocol?
    
    var roundLabel: UILabel!
    var difficultyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Put the edit button in, with space between it and the compendium buttons.
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = 40.0
        
        navigationItem.rightBarButtonItems?.insert(fixedSpace, atIndex: 0)
        navigationItem.rightBarButtonItems?.insert(editButtonItem(), atIndex: 0)
        
        // Another thing IB won't let us do: put labels in toolbars, even though this is perfectly valid UIKit. So we build the toolbar up the hard way.
        roundLabel = UILabel()
        roundLabel.text = "Round 1"
        roundLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        roundLabel.sizeToFit()

        let roundButtonItem = UIBarButtonItem(customView: roundLabel)
        
        difficultyLabel = UILabel()
        difficultyLabel.text = "No Challenge"
        difficultyLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        difficultyLabel.sizeToFit()

        let labelButtonItem = UIBarButtonItem(customView: difficultyLabel)
        
        toolbarItems = []
        if let _ = game {
            toolbarItems?.append(roundButtonItem)
            toolbarItems?.append(nextButtonItem)
            toolbarItems?.append(initiativeButtonItem)
            toolbarItems?.append(awardXPButtonItem)
        }
        
        toolbarItems?.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))
        toolbarItems?.append(labelButtonItem)
        toolbarItems?.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))
        
        toolbarItems?.append(tabletopButtonItem)

        // Set up the rest of the view.
        configureView()
        
        observer = ManagedObjectObserver(object: encounter, delegate: self)
        
        if encounter.inserted {
            setEditing(true, animated: false)
        }
    }

    func configureView() {
        navigationItem.title = encounter.title
        
        roundLabel.hidden = false
        roundLabel.text = "Round \(encounter.round)"
        roundLabel.sizeToFit()
        
        nextButtonItem.enabled = encounter.round > 0
        initiativeButtonItem.enabled = encounter.combatants.count > 0
        awardXPButtonItem.enabled = encounter.round > 0
        
        if let difficulty = encounter.calculateDifficulty(forGame: game) {
            let difficultyText: String
            switch difficulty {
            case .Deadly:
                difficultyText = "Deadly"
            case .Hard:
                difficultyText = "Hard"
            case .Medium:
                difficultyText = "Medium"
            case .Easy:
                difficultyText = "Easy"
            case .None:
                difficultyText = "None"
            }
            
            let xp = encounter.totalXP()
            let xpFormatter = NSNumberFormatter()
            xpFormatter.numberStyle = .DecimalStyle
            
            difficultyLabel.text = "\(difficultyText)—\(xpFormatter.stringFromNumber(xp)!) XP"
            difficultyLabel.sizeToFit()
        } else {
            difficultyLabel.text = "Incomplete encounter"
            difficultyLabel.sizeToFit()
        }
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
        
        combatantsViewController.setEditing(editing, animated: animated)
        
        if oldEditing && !editing {
            // Adding monsters in the game should immediate show the Initiative view.
            if encounter.round > 0 && encounter.combatants.filteredSetUsingPredicate(NSPredicate(format: "rawInitiative == nil")).count > 0 {
                performSegueWithIdentifier("InitiativeSegue", sender: self)
            }
        }
    }
    
    // MARK: Navigation
    
    var combatantsViewController: EncounterCombatantsViewController!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CombatantsEmbedSegue" {
            combatantsViewController = segue.destinationViewController as! EncounterCombatantsViewController
            combatantsViewController.encounter = encounter
        } else if segue.identifier == "InitiativeSegue" {
            let viewController = (segue.destinationViewController as! UINavigationController).topViewController as! InitiativeViewController
            viewController.encounter = encounter
            viewController.game = game!
        } else if segue.identifier == "AwardXPSegue" {
            let viewController = segue.destinationViewController as! AddLogEntryViewController
            viewController.encounter = encounter
            viewController.game = game
        } else if segue.identifier == "TabletopSegue" {
            let viewController = segue.destinationViewController as! TabletopViewController
            viewController.encounter = encounter
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
    
    // MARK: Actions
    
    @IBAction func nextButtonTapped(sender: UIBarButtonItem) {
        encounter.nextTurn()
        encounter.lastModified = NSDate()
        try! managedObjectContext.save()
    }
    
    
    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(object: Encounter, changedForType type: ManagedObjectChangeType) {
        configureView()
    }
    
    // Container views
    
    var middleViewController: UIViewController? {
        willSet {
            if let middleViewController = middleViewController {
                middleViewController.willMoveToParentViewController(nil)
                middleViewController.view.removeFromSuperview()
                middleViewController.removeFromParentViewController()
            }
        }
        didSet {
            if let middleViewController = middleViewController {
                addChildViewController(middleViewController)
                middleContainerView.addSubview(middleViewController.view)
                middleViewController.view.frame = middleContainerView.bounds

                // FIXME this does the right thing for now, but it feels kinda hacky.
                if let scrollView = (middleViewController.view as? UIScrollView ?? middleViewController.view.subviews.first as? UIScrollView) {
                    let oldTopInset = scrollView.contentInset.top
                    scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0.0, bottom: bottomLayoutGuide.length, right: 0.0)
                    scrollView.scrollIndicatorInsets = scrollView.contentInset
                    scrollView.contentOffset.y -= (scrollView.contentInset.top - oldTopInset)
                }
                
                middleViewController.didMoveToParentViewController(self)
            }
        }
    }
    
    var rightViewController: UIViewController? {
        willSet {
            if let rightViewController = rightViewController {
                rightViewController.willMoveToParentViewController(nil)
                rightViewController.view.removeFromSuperview()
                rightViewController.removeFromParentViewController()
            }
        }
        didSet {
            if let rightViewController = rightViewController {
                addChildViewController(rightViewController)
                rightContainerView.addSubview(rightViewController.view)
                rightViewController.view.frame = rightContainerView.bounds
                
                // FIXME this does the right thing for now, but it feels kinda hacky.
                if let scrollView = rightViewController.view as? UIScrollView {
                    scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0.0, bottom: bottomLayoutGuide.length, right: 0.0)
                    scrollView.scrollIndicatorInsets = scrollView.contentInset
                }
                
                rightViewController.didMoveToParentViewController(self)
            }
        }
    }

}

class EncounterShowMiddleSegue: UIStoryboardSegue {
    
    override func perform() {
        let encounterViewController = sourceViewController.parentViewController as! EncounterViewController
        encounterViewController.middleViewController = destinationViewController
    }

}

class EncounterShowRightSegue: UIStoryboardSegue {
    
    override func perform() {
        let encounterViewController = sourceViewController.parentViewController as! EncounterViewController
        encounterViewController.rightViewController = destinationViewController
    }
    
}

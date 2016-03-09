//
//  EncounterAddCombatantViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/3/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class EncounterAddCombatantViewController: UIViewController {
    
    var encounter: Encounter!
    
    var quantity = 1

    var completionBlock: ((cancelled: Bool, monster: Monster?, quantity: Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    
    var monstersViewController: MonstersViewController!
    var addButtonItem: UIBarButtonItem!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CompendiumMonstersEmbedSegue" {
            let splitViewController = segue.destinationViewController as! UISplitViewController

            monstersViewController = (splitViewController.viewControllers.first as! UINavigationController).topViewController as! MonstersViewController
            monstersViewController.books = encounter.adventure.books.allObjects as! [Book]
            
            let cancelButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelButtonTapped:")
            monstersViewController.navigationItem.leftBarButtonItem = cancelButtonItem
            
            addButtonItem = UIBarButtonItem(title: "Add 1", style: .Done, target: self, action: "addButtonTapped:")

            let stepper = UIStepper()
            stepper.minimumValue = 1.0
            stepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: .ValueChanged)
            stepper.value = 1.0
            let stepperButtonItem = UIBarButtonItem(customView: stepper)

            monstersViewController.detailBarButtonItems = [addButtonItem, stepperButtonItem]
        }
    }

    // MARK: Actions
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        completionBlock?(cancelled: true, monster: nil, quantity: 0)
    }

    @IBAction func addButtonTapped(sender: UIBarButtonItem) {
        // FIXME continued very hacky
        if let indexPath = monstersViewController.tableView.indexPathForSelectedRow {
            let monster = monstersViewController.fetchedResultsController.objectAtIndexPath(indexPath) as! Monster
            completionBlock?(cancelled: false, monster: monster, quantity: quantity)
        }
    }
    
    @IBAction func stepperValueChanged(sender: UIStepper) {
        quantity = Int(sender.value)
        addButtonItem.title = "Add \(quantity)"
    }

}

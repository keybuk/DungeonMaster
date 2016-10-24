//
//  EncounterAddCombatantViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/3/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class EncounterAddCombatantViewController : UIViewController {
    
    var encounter: Encounter!
    
    var quantity = 1

    var completionBlock: ((_ cancelled: Bool, _ monster: Monster?, _ quantity: Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: Navigation
    
    var monstersViewController: MonstersViewController!
    var addButtonItem: UIBarButtonItem!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CompendiumMonstersEmbedSegue" {
            let splitViewController = segue.destination as! UISplitViewController

            monstersViewController = (splitViewController.viewControllers.first as! UINavigationController).topViewController as! MonstersViewController
            monstersViewController.books = encounter.adventure.books.allObjects as! [Book]
            
            let cancelButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped(_:)))
            monstersViewController.navigationItem.leftBarButtonItem = cancelButtonItem
            
            addButtonItem = UIBarButtonItem(title: "Add 1", style: .done, target: self, action: #selector(addButtonTapped(_:)))

            let stepper = UIStepper()
            stepper.minimumValue = 1.0
            stepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
            stepper.value = 1.0
            let stepperButtonItem = UIBarButtonItem(customView: stepper)

            monstersViewController.detailBarButtonItems = [addButtonItem, stepperButtonItem]
        }
    }

    // MARK: Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        completionBlock?(true, nil, 0)
    }

    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        // FIXME continued very hacky
        if let indexPath = monstersViewController.tableView.indexPathForSelectedRow {
            let monster = monstersViewController.fetchedResultsController.object(at: indexPath)
            completionBlock?(cancelled: false, monster: monster, quantity: quantity)
        }
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        quantity = Int(sender.value)
        addButtonItem.title = "Add \(quantity)"
    }

}

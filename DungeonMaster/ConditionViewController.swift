//
//  ConditionViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/14/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class ConditionViewController: UITableViewController {

    @IBOutlet var addButton: UIBarButtonItem!

    var type: ConditionType?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UIPickerViewDataSource
extension ConditionViewController: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 15
    }

}

// MARK: UIPickerViewDelegate
extension ConditionViewController: UIPickerViewDelegate {

    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch row {
        case 0:
            return NSAttributedString(string: "Condition", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        case 1:
            return NSAttributedString(string: "Blinded")
        case 2:
            return NSAttributedString(string: "Charmed")
        case 3:
            return NSAttributedString(string: "Deafened")
        case 4:
            return NSAttributedString(string: "Frightened")
        case 5:
            return NSAttributedString(string: "Grappled")
        case 6:
            return NSAttributedString(string: "Incapacitated")
        case 7:
            return NSAttributedString(string: "Invisible")
        case 8:
            return NSAttributedString(string: "Paralyzed")
        case 9:
            return NSAttributedString(string: "Petrified")
        case 10:
            return NSAttributedString(string: "Poisoned")
        case 11:
            return NSAttributedString(string: "Prone")
        case 12:
            return NSAttributedString(string: "Restrained")
        case 13:
            return NSAttributedString(string: "Stunned")
        case 14:
            return NSAttributedString(string: "Unconcious")
        default:
            abort()
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            type = nil
        case 1:
            type = .Blinded
        case 2:
            type = .Charmed
        case 3:
            type = .Deafened
        case 4:
            type = .Frightened
        case 5:
            type = .Grappled
        case 6:
            type = .Incapacitated
        case 7:
            type = .Invisible
        case 8:
            type = .Paralyzed
        case 9:
            type = .Petrified
        case 10:
            type = .Poisoned
        case 11:
            type = .Prone
        case 12:
            type = .Restrained
        case 13:
            type = .Stunned
        case 14:
            type = .Unconcious
        default:
            abort()
        }
        
        addButton.enabled = (type != nil)
    }

}

//
//  DamageViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class DamageViewController: UITableViewController {
    
    @IBOutlet var addButton: UIBarButtonItem!
    
    var points: Int?
    var type: DamageType?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let pointsCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! PointsCell
        pointsCell.textField.becomeFirstResponder()
    }
    
    // MARK: Actions
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        points = Int(sender.text!)
        if points == nil {
            sender.textColor = UIColor.redColor()
        } else {
            sender.textColor = nil
        }
        addButton.enabled = (points != nil && type != nil)
    }

}

// MARK: UIPickerViewDataSource
extension DamageViewController: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 14
    }
    
}

// MARK: UIPickerViewDelegate
extension DamageViewController: UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch row {
        case 0:
            return NSAttributedString(string: "Damage Type", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        case 1:
            return NSAttributedString(string: "Acid")
        case 2:
            return NSAttributedString(string: "Bludgeoning")
        case 3:
            return NSAttributedString(string: "Cold")
        case 4:
            return NSAttributedString(string: "Fire")
        case 5:
            return NSAttributedString(string: "Force")
        case 6:
            return NSAttributedString(string: "Lightning")
        case 7:
            return NSAttributedString(string: "Necrotic")
        case 8:
            return NSAttributedString(string: "Piercing")
        case 9:
            return NSAttributedString(string: "Poison")
        case 10:
            return NSAttributedString(string: "Psychic")
        case 11:
            return NSAttributedString(string: "Radiant")
        case 12:
            return NSAttributedString(string: "Slashing")
        case 13:
            return NSAttributedString(string: "Thunder")
        default:
            abort()
        }
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            type = nil
        case 1:
            type = .Acid
        case 2:
            type = .Bludgeoning
        case 3:
            type = .Cold
        case 4:
            type = .Fire
        case 5:
            type = .Force
        case 6:
            type = .Lightning
        case 7:
            type = .Necrotic
        case 8:
            type = .Piercing
        case 9:
            type = .Poison
        case 10:
            type = .Psychic
        case 11:
            type = .Radiant
        case 12:
            type = .Slashing
        case 13:
            type = .Thunder
        default:
            abort()
        }
        
        addButton.enabled = (points != nil && type != nil)
    }
    
}

// MARK: -

class PointsCell: UITableViewCell {
    
    @IBOutlet var textField: UITextField!

}

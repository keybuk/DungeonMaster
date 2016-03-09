//
//  DamageViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class DamageViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
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

    // MARK: UIPickerViewDataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DamageType.cases.count + 1
    }
    
    // MARK: UIPickerViewDelegate
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch row {
        case 0:
            return NSAttributedString(string: "Damage Type", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        default:
            return NSAttributedString(string: DamageType(rawValue: row - 1)!.stringValue)
        }
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            type = nil
        default:
            type = DamageType(rawValue: row - 1)
        }
        
        addButton.enabled = (points != nil && type != nil)
    }
    
}

// MARK: -

class PointsCell: UITableViewCell {
    
    @IBOutlet var textField: UITextField!

}

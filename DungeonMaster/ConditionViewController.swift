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
        return sharedRules.conditionType.count + 1
    }

}

// MARK: UIPickerViewDelegate
extension ConditionViewController: UIPickerViewDelegate {

    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch row {
        case 0:
            return NSAttributedString(string: "Condition", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        default:
            return NSAttributedString(string: ConditionType(rawValue: row - 1)!.stringValue.capitalizedString)
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            type = nil
        default:
            type = ConditionType(rawValue: row - 1)
        }
        
        addButton.enabled = (type != nil)
    }

}

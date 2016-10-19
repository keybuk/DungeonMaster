//
//  ConditionViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/14/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class ConditionViewController : UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var addButton: UIBarButtonItem!

    var type: Condition?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Condition.cases.count + 1
    }

    // MARK: UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch row {
        case 0:
            return NSAttributedString(string: "Condition", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        default:
            return NSAttributedString(string: Condition(rawValue: row - 1)!.stringValue)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            type = nil
        default:
            type = Condition(rawValue: row - 1)
        }
        
        addButton.isEnabled = (type != nil)
    }

}

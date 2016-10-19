//
//  DamageViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/13/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class DamageViewController : UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet var addButton: UIBarButtonItem!
    
    var points: Int?
    var type: DamageType?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let pointsCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! PointsCell
        pointsCell.textField.becomeFirstResponder()
    }
    
    // MARK: Actions
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        points = Int(sender.text!)
        if points == nil {
            sender.textColor = UIColor.red
        } else {
            sender.textColor = nil
        }
        addButton.isEnabled = (points != nil && type != nil)
    }

    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DamageType.cases.count + 1
    }
    
    // MARK: UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch row {
        case 0:
            return NSAttributedString(string: "Damage Type", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        default:
            return NSAttributedString(string: DamageType(rawValue: row - 1)!.stringValue)
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            type = nil
        default:
            type = DamageType(rawValue: row - 1)
        }
        
        addButton.isEnabled = (points != nil && type != nil)
    }
    
}

// MARK: -

class PointsCell : UITableViewCell {
    
    @IBOutlet var textField: UITextField!

}

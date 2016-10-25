//
//  CombatantViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class CombatantViewController : UITableViewController, ManagedObjectObserverDelegate, UITextViewDelegate {

    /// The encounter combatant being shown and manipulated.
    var combatant: Combatant!
    
    var observer: NSObjectProtocol?
    
    var ignoreNextUpdate = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = self.editButtonItem

        observer = ManagedObjectObserver(object: combatant, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.isToolbarHidden = true
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RoleSegue" {
            let combatantRoleViewController = segue.destination as! CombatantRoleViewController
            combatantRoleViewController.role = combatant.role
        }
    }

    @IBAction func unwindFromRole(_ segue: UIStoryboardSegue) {
        let combatantRoleViewController = segue.source as! CombatantRoleViewController
        
        combatant.role = combatantRoleViewController.role!
        try! managedObjectContext.save()
    }
    
    @IBAction func unwindFromCondition(_ segue: UIStoryboardSegue) {
        let conditionViewController = segue.source as! ConditionViewController
        
        let _ = CombatantCondition(target: combatant, type: conditionViewController.type!, insertInto: managedObjectContext)
        try! managedObjectContext.save()
    }

    @IBAction func unwindFromDamage(_ segue: UIStoryboardSegue) {
        let damageViewController = segue.source as! DamageViewController
        
        let damage = CombatantDamage(target: combatant, points: damageViewController.points!, type: damageViewController.type!, insertInto: managedObjectContext)
        
        combatant.damagePoints += damage.points
        try! managedObjectContext.save()
    }
    
    // MARK: Actions
    
    @IBAction func hitPointsEditingChanged(_ sender: UITextField) {
        if let hitPoints = Int(sender.text!) {
            ignoreNextUpdate = true
            combatant.hitPoints = hitPoints
            try! managedObjectContext.save()
            sender.textColor = nil
        } else {
            sender.textColor = UIColor.red
        }
    }

    @IBAction func initiativeEditingChanged(_ sender: UITextField) {
        if let initiative = Int(sender.text!) {
            ignoreNextUpdate = true
            combatant.initiative = initiative
            try! managedObjectContext.save()
            sender.textColor = nil
        } else {
            sender.textColor = UIColor.red
        }
    }
    
    // MARK: UITableViewDataSource
    
    // MARK: Sections
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return combatant.role != .player ? 4 : 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // Name, Role, Initiative, Hit Points if DM.
            return combatant.role != .player ? 4 : 3
        case 1:
            return combatant.conditions.count + 1
        case 2 where combatant.role != .player:
            return combatant.damages.count + 1
        case 2 where combatant.role == .player, 3 where combatant.role != .player:
            return 1
        default:
            abort()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Conditions"
        case 2 where combatant.role != .player:
            return "Damage"
        case 2 where combatant.role == .player, 3 where combatant.role != .player:
            return "Notes"
        default:
            abort()
        }
    }
    
    // MARK: Rows
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath as NSIndexPath).section {
        case 0:
            switch (indexPath as NSIndexPath).row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CombatantNameCell", for: indexPath) as! CombatantNameCell
                cell.nameLabel.text = combatant.monster?.name ?? combatant.player?.name
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "RoleCell", for: indexPath)
                switch combatant.role {
                case .foe:
                    cell.textLabel?.text = "Foe"
                case .friend:
                    cell.textLabel?.text = "Friend"
                case .player:
                    cell.textLabel?.text = "Player"
                }
                if let _ = combatant.monster {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "DiceRollCell", for: indexPath) as! DiceRollCell
                if combatant.role != .player {
                    cell.diceCombo = combatant.monster!.initiativeDice
                } else {
                    cell.diceCombo = nil
                }
                cell.label.text = "Initiative"
                if let initiative = combatant.initiative {
                    cell.textField.text = "\(initiative)"
                } else {
                    cell.textField.text = "—"
                }
                cell.textField.addTarget(self, action: #selector(initiativeEditingChanged(_:)), for: .editingChanged)
                return cell
            case 3 where combatant.role != .player:
                let cell = tableView.dequeueReusableCell(withIdentifier: "DiceRollCell", for: indexPath) as! DiceRollCell
                cell.diceCombo = combatant.monster!.hitDice
                cell.label.text = "Hit Points"
                cell.textField.text = "\(combatant.hitPoints)"
                // Should read up on control events and figure out if this is right or not.
                cell.textField.addTarget(self, action: #selector(hitPointsEditingChanged(_:)), for: .editingChanged)
                return cell
            default:
                abort()
            }
        case 1:
            if (indexPath as NSIndexPath).row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddConditionCell", for: indexPath)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CombatantConditionCell", for: indexPath) as! CombatantConditionCell
                let condition = combatant.conditions.object(at: (indexPath as NSIndexPath).row - 1) as! CombatantCondition
                cell.condition = condition
                return cell
            }
        case 2 where combatant.role != .player:
            if (indexPath as NSIndexPath).row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddDamageCell", for: indexPath) as! AddDamageCell
                let hitPoints = combatant.hitPoints - combatant.damagePoints
                cell.hitPointsLabel.text = "\(hitPoints)"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CombatantDamageCell", for: indexPath) as! CombatantDamageCell
                let damageIndex = combatant.damages.count - (indexPath as NSIndexPath).row
                let damage = combatant.damages.object(at: damageIndex) as! CombatantDamage
                cell.damage = damage
                
                var hitPoints = combatant.hitPoints
                for index in 0..<damageIndex {
                    let damage = combatant.damages.object(at: index) as! CombatantDamage
                    hitPoints -= damage.points
                }
                hitPoints = max(hitPoints, 0)
                
                cell.hitPointsLabel.attributedText = NSAttributedString(string: "\(hitPoints)", attributes: [NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue])
                
                return cell
            }
        case 2 where combatant.role == .player, 3 where combatant.role != .player:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath) as! NotesCell
            cell.textView.text = combatant.notes
            return cell
        default:
            abort()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath as NSIndexPath).section {
        case 0, 1:
            fallthrough
        case 2 where combatant.role != .player:
            return 44.0
        case 2 where combatant.role == .player, 3 where combatant.role != .player:
            return 144.0
        default:
            abort()
        }
    }

    // MARK: Edit support
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch (indexPath as NSIndexPath).section {
        case 1:
            fallthrough
        case 2 where combatant.role != .player:
            return (indexPath as NSIndexPath).row > 0
        case 0:
            fallthrough
        case 2 where combatant.role == .player, 3 where combatant.role != .player:
            return false
        default:
            abort()
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).section {
        case 1:
            if (indexPath as NSIndexPath).row > 0 {
                let condition = combatant.conditions.object(at: (indexPath as NSIndexPath).row - 1) as! CombatantCondition
                managedObjectContext.delete(condition)
                try! managedObjectContext.save()
            }
        case 2 where combatant.role != .player:
            if (indexPath as NSIndexPath).row > 0 {
                let damage = combatant.damages.object(at: combatant.damages.count - (indexPath as NSIndexPath).row) as! CombatantDamage
                let points = damage.points
                managedObjectContext.delete(damage)
                
                combatant.damagePoints -= points
                try! managedObjectContext.save()
            }
        default:
            break
        }
    }

    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).section {
        case 1:
            if (indexPath as NSIndexPath).row > 0 {
                let cell = tableView.cellForRow(at: indexPath)! as! CombatantConditionCell
                let condition = cell.condition.type

                
                let conditionRulesViewController = storyboard?.instantiateViewController(withIdentifier: "ConditionRulesViewController") as! ConditionRulesViewController
                conditionRulesViewController.modalPresentationStyle = .popover
                
                conditionRulesViewController.popoverPresentationController?.sourceView = cell.contentView
                conditionRulesViewController.popoverPresentationController?.sourceRect = CGRect(x: cell.contentView.bounds.size.width, y: 0.0, width: 0.0, height: cell.bounds.size.height)

                conditionRulesViewController.condition = condition
                present(conditionRulesViewController, animated: true, completion: nil)
            }
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).section {
        case 0:
            switch (indexPath as NSIndexPath).row {
            case 2:
                fallthrough
            case 3 where combatant.role != .player:
                let cell = tableView.cellForRow(at: indexPath) as! DiceRollCell
                cell.textField.becomeFirstResponder()
            default:
                break
            }
        case 1:
            fallthrough
        case 
             2 where combatant.role != .player:
            // Handled by a segue action in the storyboard.
            break
        case 2 where combatant.role == .player, 3 where combatant.role != .player:
            let cell = tableView.cellForRow(at: indexPath) as! NotesCell
            cell.textView.becomeFirstResponder()
        default:
            break
        }
    }

    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(_ object: Combatant, changedForType type: ManagedObjectChangeType) {
        if !ignoreNextUpdate {
            tableView.reloadData()
        }
        ignoreNextUpdate = false
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        ignoreNextUpdate = true
        combatant.notes = textView.text
        try! managedObjectContext.save()
    }

}

// MARK: -

class CombatantNameCell : UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    
}

class DiceRollCell : UITableViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextField!
    @IBOutlet var button: UIButton!
    
    var diceCombo: DiceCombo? {
        didSet {
            if let diceCombo = diceCombo {
                button.setTitle("\(diceCombo.description)", for: UIControlState())
                button.isHidden = false
            } else {
                button.isHidden = true
            }
        }
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        PlaySound(.Dice)
        diceCombo = diceCombo!.reroll()
        textField.text = "\(diceCombo!.value)"
        // This seems a very hacky way to do this...
        textField.sendActions(for: .editingChanged)
    }
    
}

class NotesCell : UITableViewCell {
    
    @IBOutlet var textView: UITextView!

}

class CombatantConditionCell : UITableViewCell {

    var condition: CombatantCondition! {
        didSet {
            textLabel?.text = condition.type.stringValue
        }
    }

}

class AddDamageCell : UITableViewCell {
    
    @IBOutlet var hitPointsLabel: UILabel!

}

class CombatantDamageCell : UITableViewCell {
    
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var hitPointsLabel: UILabel!
    
    var damage: CombatantDamage! {
        didSet {
            pointsLabel.text = "\(damage.points)"
            typeLabel.text = damage.type.stringValue
        }
    }

}

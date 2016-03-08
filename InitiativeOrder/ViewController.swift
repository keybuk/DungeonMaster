//
//  ViewController.swift
//  InitiativeOrder
//
//  Created by Scott James Remnant on 2/7/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import DungeonKit
import UIKit

struct Combatant {
    var name: String
    var initiative: Int?
    var isCurrentTurn: Bool
    var isAlive: Bool
}

class ViewController: UIViewController, NetworkPeerDelegate, NetworkConnectionDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var roundLabel: UILabel!
    @IBOutlet var turnLabel: UILabel!
    @IBOutlet var nextLabel: UILabel!
    
    /// Our peer membership of the DungeonNet.
    var networkPeer: NetworkPeer?

    // Maintain a list of combatant information receive from the Dungeon Master.
    var combatants: [Combatant] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        
        networkPeer = NetworkPeer(type: .InitiativeOrder, name: "Initiative Order", acceptedTypes: [ .DungeonMaster ])
        networkPeer?.delegate = self
        networkPeer?.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        if networkPeer?.connections.count > 0 {
            // When there is a connection, display whose turn it is, and who would be up next.
            var lastTurnIndex: Array.Index? = nil
            for (index, combatant) in combatants.enumerate() {
                if combatant.isCurrentTurn {
                    if lastTurnIndex == nil {
                        turnLabel.text = combatant.name
                    }
                    lastTurnIndex = index
                }
            }
            
            let nextTurnIndex = lastTurnIndex.map({ $0 + 1 }) ?? 0
            if let nextCombatant = (combatants.suffixFrom(nextTurnIndex) + combatants.prefixUpTo(nextTurnIndex)).filter({ $0.isAlive }).first {
                nextLabel.text = nextCombatant.name
            } else {
                nextLabel.text = ""
            }

        } else {
            // When there is not a connection, clear the display and update the title to indicate that we're searching.
            navigationItem.title = "Searching for Dungeon Master"
            roundLabel.text = ""
            turnLabel.text = ""
            nextLabel.text = ""
        }
    }
    
    /// Called by the app delegate when the app goes into the background.
    func enterBackground() {
        networkPeer?.stop()
    }
    
    /// Called by the app delegate when the app returns to the foreground.
    func leaveBackground() {
        networkPeer?.start()
    }
    
    // MARK: NetworkPeerDelegate
    
    func networkPeer(peer: NetworkPeer, didEstablishConnection connection: NetworkConnection) {
        // Update the title now we're connected, so we say something until an encounter starts.
        navigationItem.title = "Connected"
        
        connection.delegate = self
    }
    
    // MARK: NetworkConnectionDelegate
    
    func connection(connection: NetworkConnection, didReceiveMessage message: NetworkMessage) {
        switch message {
        case let .BeginEncounter(title):
            combatants = []
            tableView.reloadData()
            navigationItem.title = title
        case let .InsertCombatant(toIndex, name, initiative, isCurrentTurn, isAlive):
            combatants.insert(Combatant(name: name, initiative: initiative, isCurrentTurn: isCurrentTurn, isAlive: isAlive), atIndex: toIndex)
            
            let indexPath = NSIndexPath(forRow: toIndex, inSection: 0)
            tableView.insertRowsAtIndexPaths([ indexPath ], withRowAnimation: .Automatic)
        case let .DeleteCombatant(fromIndex):
            combatants.removeAtIndex(fromIndex)
            
            let indexPath = NSIndexPath(forRow: fromIndex, inSection: 0)
            tableView.deleteRowsAtIndexPaths([ indexPath ], withRowAnimation: .Automatic)
        case let .MoveCombatant(fromIndex, toIndex):
            let combatant = combatants.removeAtIndex(fromIndex)
            combatants.insert(combatant, atIndex: toIndex)
            
            let fromIndexPath = NSIndexPath(forRow: fromIndex, inSection: 0)
            let toIndexPath = NSIndexPath(forRow: toIndex, inSection: 0)
            tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
        case let .UpdateCombatant(index, name, initiative, isCurrentTurn, isAlive):
            let combatant = Combatant(name: name, initiative: initiative, isCurrentTurn: isCurrentTurn, isAlive: isAlive)

            combatants.removeAtIndex(index)
            combatants.insert(combatant, atIndex: index)
            
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? CombatantCell {
                cell.combatant = combatant
            }
        case let .Round(round):
            roundLabel.text = "\(round)"
        default:
            break
        }
        
        configureView()
    }
    
    func connectionDidClose(connection: NetworkConnection) {
        navigationItem.title = "Lost Connection"
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return combatants.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CombatantCell", forIndexPath: indexPath) as! CombatantCell
        cell.combatant = combatants[indexPath.row]
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let combatant = combatants[indexPath.row]
        guard combatant.initiative == nil else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        // Prompt for the initiative using an alert view; it's not great UI, but it works for now.
        let controller = UIAlertController(title: "\(combatant.name)", message: "Enter initiative roll", preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            if let textField = controller.textFields?.first, textFieldText = textField.text, initiative = Int(textFieldText) {
                self.networkPeer?.broadcastMessage(.Initiative(name: combatant.name, initiative: initiative))
            }
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }))

        controller.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "1d20 + Dex"
            textField.text = combatant.initiative.map({ "\($0)" })
            textField.keyboardType = .NumberPad
            textField.delegate = self
        }
        
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // A hyphen is valid at the start of an empty string, or where replacing the start of the string.
        if string.hasPrefix("-") {
            return range.location == 0
        }
        
        // Otherwise only digits are valid.1
        let validSet = NSCharacterSet.decimalDigitCharacterSet()
        for character in string.unicodeScalars {
            if !validSet.longCharacterIsMember(character.value) {
                return false
            }
        }
        return true
    }

}

class CombatantCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var initiativeLabel: UILabel!

    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    var combatant: Combatant! {
        didSet {
            var attributes: [String: AnyObject] = [:]
            if !combatant.isAlive {
                attributes[NSStrikethroughStyleAttributeName] = NSUnderlineStyle.StyleSingle.rawValue
                attributes[NSForegroundColorAttributeName] = UIColor.lightGrayColor()
            }
            if combatant.isCurrentTurn {
                attributes[NSForegroundColorAttributeName] = UIColor.whiteColor()
                backgroundColor = tintColor
            } else {
                backgroundColor = UIColor.whiteColor()
            }
            
            nameLabel.attributedText = NSAttributedString(string: combatant.name, attributes: attributes)
            initiativeLabel.attributedText = NSAttributedString(string: combatant.initiative.map({ "\($0)" }) ?? "—", attributes: attributes)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        leadingConstraint.constant = editing ? 0.0 : (separatorInset.left - layoutMargins.left)
    }

}

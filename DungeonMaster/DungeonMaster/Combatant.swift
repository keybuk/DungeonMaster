//
//  Combatant.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/11/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import CoreGraphics
import Foundation

/// Combatant represents a creature, either a monster or a player character, involved in a combat encounter.
final class Combatant : NSManagedObject {

    /// Date that this object was created.
    ///
    /// This exists entirely as a sort criterion so that Encounter.combatants doesn't need to be an OrderedSet.
    @NSManaged var dateCreated: Date

    /// The encounter that this combatant is involved in.
    @NSManaged var encounter: Encounter
    
    /// The monster involved in the encounter.
    @NSManaged var monster: Monster?
    
    /// The player involved in the encounter.
    @NSManaged var player: Player?
    
    /// Role of the monster or player.
    var role: CombatRole {
        get {
            return CombatRole(rawValue: rawRole.intValue)!
        }
        set(newRole) {
            rawRole = NSNumber(newRole.rawValue)
        }
    }
    @NSManaged fileprivate var rawRole: NSNumber

    /// Combatant's initiative roll.
    ///
    /// This is optional up until the point that initiative has been rolled, at which point it should alway be set; to distinguish from a valid 0 initiative roll.
    var initiative: Int? {
        get {
            return rawInitiative?.intValue
        }
        set(newInitiative) {
            rawInitiative = newInitiative.map({ NSNumber(value: $0 as Int) })
            initiativeOrder = newInitiative.map({ _ in 0 })
        }
    }
    @NSManaged fileprivate var rawInitiative: NSNumber?
    
    /// Ordering of combatant within all those of the same initiative.
    var initiativeOrder: Int? {
        get {
            return rawInitiativeOrder?.intValue
        }
        set(newInitiativeOrder) {
            rawInitiativeOrder = newInitiativeOrder.map({ NSNumber(value: $0 as Int) })
        }
    }
    @NSManaged fileprivate var rawInitiativeOrder: NSNumber?
    
    /// True when this combatant is up next in the turn order.
    @NSManaged var isCurrentTurn: Bool

    /// Hit points for the combatant
    ///
    /// This is only meaningful for monsters controlled by the DM, it is ignored for those with a `role` of `Player`. It can be initialized from the monster's `hitDice`.
    var hitPoints: Int {
        get {
            return rawHitPoints.intValue
        }
        set(newHitPoints) {
            rawHitPoints = NSNumber(value: newHitPoints as Int)
        }
    }
    @NSManaged fileprivate var rawHitPoints: NSNumber
    
    /// Total damage points that the combatant has taken.
    ///
    /// This is only meaninful for monsters controlled by the DM, it is ignored for those with a `role` of `Player`.
    var damagePoints: Int {
        get {
            return rawDamagePoints.intValue
        }
        set(newDamagePoints) {
            rawDamagePoints = NSNumber(value: newDamagePoints as Int)
        }
    }
    @NSManaged fileprivate var rawDamagePoints: NSNumber
    
    /// Health of the combatant in the range 0.0...1.0.
    ///
    /// This is only meaninful for monsters controlled by the DM, it is ignored for those with a `role` of `Player`.
    var health: Float {
        return Float(max(hitPoints - damagePoints, 0)) / Float(hitPoints)
    }
    
    /// Returns whether the combatant is still alive.
    ///
    /// Always returns true for player-controlled combatants.
    var isAlive: Bool {
        return role == .player || damagePoints < hitPoints
    }

    /// Armor class of the combatant.
    ///
    /// This is only available for monsters controlled by the DM, it will always return `nil` for those with a `role` of `Player`.
    var armorClass: Int? {
        guard let monster = monster else { return nil }
        
        let basicArmorPredicate = NSPredicate(format: "rawCondition == nil")
        var armors = monster.armor.filtered(using: basicArmorPredicate)
        
        if conditions.count > 0 {
            let rawConditions = conditions.map({ NSNumber(value: ($0 as! CombatantCondition).type.rawValue as Int) })
            let conditionsPredicate = NSPredicate(format: "rawCondition IN %@", rawConditions)
            
            let conditionArmors = monster.armor.filtered(using: conditionsPredicate)
            if conditionArmors.count > 0 {
                armors = conditionArmors
            }
        }
        
        // Return the highest applicable AC.
        return armors.map({ ($0 as! Armor).armorClass }).max()
    }

    /// Location of the combatant on the table top.
    var location: TabletopLocation? {
        get {
            if let x = rawLocationX, let y = rawLocationY {
                return TabletopLocation(x: CGFloat(x.floatValue), y: CGFloat(y.floatValue))
            } else {
                return nil
            }
        }
        set(newLocation) {
            rawLocationX = newLocation.map({ NSNumber(value: Float($0.x) as Float) })
            rawLocationY = newLocation.map({ NSNumber(value: Float($0.y) as Float) })
        }
    }
    @NSManaged fileprivate var rawLocationX: NSNumber?
    @NSManaged fileprivate var rawLocationY: NSNumber?

    /// Damages that the combatant has taken.
    ///
    /// Each member is a `CombatantDamage`.
    @NSManaged var damages: NSOrderedSet
    
    /// Conditions currently applied to the combatant.
    ///
    /// Each member is a `CombatantCondition`.
    @NSManaged var conditions: NSOrderedSet

    /// Text notes relevant to this combatant.
    @NSManaged var notes: String?
    
    /// XP awards given for defeating this combatant.
    ///
    /// Each member is an `XPAward` linking to the player that received the award.
    @NSManaged var xpAwards: NSSet
    
    convenience init(encounter: Encounter, monster: Monster, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.Combatant, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.encounter = encounter
        self.monster = monster
        
        dateCreated = Date()
        hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
    }
    
    convenience init(encounter: Encounter, player: Player, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.Combatant, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.encounter = encounter
        self.player = player
        self.role = .player
        
        dateCreated = Date()
    }

    // MARK: Validation

    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    func validateConsistency() throws {
        // Combatant must be a monster or a player, never both.
        guard (monster != nil) != (player != nil) else {
            let errorString = "Combatant must have monster or player, not both or neither."
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Combatant", code: NSManagedObjectValidationError, userInfo: userDict)
        }
        
        // DM cannot control players directly.
        guard role == .player || player == nil else {
            let errorString = "Player Combatant must not be .Friend or .Foe."
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Combatant", code: NSManagedObjectValidationError, userInfo: userDict)
        }
    }

}

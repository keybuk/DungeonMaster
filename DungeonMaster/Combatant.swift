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
final class Combatant: NSManagedObject {

    /// Date that this object was created.
    ///
    /// This exists entirely as a sort criterion so that Encounter.combatants doesn't need to be an OrderedSet.
    @NSManaged var dateCreated: NSDate

    /// The encounter that this combatant is involved in.
    @NSManaged var encounter: Encounter
    
    /// The monster involved in the encounter.
    @NSManaged var monster: Monster?
    
    /// The player involved in the encounter.
    @NSManaged var player: Player?
    
    /// Role of the monster or player.
    var role: CombatRole {
        get {
            return CombatRole(rawValue: rawRole.integerValue)!
        }
        set(newRole) {
            rawRole = newRole.rawValue
        }
    }
    @NSManaged private var rawRole: NSNumber

    /// Combatant's initiative roll.
    ///
    /// This is optional up until the point that initiative has been rolled, at which point it should alway be set; to distinguish from a valid 0 initiative roll.
    var initiative: Int? {
        get {
            return rawInitiative?.integerValue
        }
        set(newInitiative) {
            rawInitiative = newInitiative.map({ NSNumber(integer: $0) })
            initiativeOrder = newInitiative.map({ _ in 0 })
        }
    }
    @NSManaged private var rawInitiative: NSNumber?
    
    /// Ordering of combatant within all those of the same initiative.
    var initiativeOrder: Int? {
        get {
            return rawInitiativeOrder?.integerValue
        }
        set(newInitiativeOrder) {
            rawInitiativeOrder = newInitiativeOrder.map({ NSNumber(integer: $0) })
        }
    }
    @NSManaged private var rawInitiativeOrder: NSNumber?
    
    /// True when this combatant is up next in the turn order.
    @NSManaged var isCurrentTurn: Bool

    /// Hit points for the combatant
    ///
    /// This is only meaningful for monsters controlled by the DM, it is ignored for those with a `role` of `Player`. It can be initialized from the monster's `hitDice`.
    var hitPoints: Int {
        get {
            return rawHitPoints.integerValue
        }
        set(newHitPoints) {
            rawHitPoints = NSNumber(integer: newHitPoints)
        }
    }
    @NSManaged private var rawHitPoints: NSNumber
    
    /// Total damage points that the combatant has taken.
    ///
    /// This is only meaninful for monsters controlled by the DM, it is ignored for those with a `role` of `Player`.
    var damagePoints: Int {
        get {
            return rawDamagePoints.integerValue
        }
        set(newDamagePoints) {
            rawDamagePoints = NSNumber(integer: newDamagePoints)
        }
    }
    @NSManaged private var rawDamagePoints: NSNumber
    
    /// Health of the combatant in the range 0.0...1.0.
    ///
    /// This is only meaninful for monsters controlled by the DM, it is ignored for those with a `role` of `Player`.
    var health: Float {
        return Float(max(hitPoints - damagePoints, 0)) / Float(hitPoints)
    }

    /// Armor class of the combatant.
    ///
    /// This is only available for monsters controlled by the DM, it will always return `nil` for those with a `role` of `Player`.
    var armorClass: Int? {
        guard let monster = monster else { return nil }
        
        let basicArmorPredicate = NSPredicate(format: "rawCondition == nil")
        var armors = monster.armor.filteredSetUsingPredicate(basicArmorPredicate)
        
        if conditions.count > 0 {
            let rawConditions: [NSNumber] = conditions.map({ NSNumber(integer: ($0 as! CombatantCondition).type.rawValue) })
            let conditionsPredicate = NSPredicate(format: "rawCondition IN %@", rawConditions)
            
            let conditionArmors = monster.armor.filteredSetUsingPredicate(conditionsPredicate)
            if conditionArmors.count > 0 {
                armors = conditionArmors
            }
        }
        
        // Return the highest applicable AC.
        return armors.map({ ($0 as! Armor).armorClass }).maxElement()
    }

    /// Location of the combatant on the table top.
    var location: TabletopLocation? {
        get {
            if let x = rawLocationX, y = rawLocationY {
                return TabletopLocation(x: CGFloat(x.floatValue), y: CGFloat(y.floatValue))
            } else {
                return nil
            }
        }
        set(newLocation) {
            rawLocationX = newLocation.map({ NSNumber(float: Float($0.x)) })
            rawLocationY = newLocation.map({ NSNumber(float: Float($0.y)) })
        }
    }
    @NSManaged private var rawLocationX: NSNumber?
    @NSManaged private var rawLocationY: NSNumber?

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
    
    convenience init(encounter: Encounter, monster: Monster, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Combatant, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.encounter = encounter
        self.monster = monster
        
        dateCreated = NSDate()
        hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
    }
    
    convenience init(encounter: Encounter, player: Player, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Combatant, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.encounter = encounter
        self.player = player
        self.role = .Player
        
        dateCreated = NSDate()
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
        guard role == .Player || player == nil else {
            let errorString = "Player Combatant must not be .Friend or .Foe."
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Combatant", code: NSManagedObjectValidationError, userInfo: userDict)
        }
    }

}

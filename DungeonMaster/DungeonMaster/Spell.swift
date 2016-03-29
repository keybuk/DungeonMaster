//
//  Spell.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/29/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// Spell represents a spell that can be cast by monsters or players.
final class Spell : NSManagedObject {

    /// Name for the spell.
    @NSManaged var name: String
    
    /// First initial of the spell's name, used for section and index titles in the spells list.
    var nameInitial: String {
        return String(name.characters[name.characters.startIndex])
    }
    
    /// Source material for the spell.
    ///
    /// Each member is a `Source` containing a reference to the specific book, supplement, etc. the spell text can be found in, the page number, and the section if relevant.
    @NSManaged var sources: NSSet
    
    /// Character classes that may cast this spell.
    ///
    /// Each member is a `SpellClass`.
    @NSManaged var classes: NSSet

    /// Level of the spell.
    ///
    /// Cantrips have a level of 0 (consistent with the lists created by WotC).
    var level: Int {
        get {
            return rawLevel.integerValue
        }
        set(newLevel) {
            rawLevel = NSNumber(integer: newLevel)
        }
    }
    @NSManaged private var rawLevel: NSNumber
    
    /// School of magic the spell is associated with.
    var school: MagicSchool {
        get {
            return MagicSchool(rawValue: rawSchool.integerValue)!
        }
        set(newSchool) {
            rawSchool = NSNumber(integer: newSchool.rawValue)
        }
    }
    @NSManaged private var rawSchool: NSNumber
    
    /// True if the spell can be cast as a ritual.
    @NSManaged var canCastAsRitual: Bool
    
    /// True if the spell can be cast as an action on a creature's turn.
    @NSManaged var canCastAsAction: Bool
    
    /// True if the spell can be cast as a bonus action on a creature's turn.
    @NSManaged var canCastAsBonusAction: Bool
    
    /// True if the spell can be cast as a reaction outside of a creature's normal turn.
    ///
    /// `reactionResponse` gives the criteria for this reaction being triggered.
    @NSManaged var canCastAsReaction: Bool
    
    /// Criteria for when the spell can be cast as a reaction.
    @NSManaged var reactionResponse: String?
    
    /// Time the spell takes to cast (in minutes).
    ///
    /// This is usually present when the spell can otherwise not be cast during an action, bonus action, or reaction; but it may be present as an alternative to an action.
    var castingTime: Int? {
        get {
            return rawCastingTime?.integerValue
        }
        set(newCastingTime) {
            rawCastingTime = newCastingTime.map({ NSNumber(integer: $0) })
        }
    }
    @NSManaged private var rawCastingTime: NSNumber?
    
    /// General category of the range of the spell.
    ///
    /// When this is `Distance` or `CenteredOnSelf`, further details are given in `rangeDistance` and `rangeShape`.
    var range: SpellRange {
        get {
            return SpellRange(rawValue: rawRange.integerValue)!
        }
        set(newRange) {
            rawRange = NSNumber(integer: newRange.rawValue)
        }
    }
    @NSManaged private var rawRange: NSNumber
    
    /// Range of the spell (in feet).
    ///
    /// This is present when `range` is `.Distance` or `.CenteredOnSelf`.
    var rangeDistance: Int? {
        get {
            return rawRangeDistance?.integerValue
        }
        set(newRangeDistance) {
            rawRangeDistance = newRangeDistance.map({ NSNumber(integer: $0) })
        }
        
    }
    @NSManaged private var rawRangeDistance: NSNumber?
    
    /// Shape of the spell.
    ///
    /// This is present when `range` is `.CenteredOnSelf` and describes the shape of the effect.
    var rangeShape: SpellRangeShape? {
        get {
            return rawRangeShape.map({ SpellRangeShape(rawValue: $0.integerValue)! })
        }
        set(newRangeShape) {
            rawRangeShape = newRangeShape.map({ NSNumber(integer: $0.rawValue) })
        }
    }
    @NSManaged private var rawRangeShape: NSNumber?
    
    /// True when the spell has a verbal component.
    @NSManaged var hasVerbalComponent: Bool
    
    /// True when the spell has a somatic component.
    @NSManaged var hasSomaticComponent: Bool
    
    /// True when the spell has a material component.
    ///
    /// The description of the component is available in `materialComponent`.
    @NSManaged var hasMaterialComponent: Bool
    
    /// Description of the spell's material component.
    @NSManaged var materialComponent: String?
    
    /// General category of the duration of the spell.
    var duration: SpellDuration {
        get {
            return SpellDuration(rawValue: rawDuration.integerValue)!
        }
        set(newDuration) {
            rawDuration = NSNumber(integer: newDuration.rawValue)
        }
    }
    @NSManaged var rawDuration: NSNumber
    
    /// Duration of the spell (in minutes or rounds).
    ///
    /// Present, and in minutes, when `duration` is `.Time` or `.MaxTime`; present, and in rounds, when `duration` is `.Rounds` or `.MaxRounds`.
    var durationTime: Int? {
        get {
            return rawDurationTime?.integerValue
        }
        set(newDurationTime) {
            rawDurationTime = newDurationTime.map({ NSNumber(integer: $0) })
        }
    }
    @NSManaged private var rawDurationTime: NSNumber?
    
    /// True if the spell requires concentration throughout its duration.
    ///
    /// Only ever `true` when `duration` is `MaxTime`, since concentration spells cannot force a fixed time.
    @NSManaged var requiresConcentration: Bool
    
    /// Text description accompanying the spell.
    @NSManaged var text: String

    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Spell, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
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
        // Spell must have reactionResponse when canCastAsReaction is true, and vice-versa.
        guard canCastAsReaction == (reactionResponse != nil) else {
            let errorString = "Spell must have, and only have, reactionResponse when canCastAsReaction is true."
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Spell", code: NSManagedObjectValidationError, userInfo: userDict)
        }
    
        // Spell must have materialComponent when hasMaterialComponent is true, and vice-versa.
        guard hasMaterialComponent == (materialComponent != nil) else {
            let errorString = "Spell must have, and only have, materialComponent when hasMaterialComponent is true."
            let userDict = [ NSLocalizedDescriptionKey: errorString ]
            throw NSError(domain: "Spell", code: NSManagedObjectValidationError, userInfo: userDict)
        }        
    }

}

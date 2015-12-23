//
//  PlayerSkill.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// PlayerSkill represents a skill that the player is proficient in.
final class PlayerSkill: NSManagedObject {
    
    /// Player character that this proficiency applies to.
    @NSManaged var player: Player
    
    /// Skill that the player is proficient in.
    var skill: Skill {
        get {
            return Skill(rawAbilityValue: rawAbility.integerValue, rawSkillValue: rawSkill.integerValue)!
        }
        set(newSkill) {
            rawAbility = NSNumber(integer: newSkill.rawAbilityValue)
            rawSkill = NSNumber(integer: newSkill.rawSkillValue)
        }
    }
    @NSManaged private var rawAbility: NSNumber
    @NSManaged private var rawSkill: NSNumber
    
    convenience init(player: Player, skill: Skill, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.PlayerSkill, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.player = player
        self.skill = skill
    }
    
}

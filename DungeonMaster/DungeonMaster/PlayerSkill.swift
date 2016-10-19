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
final class PlayerSkill : NSManagedObject {
    
    /// Player character that this proficiency applies to.
    @NSManaged var player: Player
    
    /// Skill that the player is proficient in.
    var skill: Skill {
        get {
            return Skill(rawAbilityValue: rawAbility.intValue, rawSkillValue: rawSkill.intValue)!
        }
        set(newSkill) {
            rawAbility = NSNumber(value: newSkill.rawAbilityValue as Int)
            rawSkill = NSNumber(value: newSkill.rawSkillValue as Int)
        }
    }
    @NSManaged fileprivate var rawAbility: NSNumber
    @NSManaged fileprivate var rawSkill: NSNumber
    
    convenience init(player: Player, skill: Skill, insertInto context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forModel: Model.PlayerSkill, in: context)
        self.init(entity: entity, insertInto: context)
        
        self.player = player
        self.skill = skill
    }
    
}

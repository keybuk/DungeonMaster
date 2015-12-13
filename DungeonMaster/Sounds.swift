//
//  Sounds.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/12/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import AudioToolbox

func DiceRollSound() {
    if let soundFileURL = NSBundle.mainBundle().URLForResource("dice", withExtension: "caf") {
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundFileURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}

//
//  Sounds.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/12/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import AudioToolbox
import Foundation

enum Sound : String {
    case Dice = "dice"
    case Initiative = "initiative"
}

func PlaySound(sound: Sound) {
    if let soundFileURL = NSBundle.mainBundle().URLForResource(sound.rawValue, withExtension: "caf", subdirectory: "Sounds") {
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundFileURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}

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

func PlaySound(_ sound: Sound) {
    if let soundFileURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf", subdirectory: "Sounds") {
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundFileURL as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}

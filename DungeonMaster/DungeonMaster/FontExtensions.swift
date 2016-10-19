//
//  FontExtensions.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 2/23/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

extension UIFont {
    
    /// Returns the equivalent font of the receiver, but with monospaced digits.
    var monospacedDigitFont: UIFont {
        let oldFontDescriptor = fontDescriptor
        let newFontDescriptor = oldFontDescriptor.monospacedDigitFontDescriptor
        return UIFont(descriptor: newFontDescriptor, size: 0)
    }
    
}

extension UIFontDescriptor {

    /// Returns the equivalent font descriptor of the receiver, but with the monospaced digits feature enabled.
    var monospacedDigitFontDescriptor: UIFontDescriptor {
        let fontDescriptorFeatureSettings = [[UIFontFeatureTypeIdentifierKey: kNumberSpacingType, UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptorFeatureSettingsAttribute: fontDescriptorFeatureSettings]
        let fontDescriptor = self.addingAttributes(fontDescriptorAttributes)
        return fontDescriptor
    }
    
}

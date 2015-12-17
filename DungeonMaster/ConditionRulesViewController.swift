//
//  ConditionRulesViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/16/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class ConditionRulesViewController: UIViewController {

    @IBOutlet var textView: UITextView!
    
    var condition: ConditionType!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let text = NSTextStorage()
        
        let nameFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline)
        
        let nameParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        nameParaStyle.paragraphSpacing = 6.0
        
        let nameStyle = [
            NSFontAttributeName: UIFont(descriptor: nameFont, size: 0.0),
            NSParagraphStyleAttributeName: nameParaStyle
        ]

        let name = condition.rawValue.capitalizedString
        text.appendAttributedString(NSAttributedString(string: "\(name)\n", attributes: nameStyle))

        
        let bodyFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
        
        let listParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        listParaStyle.headIndent = 20.0
        listParaStyle.tabStops = [
            NSTextTab(textAlignment: .Left, location: 20.0, options: [String:AnyObject]()),
        ]

        let listStyle = [
            NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
            NSParagraphStyleAttributeName: listParaStyle
        ]
        
        
        let filename = NSBundle.mainBundle().pathForResource("Rules", ofType: "plist")!
        let rulesData = NSDictionary(contentsOfFile: filename)!
        
        let conditions = rulesData["conditions"]! as! [String: [String]]

        for ruleText in conditions[condition.rawValue]! {
            text.appendAttributedString(NSAttributedString(string: "•\t\(ruleText)\n", attributes: listStyle))
        }

        // Set the text with scroll disabled to stop it going to the bottom.
        textView.scrollEnabled = false
        textView.attributedText = text
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Enable scrolling, doing this earlier just scrolls to the bottom again.
        textView.scrollEnabled = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

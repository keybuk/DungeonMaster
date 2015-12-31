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
    
    var condition: Condition! {
        didSet {
            guard textView != nil else { return }
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable scrolling, otherwise we end up at the bottom.
        textView.scrollEnabled = false
        configureView()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Enable scrolling, doing this earlier just scrolls to the bottom again.
        textView.scrollEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        let markupParser = MarkupParser()
        markupParser.tableWidth = textView.frame.size.width
        markupParser.linkColor = textView.tintColor
        
        markupParser.parse("***\(condition.stringValue)***")
        markupParser.parse(condition.rulesDescription)
        
        textView.attributedText = markupParser.text
    }

}

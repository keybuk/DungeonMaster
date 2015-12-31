//
//  MarkupParserTest.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/27/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import XCTest
@testable import DungeonMaster

class MarkupParserTest: XCTestCase {
    
    // MARK: - Basic functionality
    
    func testParseOneLines() {
        let lines = [ "This is a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
    }
    
    func testParseMultipleLines() {
        let lines = [ "This is a test", "and so is this." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
    }
    
    func testParseOneLine() {
        let markupParser = MarkupParser()
        markupParser.parse("This is a test")
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
    }
    
    func testParseMultipleLine() {
        let markupParser = MarkupParser()
        markupParser.parse("This is a test")
        markupParser.parse("and so is this.")
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
    }
    
    func testParseEmbeddedNewline() {
        let markupParser = MarkupParser()
        markupParser.parse("This is a test\nand so is this.")
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
    }
    
    func testReset() {
        let markupParser = MarkupParser()
        markupParser.parse("This is a test")
        markupParser.reset()
        markupParser.parse("and so is this.")
        
        XCTAssertEqual(markupParser.text.string, "and so is this.\n")
    }
    
    func testParseText() {
        let line = "This is a test"
        
        let markupParser = MarkupParser()
        let text = markupParser.parseText(line, attributes: [String:AnyObject](), features: .All, appendNewline: false)
        
        XCTAssertEqual(markupParser.text.string, "")
        XCTAssertEqual(text.string, "This is a test")
    }

    // MARK: - Blocks
    
    // MARK: Basic paragraphs
    
    func testOneLineString() {
        let lines = [ "This is a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)

        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        let style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }
    
    func testMultipleLineString() {
        let lines = [ "This is a test", "and so is this." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)

        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }
    
    func testBlankLine() {
        let lines = [ "This is a test", "", "and so is this." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }

    func testParagraphSpacingBefore() {
        let lines = [ "This is a test", "and so is this." ]
        
        let markupParser = MarkupParser()
        markupParser.paragraphSpacingBefore = markupParser.paragraphSpacing
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }
    
    // MARK: Indented paragraphs
    
    func testIndented() {
        let lines = [ "} This is a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        let style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }

    // MARK: Headings
    
    func testHeadingAtStart() {
        let lines = [ "# This is a test", "And this is the text." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nAnd this is the text.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 22)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 15, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 22)
    }
    
    func testHeadingAfterText() {
        let lines = [ "Previous text.", "# This is a test", "And this is the text." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Previous text.\nThis is a test\nAnd this is the text.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 15)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 15, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 30, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 30)
        XCTAssertEqual(range.length, 22)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 30, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 30)
        XCTAssertEqual(range.length, 22)
    }
    
    func testTwoHeadings() {
        let lines = [ "# This is a test", "# And so is this." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nAnd so is this.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 15, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }

    // MARK: Bulleted lists

    func testBulletItem() {
        let lines = [ "• Daddy" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "•\tDaddy\n")

        var range = NSRange()
        let style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
    }
    
    func testMultipleBulletItems() {
        let lines = [ "• Daddy", "• Chips" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "•\tDaddy\n•\tChips\n")
        
        // The complete bulleted list should end up in a single paragraph block, since there's no change to the attributes.
        var range = NSRange()
        let style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
    }
    
    // MARK: Tables
    
    func testSimpleTable() {
        let lines = [ "State | Capital", "Idaho | Boise", "California | Sacramento" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)

        XCTAssertEqual(markupParser.text.string, "\tState\tCapital\n\tIdaho\tBoise\n\tCalifornia\tSacramento\n")
        
        // The first line of the table is the heading, and should be covered by a single style with a bold font and tab stops for each column.
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[1].location, markupParser.tableSpacing * 2)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        let headingTabStops = style!.tabStops
        
        // The next two lines of the table are the body, with a non-bold font. The tab stops must match the heading ones.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 13)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 15, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 13)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 28, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(range.location, 28)
        XCTAssertEqual(range.length, 23)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 28, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 28)
        XCTAssertEqual(range.length, 23)
    }
    
    func testNumericTable() {
        let lines = [ "State | Year Joined | Capital", "Idaho | 1890 | Boise", "California | 1850 | Sacramento" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "\tState\tYear Joined\tCapital\n\tIdaho\t1890\tBoise\n\tCalifornia\t1850\tSacramento\n")
        
        // The first line of the table is the heading, and should be covered by a single style with a bold font and tab stops for each column. The middle column should be centered.
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Center)
        XCTAssertGreaterThan(style!.tabStops[1].location, markupParser.tableSpacing * 2)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[2].location, markupParser.tableSpacing * 3)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 27)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 27)
        
        let headingTabStops = style!.tabStops
        
        // The next two lines of the table are the body, with a non-bold font. The tab stops must match the heading ones.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 27, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Center)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[2].location, headingTabStops[2].location)
        XCTAssertEqual(range.location, 27)
        XCTAssertEqual(range.length, 18)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 27, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 27)
        XCTAssertEqual(range.length, 18)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 45, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Center)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[2].location, headingTabStops[2].location)
        XCTAssertEqual(range.location, 45)
        XCTAssertEqual(range.length, 28)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 45, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 45)
        XCTAssertEqual(range.length, 28)
    }
    
    func testFillTable() {
        let lines = [ "Foo | FooFoo | Foo", "foo | foofoo | foo", "foo | foofoo | foo" ]
        
        let markupParser = MarkupParser()
        markupParser.tableWidth = 300.0 + 4 * markupParser.tableSpacing
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "\tFoo\tFooFoo\tFoo\n\tfoo\tfoofoo\tfoo\n\tfoo\tfoofoo\tfoo\n")
        
        // The left and right colum should be equally sized, and the middle column twice the width.
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThanOrEqual(style!.tabStops[1].location, markupParser.tableSpacing * 2 + 75.0)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThanOrEqual(style!.tabStops[2].location, markupParser.tableSpacing * 3 + 225.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        let headingTabStops = style!.tabStops
        
        // Body should otherwise match.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[2].location, headingTabStops[2].location)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 16)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 16, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 16)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 32, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[2].location, headingTabStops[2].location)
        XCTAssertEqual(range.location, 32)
        XCTAssertEqual(range.length, 16)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 32, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 32)
        XCTAssertEqual(range.length, 16)
    }
    
    func testFillTableWithNumeric() {
        let lines = [ "Foo | Foo", "1 | foo", "2 | foo" ]
        
        let markupParser = MarkupParser()
        markupParser.tableWidth = 300.0 + 3 * markupParser.tableSpacing
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "\tFoo\tFoo\n\t1\tfoo\n\t2\tfoo\n")
        
        // Only the right column should be expanded, since the left is numeric.
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Center)
        XCTAssertGreaterThan(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertLessThan(style!.tabStops[1].location, markupParser.tableSpacing * 2 + 150.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 9)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 9)
        
        let headingTabStops = style!.tabStops
        
        // Body should otherwise match.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 9, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Center)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(range.location, 9)
        XCTAssertEqual(range.length, 7)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 9, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 9)
        XCTAssertEqual(range.length, 7)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Center)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 7)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 16, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 7)
    }

    func testCollapseTableWithOverlong() {
        let lines = [ "d6 | Description | Race",
            "1 | This is a very long description that should cause the table to overflow the bounds of its line | Dwarf", "2 | Huh | Elf" ]
        
        let markupParser = MarkupParser()
        markupParser.tableWidth = 300.0
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "\td6\tDescription\tRace\n\t1\tThis is a very long\tDwarf\n\t\tdescription that should\n\t\tcause the table to overflow\n\t\tthe bounds of its line\n\t2\tHuh\tElf\n")
        
        // The left and right columns should be smaller than the middle
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Center)
        XCTAssertGreaterThan(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertLessThanOrEqual(style!.tabStops[1].location, markupParser.tableSpacing * 2 + 75.0)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThanOrEqual(style!.tabStops[2].location, markupParser.tableSpacing * 3 + 200.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 21)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 21)
        
        let headingTabStops = style!.tabStops
        
        // The first logical row paragraph style should extend over the entire text, including the broken column on separate physical lines.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 21, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Center)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[2].location, headingTabStops[2].location)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 110)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 21, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 110)

        // Second logical row matches the physical one.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 131, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Center)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[2].location, headingTabStops[2].location)
        XCTAssertEqual(range.location, 131)
        XCTAssertEqual(range.length, 11)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 131, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 131)
        XCTAssertEqual(range.length, 11)
    }

    // MARK: Mixed blocks
    
    func testIndentedAfterText() {
        let lines = [ "This is a test", "} and so is this." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }
    
    func testIndentedAfterHeading() {
        let lines = [ "# This is a test", "} and so is this." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }
    
    func testIndentedBetweenText() {
        let lines = [ "This is a test", "} and so is this.", "And this." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\nand so is this.\nAnd this.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 31, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 31)
        XCTAssertEqual(range.length, 10)
    }

    func testBulletAfterText() {
        let lines = [ "Choose between:", "• Daddy", "• Chips" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Choose between:\n•\tDaddy\n•\tChips\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)

        // Bulleted list gets broken in two, because the first item gains paragraph spacing.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 8)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 24, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 24)
        XCTAssertEqual(range.length, 8)
    }
    
    func testBulletAfterHeading() {
        let lines = [ "# Choose between", "• Daddy", "• Chips" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Choose between\n•\tDaddy\n•\tChips\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        // Bulleted list no longer gets broken in two, because no paragraph spacing after heading.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }

    func testBulletBeforeText() {
        let lines = [ "• Daddy", "• Chips", "There are no other alternatives." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "•\tDaddy\n•\tChips\nThere are no other alternatives.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 33)
    }

    func testBulletsBetweenText() {
        let lines = [ "Choose between:", "• Daddy", "• Chips", "There are no other alternatives." ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Choose between:\n•\tDaddy\n•\tChips\nThere are no other alternatives.\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        // Bulleted list gets broken in two, because the first item gains paragraph spacing.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 8)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 24, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 24)
        XCTAssertEqual(range.length, 8)
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 32, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 32)
        XCTAssertEqual(range.length, 33)
    }

    func testTableAfterText() {
        let lines = [ "Some text", "Foo | Bar", "foo | bar" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Some text\n\tFoo\tBar\n\tfoo\tbar\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)

        // Table gets broken in two, first for the heading:
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 10, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[1].location, markupParser.tableSpacing * 2)
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        let headingTabStops = style!.tabStops

        // and then for the body.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 19, effectiveRange: &range) as? NSParagraphStyle

        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(range.location, 19)
        XCTAssertEqual(range.length, 9)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 19, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 19)
        XCTAssertEqual(range.length, 9)
    }
    
    func testTableAfterHeading() {
        let lines = [ "# Some text", "Foo | Bar", "foo | bar" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Some text\n\tFoo\tBar\n\tfoo\tbar\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        // Table gets broken in two, first for the heading:
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 10, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[1].location, markupParser.tableSpacing * 2)
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        let headingTabStops = style!.tabStops
        
        // and then for the body.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 19, effectiveRange: &range) as? NSParagraphStyle
        
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(range.location, 19)
        XCTAssertEqual(range.length, 9)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 19, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 19)
        XCTAssertEqual(range.length, 9)
    }

    func testTableBetweenText() {
        let lines = [ "Some text", "Foo | Bar", "foo | bar", "More text" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Some text\n\tFoo\tBar\n\tfoo\tbar\nMore text\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        // Table gets broken in two, first for the heading:
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 10, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[1].location, markupParser.tableSpacing * 2)
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        let headingTabStops = style!.tabStops
        
        // and then for the body.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 19, effectiveRange: &range) as? NSParagraphStyle
        
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, headingTabStops[0].location)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, headingTabStops[1].location)
        XCTAssertEqual(range.location, 19)
        XCTAssertEqual(range.length, 9)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 19, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 19)
        XCTAssertEqual(range.length, 9)
        
        // Text following table should have paragraph spacing.
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 28, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, markupParser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 28)
        XCTAssertEqual(range.length, 10)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 28, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 28)
        XCTAssertEqual(range.length, 10)
    }

    // MARK: - Inline style
    
    // MARK: Emphasis

    func testItalicsAtStart() {
        let lines = [ "*Title,* This is a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Title, This is a test\n")

        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 6)

        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 6, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 6)
        XCTAssertEqual(range.length, 16)
    }
    
    func testItalicsInMiddle() {
        let lines = [ "This *is* a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 5, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 5)
        XCTAssertEqual(range.length, 2)

        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 7, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }
    
    func testItalicsAtEnd() {
        let lines = [ "This is a *test*" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 4)
        
        // Final attribute for the newline.
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 14, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testItalicsWholeString() {
        let lines = [ "*This is a test*" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")

        var range = NSRange()
        let font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }

    func testBoldAtStart() {
        let lines = [ "**Title.** This is a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Title. This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 6)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 6, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 6)
        XCTAssertEqual(range.length, 16)
    }
    
    func testBoldInMiddle() {
        let lines = [ "This **is** a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 5, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 5)
        XCTAssertEqual(range.length, 2)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 7, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }
    
    func testBoldAtEnd() {
        let lines = [ "This is a **test**" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 4)
        
        // Final attribute for the newline.
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 14, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }
    
    func testBoldWholeString() {
        let lines = [ "**This is a test**" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        let font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }
    
    func testBoldItalicsAtStart() {
        let lines = [ "***Title.*** This is a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "Title. This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 6)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 6, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 6)
        XCTAssertEqual(range.length, 16)
    }
    
    func testBoldItalicsInMiddle() {
        let lines = [ "This ***is*** a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 5, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 5)
        XCTAssertEqual(range.length, 2)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 7, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }
    
    func testBoldItalicsAtEnd() {
        let lines = [ "This is a ***test***" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 4)
        
        // Final attribute for the newline.
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 14, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testBoldItalicsWholeString() {
        let lines = [ "***This is a test***" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        let font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }

    // MARK: Quoted stings
    
    func testQuotedStringAtStart() {
        let lines = [ "\"This is\" a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "“This is” a test\n")
    }

    func testQuotedStringInMiddle() {
        let lines = [ "This is a \"test string\" containing a quote" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a “test string” containing a quote\n")
    }
    
    func testQuotedStringAtEnd() {
        let lines = [ "This is \"a test\"" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is “a test”\n")
    }

    func testQuotedWholeString() {
        let lines = [ "\"This is a test\"" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        // In contrast to emphasis, the newline should be still outside the quote.
        XCTAssertEqual(markupParser.text.string, "“This is a test”\n")
    }
    
    // MARK: Single quotes

    func testSingleQuote() {
        let lines = [ "This is' a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is’ a test\n")
    }

    // MARK: Links

    func testLinkAtStart() {
        let lines = [ "[This is] a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertEqual(link, "This is")
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 7)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 7, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }

    func testLinkInMiddle() {
        let lines = [ "This is a [test string] containing a link" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test string containing a link\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 11)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 21, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 19)
    }

    func testLinkAtEnd() {
        let lines = [ "This is [a test]" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)

        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 8, effectiveRange: &range) as? String
        XCTAssertEqual(link, "a test")
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 6)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 14, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testLinkWholeString() {
        let lines = [ "[This is a test]" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 8, effectiveRange: &range) as? String
        XCTAssertEqual(link, "This is a test")
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 14)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 14, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testLinkAlternateText() {
        let lines = [ "This is a [test string](thing) containing a link" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a thing containing a link\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 5)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 15, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 19)
    }
    
    func testLinkWithColor() {
        let lines = [ "This is a [test string] containing a link" ]
        
        let markupParser = MarkupParser()
        markupParser.linkColor = UIColor.redColor()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test string containing a link\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 11)
        
        let color = markupParser.text.attribute(NSForegroundColorAttributeName, atIndex: 10, effectiveRange: &range) as? UIColor
        XCTAssertNotNil(color)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 21, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 19)
    }

    // MARK: Mixed inline styles
    
    func testEmphasisInQuotedString() {
        let lines = [ "This is a \"test with *emphasis* in the quoted\" string" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a “test with emphasis in the quoted” string\n")

        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 21)

        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 21, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 8)

        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 29, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 29)
        XCTAssertEqual(range.length, 23)
    }
    
    func testLinkWithSingleQuote() {
        let lines = [ "This is a [test' string] containing a link" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        // Output should be a smart quote.
        XCTAssertEqual(markupParser.text.string, "This is a test’ string containing a link\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        // But the link name should be an ordinary apostrophe.
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test' string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 12)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 22, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 22)
        XCTAssertEqual(range.length, 19)
    }
    
    func testLinkWithAlternateTextAndSingleQuote() {
        let lines = [ "This is a [test string](test' string) containing a link" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        // Output should be a smart quote.
        XCTAssertEqual(markupParser.text.string, "This is a test’ string containing a link\n")
    }

    // MARK: - Mixed block and inline styles
    
    func testBulletItemWithEmphasis() {
        let lines = [ "• Daddy *and* Chips" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "•\tDaddy and Chips\n")
        
        var range = NSRange()
        var style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
        
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
        
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 8, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 3)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 8, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 3)
        
        
        style = markupParser.text.attribute(NSParagraphStyleAttributeName, atIndex: 11, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, markupParser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, markupParser.paragraphIndent)
        XCTAssertEqual(range.location, 11)
        XCTAssertEqual(range.length, 7)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 11, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 11)
        XCTAssertEqual(range.length, 7)
    }

    // MARK: - Recovery of invalid cases
    
    func testBrokenEmphasisString() {
        let lines = [ "This is *a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is *a test\n")
        
        var range = NSRange()
        let font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
    }

    func testTooLongOperatorStartInEmphasisString() {
        let lines = [ "This is **a* test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is *a test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 9)

        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 9, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 9)
        XCTAssertEqual(range.length, 1)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 6)
    }

    func testTooLongOperatorEndInEmphasisString() {
        let lines = [ "This is *a** test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a* test\n")
        
        var range = NSRange()
        var font = markupParser.text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 8, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 1)
        
        font = markupParser.text.attribute(NSFontAttributeName, atIndex: 9, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 9)
        XCTAssertEqual(range.length, 7)
    }

    func testBrokenQuotedString() {
        let lines = [ "This is \"a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is \"a test\n")
    }

    func testBadlyOverlappedEmphasisAndQuotedString() {
        let lines = [ "This \"is *a\" test*" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This “is *a” test*\n")
    }

    func testBrokenLink() {
        let lines = [ "This is [a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is [a test\n")
    }

    func testBrokenEndLink() {
        let lines = [ "This is ]a test" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is ]a test\n")
    }

    func testBrokenAlternateLink() {
        let lines = [ "This is a [test string](test containing a link" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test string(test containing a link\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 11)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 21, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 24)
    }

    func testBrokenEndAlternateLink() {
        let lines = [ "This is a [test string]test) containing a link" ]
        
        let markupParser = MarkupParser()
        markupParser.parse(lines)
        
        XCTAssertEqual(markupParser.text.string, "This is a test stringtest) containing a link\n")
        
        var range = NSRange()
        var link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 11)
        
        link = markupParser.text.attribute(markupParser.linkAttributeName, atIndex: 21, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 24)
    }

}

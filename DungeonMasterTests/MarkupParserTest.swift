//
//  MarkupParserTest.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/27/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import XCTest
@testable import DungeonMaster

class MarkupTest: XCTestCase {
    
    // MARK: - Blocks
    
    // MARK: Basic paragraphs
    
    func testOneLineString() {
        let lines = [ "This is a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)

        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        let style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
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
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\nand so is this.\n")
        
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)

        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 16)
    }
    
    // MARK: Bulleted lists

    func testBulletItem() {
        let lines = [ "• Daddy" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "•\tDaddy\n")

        var range = NSRange()
        let style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
    }
    
    func testMultipleBulletItems() {
        let lines = [ "• Daddy", "• Chips" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "•\tDaddy\n•\tChips\n")
        
        // The complete bulleted list should end up in a single paragraph block, since there's no change to the attributes.
        var range = NSRange()
        let style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
    }
    
    // MARK: Tables
    
    func testSimpleTable() {
        let lines = [ "State | Capital", "Idaho | Boise", "California | Sacramento" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)

        XCTAssertEqual(text.string, "\tState\tCapital\n\tIdaho\tBoise\n\tCalifornia\tSacramento\n")
        
        // The first line of the table is the heading, and should be covered by a single style with a bold font and tab stops for each column.
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[1].location, parser.tableSpacing * 2)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
        
        let headingTabStops = style!.tabStops
        
        // The next two lines of the table are the body, and should also be covered by a single style and tab stops, but this time with a non-bold font. The tab stops must match the heading ones.
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 15, effectiveRange: &range) as? NSParagraphStyle
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
        XCTAssertEqual(range.length, 36)
        
        font = text.attribute(NSFontAttributeName, atIndex: 15, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 36)
    }
    
    func testNumericTable() {
        let lines = [ "State | Year Joined | Capital", "Idaho | 1890 | Boise", "California | 1850 | Sacramento" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "\tState\tYear Joined\tCapital\n\tIdaho\t1890\tBoise\n\tCalifornia\t1850\tSacramento\n")
        
        // The first line of the table is the heading, and should be covered by a single style with a bold font and tab stops for each column. The middle column should be centered.
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Center)
        XCTAssertGreaterThan(style!.tabStops[1].location, parser.tableSpacing * 2)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[2].location, parser.tableSpacing * 3)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 27)
        
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 27)
        
        let headingTabStops = style!.tabStops
        
        // The next two lines of the table are the body, and should also be covered by a single style and tab stops, but this time with a non-bold font. The tab stops must match the heading ones.
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 27, effectiveRange: &range) as? NSParagraphStyle
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
        XCTAssertEqual(range.length, 46)
        
        font = text.attribute(NSFontAttributeName, atIndex: 27, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 27)
        XCTAssertEqual(range.length, 46)
    }
    
    func testFillTable() {
        let lines = [ "Foo | FooFoo | Foo", "foo | foofoo | foo", "foo | foofoo | foo" ]
        
        let parser = MarkupParser()
        parser.tableWidth = 300.0 + 4 * parser.tableSpacing
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "\tFoo\tFooFoo\tFoo\n\tfoo\tfoofoo\tfoo\n\tfoo\tfoofoo\tfoo\n")
        
        // The left and right colum should be equally sized, and the middle column twice the width.
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 3)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[1].location, parser.tableSpacing * 2 + 75.0)
        XCTAssertEqual(style!.tabStops[2].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[2].location, parser.tableSpacing * 3 + 225.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        let headingTabStops = style!.tabStops
        
        // Body should otherwise match.
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
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
        XCTAssertEqual(range.length, 32)
        
        font = text.attribute(NSFontAttributeName, atIndex: 16, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 32)
    }
    
    // MARK: Mixed blocks
    
    func testBulletAfterText() {
        let lines = [ "Choose between:", "• Daddy", "• Chips" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "Choose between:\n•\tDaddy\n•\tChips\n")
        
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)

        // Bulleted list gets broken in two, because the first item gains paragraph spacing.
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, parser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 8)
        
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 24, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 24)
        XCTAssertEqual(range.length, 8)
    }

    func testBulletBeforeText() {
        let lines = [ "• Daddy", "• Chips", "There are no other alternatives." ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "•\tDaddy\n•\tChips\nThere are no other alternatives.\n")
        
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, parser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 33)
    }

    func testBulletsBetweenText() {
        let lines = [ "Choose between:", "• Daddy", "• Chips", "There are no other alternatives." ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "Choose between:\n•\tDaddy\n•\tChips\nThere are no other alternatives.\n")
        
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
        
        // Bulleted list gets broken in two, because the first item gains paragraph spacing.
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 16, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, parser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 16)
        XCTAssertEqual(range.length, 8)
        
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 24, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 24)
        XCTAssertEqual(range.length, 8)
        
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 32, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, parser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 32)
        XCTAssertEqual(range.length, 33)
    }

    func testTableAfterText() {
        let lines = [ "Some text", "Foo | Bar", "foo | bar" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "Some text\n\tFoo\tBar\n\tfoo\tbar\n")
        
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)

        // Table gets broken in two, first for the heading:
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 10, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, parser.paragraphSpacing)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, 0.0)
        XCTAssertEqual(style!.tabStops.count, 2)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.tableSpacing)
        XCTAssertEqual(style!.tabStops[1].alignment, NSTextAlignment.Left)
        XCTAssertGreaterThan(style!.tabStops[1].location, parser.tableSpacing * 2)
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        font = text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 9)
        
        let headingTabStops = style!.tabStops

        // and then for the body.
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 19, effectiveRange: &range) as? NSParagraphStyle

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
        
        font = text.attribute(NSFontAttributeName, atIndex: 19, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 19)
        XCTAssertEqual(range.length, 9)
    }

    // MARK: - Inline style
    
    // MARK: Emphasis

    func testItalicsAtStart() {
        let lines = [ "*Title,* This is a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "Title, This is a test\n")

        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 6)

        font = text.attribute(NSFontAttributeName, atIndex: 6, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 6)
        XCTAssertEqual(range.length, 16)
    }
    
    func testItalicsInMiddle() {
        let lines = [ "This *is* a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)
        
        font = text.attribute(NSFontAttributeName, atIndex: 5, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 5)
        XCTAssertEqual(range.length, 2)

        font = text.attribute(NSFontAttributeName, atIndex: 7, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }
    
    func testItalicsAtEnd() {
        let lines = [ "This is a *test*" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        font = text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 4)
        
        // Final attribute for the newline.
        font = text.attribute(NSFontAttributeName, atIndex: 14, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testItalicsWholeString() {
        let lines = [ "*This is a test*" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")

        var range = NSRange()
        let font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }

    func testBoldItalicsAtStart() {
        let lines = [ "**Title.** This is a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "Title. This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 6)
        
        font = text.attribute(NSFontAttributeName, atIndex: 6, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 6)
        XCTAssertEqual(range.length, 16)
    }
    
    func testBoldItalicsInMiddle() {
        let lines = [ "This **is** a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)
        
        font = text.attribute(NSFontAttributeName, atIndex: 5, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 5)
        XCTAssertEqual(range.length, 2)
        
        font = text.attribute(NSFontAttributeName, atIndex: 7, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }
    
    func testBoldItalicsAtEnd() {
        let lines = [ "This is a **test**" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        font = text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 4)
        
        // Final attribute for the newline.
        font = text.attribute(NSFontAttributeName, atIndex: 14, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testBoldItalicsWholeString() {
        let lines = [ "**This is a test**" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        let font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }

    func testHeadlineAtStart() {
        let lines = [ "***Title.*** This is a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "Title. This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 6)
        
        font = text.attribute(NSFontAttributeName, atIndex: 6, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 6)
        XCTAssertEqual(range.length, 16)
    }
    
    func testHeadlineInMiddle() {
        let lines = [ "This ***is*** a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)
        
        font = text.attribute(NSFontAttributeName, atIndex: 5, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 5)
        XCTAssertEqual(range.length, 2)
        
        font = text.attribute(NSFontAttributeName, atIndex: 7, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }
    
    func testHeadlineAtEnd() {
        let lines = [ "This is a ***test***" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        font = text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 4)
        
        // Final attribute for the newline.
        font = text.attribute(NSFontAttributeName, atIndex: 14, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testHeadlineWholeString() {
        let lines = [ "***This is a test***" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        let font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 15)
    }
    
    // MARK: Quoted stings
    
    func testQuotedStringAtStart() {
        let lines = [ "\"This is\" a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "“This is” a test\n")
    }

    func testQuotedStringInMiddle() {
        let lines = [ "This is a \"test string\" containing a quote" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a “test string” containing a quote\n")
    }
    
    func testQuotedStringAtEnd() {
        let lines = [ "This is \"a test\"" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is “a test”\n")
    }

    func testQuotedWholeString() {
        let lines = [ "\"This is a test\"" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        // In contrast to emphasis, the newline should be still outside the quote.
        XCTAssertEqual(text.string, "“This is a test”\n")
    }

    // MARK: Links

    func testLinkAtStart() {
        let lines = [ "[This is] a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var link = text.attribute(parser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertEqual(link, "This is")
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 7)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 7, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 7)
        XCTAssertEqual(range.length, 8)
    }

    func testLinkInMiddle() {
        let lines = [ "This is a [test string] containing a link" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test string containing a link\n")
        
        var range = NSRange()
        var link = text.attribute(parser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 11)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 21, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 19)
    }

    func testLinkAtEnd() {
        let lines = [ "This is [a test]" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var link = text.attribute(parser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)

        link = text.attribute(parser.linkAttributeName, atIndex: 8, effectiveRange: &range) as? String
        XCTAssertEqual(link, "a test")
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 6)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 14, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testLinkWholeString() {
        let lines = [ "[This is a test]" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test\n")
        
        var range = NSRange()
        var link = text.attribute(parser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        link = text.attribute(parser.linkAttributeName, atIndex: 8, effectiveRange: &range) as? String
        XCTAssertEqual(link, "This is a test")
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 14)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 14, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 14)
        XCTAssertEqual(range.length, 1)
    }

    func testLinkAlternateText() {
        let lines = [ "This is a [test string](thing) containing a link" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a thing containing a link\n")
        
        var range = NSRange()
        var link = text.attribute(parser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 5)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 15, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 15)
        XCTAssertEqual(range.length, 19)
    }

    // MARK: Mixed inline styles
    
    func testEmphasisInQuotedString() {
        let lines = [ "This is a \"test with *emphasis* in the quoted\" string" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a “test with emphasis in the quoted” string\n")

        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 21)

        font = text.attribute(NSFontAttributeName, atIndex: 21, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 8)

        font = text.attribute(NSFontAttributeName, atIndex: 29, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 29)
        XCTAssertEqual(range.length, 23)
    }
    
    // MARK: - Mixed block and inline styles
    
    func testBulletItemWithEmphasis() {
        let lines = [ "• Daddy *and* Chips" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "•\tDaddy and Chips\n")
        
        var range = NSRange()
        var style = text.attribute(NSParagraphStyleAttributeName, atIndex: 0, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
        
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
        
        
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 8, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 3)
        
        font = text.attribute(NSFontAttributeName, atIndex: 8, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 3)
        
        
        style = text.attribute(NSParagraphStyleAttributeName, atIndex: 11, effectiveRange: &range) as? NSParagraphStyle
        XCTAssertNotNil(style)
        XCTAssertEqual(style!.paragraphSpacingBefore, 0.0)
        XCTAssertEqual(style!.paragraphSpacing, 0.0)
        XCTAssertEqual(style!.firstLineHeadIndent, 0.0)
        XCTAssertEqual(style!.headIndent, parser.paragraphIndent)
        XCTAssertEqual(style!.tabStops.count, 1)
        XCTAssertEqual(style!.tabStops[0].alignment, NSTextAlignment.Left)
        XCTAssertEqual(style!.tabStops[0].location, parser.paragraphIndent)
        XCTAssertEqual(range.location, 11)
        XCTAssertEqual(range.length, 7)
        
        font = text.attribute(NSFontAttributeName, atIndex: 11, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 11)
        XCTAssertEqual(range.length, 7)
    }

    // MARK: - Recovery of invalid cases
    
    func testBrokenEmphasisString() {
        let lines = [ "This is *a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is *a test\n")
        
        var range = NSRange()
        let font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 16)
    }

    func testTooLongOperatorStartInEmphasisString() {
        let lines = [ "This is **a* test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is *a test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 9)

        font = text.attribute(NSFontAttributeName, atIndex: 9, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 9)
        XCTAssertEqual(range.length, 1)
        
        font = text.attribute(NSFontAttributeName, atIndex: 10, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 6)
    }

    func testTooLongOperatorEndInEmphasisString() {
        let lines = [ "This is *a** test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a* test\n")
        
        var range = NSRange()
        var font = text.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 8)
        
        font = text.attribute(NSFontAttributeName, atIndex: 8, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertTrue(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 8)
        XCTAssertEqual(range.length, 1)
        
        font = text.attribute(NSFontAttributeName, atIndex: 9, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitBold))
        XCTAssertFalse(font!.fontDescriptor().symbolicTraits.contains(.TraitItalic))
        XCTAssertEqual(range.location, 9)
        XCTAssertEqual(range.length, 7)
    }

    func testBrokenQuotedString() {
        let lines = [ "This is \"a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is \"a test\n")
    }

    func testBadlyOverlappedEmphasisAndQuotedString() {
        let lines = [ "This \"is *a\" test*" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This “is *a” test*\n")
    }

    func testBrokenLink() {
        let lines = [ "This is [a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is [a test\n")
    }

    func testBrokenEndLink() {
        let lines = [ "This is ]a test" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is ]a test\n")
    }

    func testBrokenAlternateLink() {
        let lines = [ "This is a [test string](test containing a link" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test string(test containing a link\n")
        
        var range = NSRange()
        var link = text.attribute(parser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 11)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 21, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 24)
    }

    func testBrokenEndAlternateLink() {
        let lines = [ "This is a [test string]test) containing a link" ]
        
        let parser = MarkupParser()
        let text = parser.parse(lines)
        
        XCTAssertEqual(text.string, "This is a test stringtest) containing a link\n")
        
        var range = NSRange()
        var link = text.attribute(parser.linkAttributeName, atIndex: 0, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 10, effectiveRange: &range) as? String
        XCTAssertEqual(link, "test string")
        XCTAssertEqual(range.location, 10)
        XCTAssertEqual(range.length, 11)
        
        link = text.attribute(parser.linkAttributeName, atIndex: 21, effectiveRange: &range) as? String
        XCTAssertNil(link)
        XCTAssertEqual(range.location, 21)
        XCTAssertEqual(range.length, 24)
    }

}

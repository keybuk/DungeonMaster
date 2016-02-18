//
//  PixelLineView.swift
//  DungeonKit
//
//  Created by Scott James Remnant on 2/16/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

/// VerticalPixelLineView is a simple UIView that draws a pixel-width line along its left-most edge.
@IBDesignable public class VerticalPixelLineView: UIView {
    
    /// Width of the line in pixels, not points.
    ///
    /// The current content scale factor is taken into account, along with the relative offsets of pixel boundaries, to accurately draw a true pixel-width line.
    @IBInspectable public var widthInPixels: CGFloat = 1.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Color of the line.
    @IBInspectable public var color: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureDefaults()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureDefaults()
    }
    
    func configureDefaults() {
        // Generally the view is going to be transparent, that means we have to take care of the background ourselves.
        opaque = false
        clearsContextBeforeDrawing = false
        
        contentMode = .ScaleToFill
        autoresizingMask = .FlexibleHeight
    }

    public override func intrinsicContentSize() -> CGSize {
        // The view always has an intrinsic width, based on the line itself, return that so we don't need a constraint for it.
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: lineWidth, height: UIViewNoIntrinsicMetric)
    }
    
    override public func sizeThatFits(size: CGSize) -> CGSize {
        let sizeThatFits = super.sizeThatFits(size)
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: lineWidth, height: sizeThatFits.height)
    }
    
    override public func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        // Clear the rectangle to be drawn.
        CGContextSetFillColorWithColor(context, (backgroundColor ?? UIColor.clearColor()).CGColor)
        CGContextFillRect(context, rect)
        
        // Since we only draw a single line, it's almost certainly cheaper to just use the default clip than worry about it ourselves.
        let width = widthInPixels / contentScaleFactor
        let offset = width / 2.0
        
        CGContextSetStrokeColorWithColor(context, color.CGColor)
        CGContextSetLineWidth(context, width)
        
        CGContextMoveToPoint(context, offset, 0.0)
        CGContextAddLineToPoint(context, offset, bounds.size.height)
        
        CGContextDrawPath(context, .Stroke)
    }
    
}

/// HorizontalPixelLineView is a simple UIView that draws a pixel-width line along its top-most edge.
@IBDesignable public class HorizontalPixelLineView: UIView {
    
    /// Width of the line in pixels, not points.
    ///
    /// The current content scale factor is taken into account, along with the relative offsets of pixel boundaries, to accurately draw a true pixel-width line.
    @IBInspectable public var widthInPixels: CGFloat = 1.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Color of the line.
    @IBInspectable public var color: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureDefaults()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureDefaults()
    }
    
    func configureDefaults() {
        // Generally the view is going to be transparent, that means we have to take care of the background ourselves.
        opaque = false
        clearsContextBeforeDrawing = false
        
        contentMode = .ScaleToFill
        autoresizingMask = .FlexibleWidth
    }
    
    public override func intrinsicContentSize() -> CGSize {
        // The view always has an intrinsic width, based on the line itself, return that so we don't need a constraint for it.
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: UIViewNoIntrinsicMetric, height: lineWidth)
    }
    
    override public func sizeThatFits(size: CGSize) -> CGSize {
        let sizeThatFits = super.sizeThatFits(size)
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: sizeThatFits.width, height: lineWidth)
    }
    
    override public func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        // Clear the rectangle to be drawn.
        CGContextSetFillColorWithColor(context, (backgroundColor ?? UIColor.clearColor()).CGColor)
        CGContextFillRect(context, rect)
        
        // Since we only draw a single line, it's almost certainly cheaper to just use the default clip than worry about it ourselves.
        let width = widthInPixels / contentScaleFactor
        let offset = width / 2.0
        
        CGContextSetStrokeColorWithColor(context, color.CGColor)
        CGContextSetLineWidth(context, width)
        
        CGContextMoveToPoint(context, 0.0, offset)
        CGContextAddLineToPoint(context, bounds.size.width, offset)
        
        CGContextDrawPath(context, .Stroke)
    }
    
}

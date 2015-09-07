//
//  Utils.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 23/2/15.

//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import UIKit
import Darwin

internal class ChartUtils
{
    internal struct Math
    {
        internal static let FDEG2RAD = CGFloat(M_PI / 180.0)
        internal static let FRAD2DEG = CGFloat(180.0 / M_PI)
        internal static let DEG2RAD = M_PI / 180.0
        internal static let RAD2DEG = 180.0 / M_PI
    }
    
    internal class func roundToNextSignificant(number number: Double) -> Double
    {
        if (isinf(number) || isnan(number) || number == 0)
        {
            return number
        }
        
        let d = ceil(log10(number < 0.0 ? -number : number))
        let pw = 1 - Int(d)
        let magnitude = pow(Double(10.0), Double(pw))
        let shifted = round(number * magnitude)
        return shifted / magnitude
    }
    
    internal class func decimals(number: Double) -> Int
    {
        if (number == 0.0)
        {
            return 0
        }
        
        let i = roundToNextSignificant(number: Double(number))
        return Int(ceil(-log10(i))) + 2
    }
    
    internal class func nextUp(number: Double) -> Double
    {
        if (isinf(number) || isnan(number))
        {
            return number
        }
        else
        {
            return number + DBL_EPSILON
        }
    }

    /// - returns: the index of the DataSet that contains the closest value on the y-axis. This will return -Integer.MAX_VALUE if failure.
    internal class func closestDataSetIndex(valsAtIndex: [ChartSelectionDetail], value: Double, axis: ChartYAxis.AxisDependency?) -> Int
    {
        var index = -Int.max
        var distance = DBL_MAX
        
        for (var i = 0; i < valsAtIndex.count; i++)
        {
            let sel = valsAtIndex[i]
            
            if (axis == nil || sel.dataSet?.axisDependency == axis)
            {
                let cdistance = abs(sel.value - value)
                if (cdistance < distance)
                {
                    index = valsAtIndex[i].dataSetIndex
                    distance = cdistance
                }
            }
        }
        
        return index
    }
    
    /// - returns: the minimum distance from a touch-y-value (in pixels) to the closest y-value (in pixels) that is displayed in the chart.
    internal class func getMinimumDistance(valsAtIndex: [ChartSelectionDetail], val: Double, axis: ChartYAxis.AxisDependency) -> Double
    {
        var distance = DBL_MAX
        
        for (var i = 0, count = valsAtIndex.count; i < count; i++)
        {
            let sel = valsAtIndex[i]
            
            if (sel.dataSet!.axisDependency == axis)
            {
                let cdistance = abs(sel.value - val)
                if (cdistance < distance)
                {
                    distance = cdistance
                }
            }
        }
        
        return distance
    }
    
    /// Calculates the position around a center point, depending on the distance from the center, and the angle of the position around the center.
    internal class func getPosition(center center: CGPoint, dist: CGFloat, angle: CGFloat) -> CGPoint
    {
        return CGPoint(
            x: center.x + dist * cos(angle * Math.FDEG2RAD),
            y: center.y + dist * sin(angle * Math.FDEG2RAD)
        )
    }
    
    internal class func drawText(context context: CGContext?, text: String, var point: CGPoint, align: NSTextAlignment, attributes: [String : AnyObject]?)
    {
        if (align == .Center)
        {
            point.x -= text.sizeWithAttributes(attributes).width / 2.0
        }
        else if (align == .Right)
        {
            point.x -= text.sizeWithAttributes(attributes).width
        }
    
        UIGraphicsPushContext(context)
        (text as NSString).drawAtPoint(point, withAttributes: attributes)
        UIGraphicsPopContext()
    }

    /// Talentoday added. Draw text based on chart size.
    internal class func drawText(context context: CGContext?, var text: String, var point: CGPoint, align: NSTextAlignment, attributes: [NSObject : AnyObject]?, chartSize:CGSize = CGSizeZero)
    {
        let width = text.sizeWithAttributes(attributes as? [String: AnyObject]).width
        let offsetX = Int(fabs(point.x - chartSize.width/2))
        var percentOffset = CGFloat(offsetX) / 40

        if percentOffset > 1 {
            percentOffset = 1
        }
        if percentOffset < 0 {
            percentOffset = 0
        }

        if point.x < chartSize.width / 2 {
            if width + 5 > point.x {
                text = breakText(text)
            }
            point.x -= width/2
            point.x -= width/2 * percentOffset
        } else {
            if width + 5 + point.x > chartSize.width {
                text = breakText(text)
            }
            point.x -= width/2 * (1 - percentOffset)
        }

        if point.y > chartSize.height / 2 {
            point.y += 10 * (1 - percentOffset)
        } else {
            point.y -= 10 * (1 - percentOffset)
        }

        let drawRect = CGRectMake(point.x, point.y, width, 30)

        UIGraphicsPushContext(context);
        (text as NSString).drawInRect(drawRect, withAttributes: (attributes as! [String: AnyObject]))
        UIGraphicsPopContext();
    }

    /// Talentoday added. Break text on multiple lines
    internal class func breakText(text:String) -> String {
        let parts = text.characters.split { $0 == " " }.map(String.init)
        var newText = parts[0]
        if parts.count > 1 {
            let lastWord = parts[parts.count - 1]
            if parts.count > 2 {
                for index in 1...parts.count - 2 {
                    if newText.characters.count < lastWord.characters.count {
                        newText = newText + " \(parts[index])"
                    } else {
                        newText = newText + "\n\(parts[index])"
                        for j in index + 1...parts.count - 1 {
                            newText = newText  + " \(parts[j])"
                        }
                        continue
                    }
                }
            } else {
                newText = newText + "\n\(lastWord)"
            }
            if newText.rangeOfString(lastWord,
                options: []) == nil {
                    newText = newText + "\n\(lastWord)"
            }
        }
        return newText
    }

    internal class func drawMultilineText(context context: CGContext?, text: String, knownTextSize: CGSize, point: CGPoint, align: NSTextAlignment, attributes: [String : AnyObject]?, constrainedToSize: CGSize)
    {
        var rect = CGRect(origin: CGPoint(), size: knownTextSize)
        rect.origin.x += point.x
        rect.origin.y += point.y
        
        if (align == .Center)
        {
            rect.origin.x -= rect.size.width / 2.0
        }
        else if (align == .Right)
        {
            rect.origin.x -= rect.size.width
        }
        
        UIGraphicsPushContext(context)
        (text as NSString).drawWithRect(rect, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
        UIGraphicsPopContext()
    }
    
    internal class func drawMultilineText(context context: CGContext?, text: String, point: CGPoint, align: NSTextAlignment, attributes: [String : AnyObject]?, constrainedToSize: CGSize)
    {
        let rect = text.boundingRectWithSize(constrainedToSize, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
        drawMultilineText(context: context, text: text, knownTextSize: rect.size, point: point, align: align, attributes: attributes, constrainedToSize: constrainedToSize)
    }
    
    /// - returns: an angle between 0.0 < 360.0 (not less than zero, less than 360)
    internal class func normalizedAngleFromAngle(var angle: CGFloat) -> CGFloat
    {
        while (angle < 0.0)
        {
            angle += 360.0
        }
        
        return angle % 360.0
    }
    
    
    /// MARK: - Bridging functions
    
    internal class func bridgedObjCGetUIColorArray (swift array: [UIColor?]) -> [NSObject]
    {
        var newArray = [NSObject]()
        for val in array
        {
            if (val == nil)
            {
                newArray.append(NSNull())
            }
            else
            {
                newArray.append(val!)
            }
        }
        return newArray
    }
    
    internal class func bridgedObjCGetUIColorArray (objc array: [NSObject]) -> [UIColor?]
    {
        var newArray = [UIColor?]()
        for object in array
        {
            newArray.append(object as? UIColor)
        }
        return newArray
    }
    
    internal class func bridgedObjCGetStringArray (swift array: [String?]) -> [NSObject]
    {
        var newArray = [NSObject]()
        for val in array
        {
            if (val == nil)
            {
                newArray.append(NSNull())
            }
            else
            {
                newArray.append(val!)
            }
        }
        return newArray
    }
    
    internal class func bridgedObjCGetStringArray (objc array: [NSObject]) -> [String?]
    {
        var newArray = [String?]()
        for object in array
        {
            newArray.append(object as? String)
        }
        return newArray
    }
}
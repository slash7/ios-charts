//
//  ChartXAxisRendererRadarChart.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 3/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics
import UIKit

public class ChartXAxisRendererRadarChart: ChartXAxisRenderer
{
    private weak var _chart: RadarChartView!
    
    public init(viewPortHandler: ChartViewPortHandler, xAxis: ChartXAxis, chart: RadarChartView)
    {
        super.init(viewPortHandler: viewPortHandler, xAxis: xAxis, transformer: nil)
        
        _chart = chart
    }
    
    public override func renderAxisLabels(context context: CGContext?)
    {
        if (!_xAxis.isEnabled || !_xAxis.isDrawLabelsEnabled)
        {
            return
        }
        
        let labelFont = _xAxis.labelFont
        let labelTextColor = _xAxis.labelTextColor
        let labelTextColors = _xAxis.labelTextColors
        let labelTextColorsCount  = labelTextColors.count

        let sliceangle = _chart.sliceAngle
        
        // calculate the factor that is needed for transforming the value to pixels
        let factor = _chart.factor
        
        let center = _chart.centerOffsets
        
        for (var i = 0, count = _xAxis.values.count; i < count; i++)
        {
            let text = _xAxis.values[i]
            
            if (text == nil)
            {
                continue
            }
            
            let angle = (sliceangle * CGFloat(i) + _chart.rotationAngle) % 360.0

            // Talentoday added
            // Calculate margin between label and web
            var margin = _xAxis.labelWidth / 2.0 // default margin from ios-charts

            // Design is done on iPhone 6 Plus, calculate scale for other devices
            let scale = UIScreen.mainScreen().bounds.size.width/414

            // Reduce default margin by 4
            margin = margin / 4.0 * scale

            let p = ChartUtils.getPosition(center: center, dist: CGFloat(_chart.yRange) * factor + margin, angle: angle)

            let textColor = (labelTextColorsCount == count) ? labelTextColors[i] : labelTextColor
            let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle

            if p.x < _chart.bounds.width / 2 {
                paragraphStyle.alignment = NSTextAlignment.Right
            } else if p.x > _chart.bounds.width / 2 {
                paragraphStyle.alignment = NSTextAlignment.Left
            }

            let attributes = [NSFontAttributeName: labelFont, NSForegroundColorAttributeName: textColor!, NSParagraphStyleAttributeName: paragraphStyle]

            /// Call Talentoday added method that supplies `chart` as parameter.
            ChartUtils.drawText(context: context, text: text!, point: CGPoint(x: p.x, y: p.y - _xAxis.labelHeight / 2.0), align: .Center, attributes: attributes, chartSize: _chart.bounds.size)
        }
    }
    
    public override func renderLimitLines(context context: CGContext?)
    {
        /// XAxis LimitLines on RadarChart not yet supported.
    }
}
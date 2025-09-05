//
//  GradientLabel.swift
//  coursiva
//
//  Created by Z1 on 14.07.2025.
//


import SwiftUI

class GradientLabel: UILabel {
    var gradientColors: [UIColor] = [.systemBlue, .systemPurple]

    override func drawText(in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), let text = self.text else {
            super.drawText(in: rect)
            return
        }
        
        // Use extra bold font (black weight), now smaller (17pt)
        let font = self.font ?? UIFont.systemFont(ofSize: 17, weight: .black)
        
        // Create attributed string with extra bold font
        let attributedString = NSAttributedString(string: text, attributes: [.font: font])
        
        // Create image context for mask (flipped to match Core Graphics)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        guard let maskCtx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            super.drawText(in: rect)
            return
        }
        maskCtx.translateBy(x: 0, y: rect.size.height)
        maskCtx.scaleBy(x: 1.0, y: -1.0)
        attributedString.draw(in: rect)
        guard let mask = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            super.drawText(in: rect)
            return
        }
        UIGraphicsEndImageContext()
        
        // Draw gradient clipped to mask
        ctx.saveGState()
        ctx.clip(to: rect, mask: mask)
        let colors = gradientColors.map { $0.cgColor } as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
        
        // 135deg gradient: start from top-left, end at bottom-right
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: rect.width, y: rect.height)
        
        ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        ctx.restoreGState()
    }
}

struct GradientTitle: UIViewRepresentable {
    var text: String
    var font: UIFont = UIFont(name: "Futura-Bold", size: 34)!
    var colors: [UIColor] = [
        UIColor(red: 0x7b/255.0, green: 0x3d/255.0, blue: 0xd8/255.0, alpha: 1.0), // #7b3dd8
        UIColor(red: 0x57/255.0, green: 0x07/255.0, blue: 0xab/255.0, alpha: 1.0)  // #5707ab
    ]

    func makeUIView(context: Context) -> GradientLabel {
        let label = GradientLabel()
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.font = font
        label.gradientColors = colors
        label.adjustsFontSizeToFitWidth = true
        return label
    }

    func updateUIView(_ uiView: GradientLabel, context: Context) {
        uiView.text = NSLocalizedString(text, comment: "")
        uiView.font = font
        uiView.gradientColors = colors
        uiView.setNeedsDisplay()
    }
}

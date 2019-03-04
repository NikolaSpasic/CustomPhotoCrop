//
//  Extensions.swift
//  PhotoCrop
//
//  Created by VTS AppsTeam on 2/19/19.
//  Copyright © 2019 VTS AppsTeam. All rights reserved.
//

import UIKit

extension UIView {
    func snapshot(afterScreenUpdates: Bool = false) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
extension UIImage {
    func imageByAddingBorder(borderWidth width: CGFloat, borderColor color: UIColor) -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        let imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.draw(in: imageRect)
        
        let ctx = UIGraphicsGetCurrentContext()
        let borderRect = imageRect.insetBy(dx: 0.0, dy: width / 2)
        
        ctx!.setStrokeColor(color.cgColor)
        ctx!.setLineWidth(width)
        ctx!.stroke(borderRect)
        
        let borderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return borderedImage!
    }
}

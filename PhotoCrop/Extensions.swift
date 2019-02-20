//
//  Extensions.swift
//  PhotoCrop
//
//  Created by VTS AppsTeam on 2/19/19.
//  Copyright © 2019 VTS AppsTeam. All rights reserved.
//

import UIKit


public extension UIImage {
    func scaleImageToSize(newSize: CGSize, offset: CGFloat) -> UIImage {
        var scaledImageRect = CGRect.zero
        let aspectWidth = newSize.width/size.width
        let aspectheight = newSize.height/size.height
        
        let aspectRatio = max(aspectWidth, aspectheight)
        
        scaledImageRect.size.width = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0
        
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
}

extension UIView {
    func snapshot(afterScreenUpdates: Bool = false) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

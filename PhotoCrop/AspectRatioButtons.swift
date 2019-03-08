//
//  AspectRatioButtons.swift
//  PhotoCrop
//
//  Created by VTS AppsTeam on 3/8/19.
//  Copyright © 2019 VTS AppsTeam. All rights reserved.
//

import Foundation
import UIKit

class AspectRatioBttn {
    var name: String = ""
    var image: UIImage?
    var width: CGFloat
    var height: CGFloat
    
    init(names: String, widths: CGFloat, heights: CGFloat) {
        name = names
        if names.hasPrefix("Facebook") {
            image = UIImage(named: "Facebook")
        } else {
            image = UIImage(named: names)
        }
        width = widths
        height = heights
    }
}

class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}

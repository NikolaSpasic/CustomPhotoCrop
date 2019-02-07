//
//  ViewController.swift
//  PhotoCrop
//
//  Created by VTS AppsTeam on 2/1/19.
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

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageHolder: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 10.0
        }
    }
    @IBOutlet var aspectRatioBttns: [UIButton]?
    
    var originalImg: UIImage?
    var croppedImage: UIImage?
    var rec: CGRect!

    private let shapeLayer: CAShapeLayer = {
        let _shapeLayer = CAShapeLayer()
        _shapeLayer.fillColor = UIColor.clear.cgColor
        _shapeLayer.strokeColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor
        _shapeLayer.lineWidth = 2
        return _shapeLayer
    }()
    private var startPoint: CGPoint!
    
    var overlay: UIView?
    var maskLayer: CAShapeLayer?
    var rect: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for button in aspectRatioBttns! {
            button.layer.cornerRadius = 15
        }
        originalImg = UIImage(named: "Slika")
        imageHolder.image = originalImg
        imageHolder.layer.borderWidth = 1
        imageHolder.layer.borderColor = UIColor.darkGray.cgColor
        imageHolder.layer.addSublayer(shapeLayer)
        
        // Create a view filling the imageView.
        overlay = UIView(frame: scrollView.frame)
        
        // Set a semi-transparent, black background.
        overlay!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        // Create the initial layer from the view bounds.
        maskLayer = CAShapeLayer()
        maskLayer!.frame = overlay!.bounds
        maskLayer!.fillColor = UIColor.black.cgColor
        
        // Set the mask of the view.
        overlay!.layer.mask = maskLayer
        
        // Add the view so it is visible.
        self.view.addSubview(overlay!)

    }

    @IBAction func doneBttnPressed(_ sender: Any) {
        if let imgDidCrop = croppedImage {
            UIImageWriteToSavedPhotosAlbum(imgDidCrop, nil, nil, nil)
        }
    }
    
    @IBAction func cancelBttnPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.33, delay: 0.0, options: [], animations: {
            self.imageHolder.alpha = 0
            self.overlay!.alpha = 0
        }, completion: { (finished: Bool) in
            self.imageHolder.image = self.originalImg
            self.overlay!.removeFromSuperview()
        })
        UIView.animate(withDuration: 0.33, delay: 0.0, options: [], animations: {
            self.imageHolder.alpha = 1
        })
    }
    
    @IBAction func cropBttnPressed(_ sender: Any) {
        
        croppedImage = cropImage(image: originalImg!, toRect: rec)
        UIView.animate(withDuration: 0.33, delay: 0.0, options: [], animations: {
            self.imageHolder.alpha = 0
        }, completion: { (finished: Bool) in
            self.imageHolder.image = self.croppedImage
        })
        UIView.animate(withDuration: 0.33, delay: 0.0, options: [], animations: {
            self.imageHolder.alpha = 1
        })
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageHolder
    }
    
    @IBAction func aspectRatioBttnsPressed(_ sender: Any) {
        clear()
        guard let button = sender as? UIButton else {
            return
        }
        let imgSize = frame(for: originalImg!, inImageViewAspectFit: scrollView)
        var toRect: CGRect?
        switch button.tag {
        case 0:
            if imgSize.height > imgSize.width {
                let cropSize = calculateAspectRatio(width: 1, height: 1, biggerSide: imgSize.height, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: imgSize.width, height: cropSize)
            } else {
                let cropSize = calculateAspectRatio(width: 1, height: 1, biggerSide: imgSize.width, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: cropSize, height: imgSize.height)
            }
//            croppedImage = cropImage(image: originalImg!, toRect: <#T##CGRect#>)
        case 1:
            if imgSize.height > imgSize.width {
                let cropSize = calculateAspectRatio(width: 16, height: 9, biggerSide: imgSize.height, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: imgSize.width, height: cropSize)
            } else {
                let cropSize = calculateAspectRatio(width: 16, height: 9, biggerSide: imgSize.width, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: cropSize, height: imgSize.height)
            }
        case 2:
            if imgSize.height > imgSize.width {
                let cropSize = calculateAspectRatio(width: 4, height: 3, biggerSide: imgSize.height, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: imgSize.width, height: cropSize)
            } else {
                let cropSize = calculateAspectRatio(width: 4, height: 3, biggerSide: imgSize.width, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: cropSize, height: imgSize.height)
            }
        case 3:
            if imgSize.height > imgSize.width {
                let cropSize = calculateAspectRatio(width: 2, height: 3, biggerSide: imgSize.height, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: imgSize.width, height: cropSize)
            } else {
                let cropSize = calculateAspectRatio(width: 2, height: 3, biggerSide: imgSize.width, originalImgFrame: imgSize)
                toRect = CGRect(x: 0, y: 0, width: cropSize, height: imgSize.height)
                
            }
        default:
            print("try again")
            return
        }
        croppedImage = cropImage(image: originalImg!, toRect: toRect!)
        UIView.animate(withDuration: 0.33, delay: 0.0, options: [], animations: {
            self.imageHolder.alpha = 0
        }, completion: { (finished: Bool) in
            self.imageHolder.image = self.croppedImage
        })
        UIView.animate(withDuration: 0.33, delay: 0.0, options: [], animations: {
            self.imageHolder.alpha = 1
        })
        let croppedImgFrame = frame(for: croppedImage!, inImageViewAspectFit: scrollView)
        let lastPoint = CGPoint(x: croppedImgFrame.maxX, y: croppedImgFrame.maxY)
        updatePath(from: croppedImgFrame.origin, to: lastPoint)
        
    }
    
    func calculateAspectRatio(width: Int, height: Int, biggerSide: CGFloat, originalImgFrame: CGRect) -> CGFloat {
        if width > height {
            let croppedSize = originalImgFrame.height * CGFloat(width) / CGFloat(height)
            return croppedSize
        } else if height > width {
            let croppedSize = originalImgFrame.height * CGFloat(height) / CGFloat(width)
            return croppedSize
        } else {
            if originalImgFrame.height < originalImgFrame.width {
                let croppedSize = originalImgFrame.height
                return croppedSize
            } else {
                let croppedSize = originalImgFrame.width
                return croppedSize
            }
        }
    }
    
    func cropImage(image: UIImage, toRect: CGRect) -> UIImage? {
        // Cropping is available trhough CGGraphics
        print("rect \(toRect)")
        let cgImage :CGImage! = image.cgImage
        let croppedCGImage: CGImage! = cgImage.cropping(to: toRect)
        
        return UIImage(cgImage: croppedCGImage)
    }
    
    func clear() {
        imageHolder.layer.sublayers = nil
        imageHolder.image = UIImage(named: "Slika")
        imageHolder.layer.addSublayer(shapeLayer)
        overlay!.alpha = 1
        self.view.addSubview(overlay!)
    }
    
    private func updatePath(from startPoint: CGPoint, to point: CGPoint) {
        let size = CGSize(width: point.x - startPoint.x, height: point.y - startPoint.y)
        rec = CGRect(origin: startPoint, size: size)
        shapeLayer.path = UIBezierPath(rect: rec).cgPath
        // Create the frame for the clear part
        let path = UIBezierPath(rect: overlay!.bounds)
        // Create the path.
        path.append(UIBezierPath(rect: rec))
        maskLayer!.path = path.cgPath
        maskLayer!.fillRule = CAShapeLayerFillRule.evenOdd
        self.view.addSubview(overlay!)
    }
    
    func frame(for image: UIImage, inImageViewAspectFit imageView: UIScrollView) -> CGRect {
        let imageRatio = (image.size.width / image.size.height)
        let viewRatio = imageView.frame.size.width / imageView.frame.size.height
        if imageRatio < viewRatio {
            let scale = imageView.frame.size.height / image.size.height
            let width = scale * image.size.width
            let topLeftX = (imageView.frame.size.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageView.frame.size.height)
        } else {
            let scale = imageView.frame.size.width / image.size.width
            let height = scale * image.size.height
            let topLeftY = (imageView.frame.size.height - height) * 0.5
            return CGRect(x: 0.0, y: topLeftY, width: imageView.frame.size.width, height: height)
        }
    }
}


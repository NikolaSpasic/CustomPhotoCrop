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

//extension UIImageView {
//    func imageFrame()->CGRect{
//        let imageViewSize = self.frame.size
//        guard let imageSize = self.image?.size else{return CGRect.zero}
//        let imageRatio = imageSize.width / imageSize.height
//        let imageViewRatio = imageViewSize.width / imageViewSize.height
//        if imageRatio < imageViewRatio {
//            let scaleFactor = imageViewSize.height / imageSize.height
//            let width = imageSize.width * scaleFactor
//            let topLeftX = (imageViewSize.width - width) * 0.5
//            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
//        }else{
//            let scalFactor = imageViewSize.width / imageSize.width
//            let height = imageSize.height * scalFactor
//            let topLeftY = (imageViewSize.height - height) * 0.5
//            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
//        }
//    }
//}

class ViewController: UIViewController {

    @IBOutlet weak var imageHolder: UIImageView!
    @IBOutlet weak var doneBttn: UIButton!
    @IBOutlet weak var cancelBttn: UIButton!
    @IBOutlet weak var cropBttn: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!// {
//        didSet{
//            scrollView.delegate = self
//            scrollView.minimumZoomScale = 1.0
//            scrollView.maximumZoomScale = 10.0
//        }
//    }
    
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
        let buttons = [doneBttn, cancelBttn, cropBttn]
        for button in buttons {
            button?.layer.cornerRadius = 15
        }
        originalImg = UIImage(named: "Slika")
        imageHolder.image = originalImg
        imageHolder.layer.borderWidth = 1
        imageHolder.layer.borderColor = UIColor.darkGray.cgColor
        imageHolder.layer.addSublayer(shapeLayer)
        
        // Create a view filling the imageView.
        overlay = UIView(frame: imageHolder.frame)
        
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
        
//        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: rec.size)
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
    
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return imageHolder
//    }
    
    func cropImage(image: UIImage, toRect: CGRect) -> UIImage? {
        // Cropping is available trhough CGGraphics
        print("rect \(toRect)")
        let cgImage :CGImage! = image.cgImage
        let croppedCGImage: CGImage! = cgImage.cropping(to: toRect)
        
        return UIImage(cgImage: croppedCGImage)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        clear()
        startPoint = touches.first?.location(in: imageHolder)
    }
    
    func clear() {
        imageHolder.layer.sublayers = nil
        imageHolder.image = UIImage(named: "Slika")
        imageHolder.layer.addSublayer(shapeLayer)
        overlay!.alpha = 1
        self.view.addSubview(overlay!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let startPoint = startPoint, let touch = touches.first else { return }
        let point: CGPoint

        if let predictedTouch = event?.predictedTouches(for: touch)?.last {
            point = predictedTouch.location(in: imageHolder)
        } else {
            point = touch.location(in: imageHolder)
        }
        updatePath(from: startPoint, to: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let startPoint = startPoint, let touch = touches.first else { return }
        let point = touch.location(in: imageHolder)
        updatePath(from: startPoint, to: point)
        imageHolder.image = imageHolder.snapshot(afterScreenUpdates: true)
        shapeLayer.path = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        shapeLayer.path = nil
        overlay!.removeFromSuperview()
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
    
//    func frame(for image: UIImage, inImageViewAspectFit imageView: UIImageView) -> CGRect {
//        let imageRatio = (image.size.width / image.size.height)
//        let viewRatio = imageView.frame.size.width / imageView.frame.size.height
//        if imageRatio < viewRatio {
//            let scale = imageView.frame.size.height / image.size.height
//            let width = scale * image.size.width
//            let topLeftX = (imageView.frame.size.width - width) * 0.5
//            return CGRect(x: topLeftX, y: 0, width: width, height: imageView.frame.size.height)
//        } else {
//            let scale = imageView.frame.size.width / image.size.width
//            let height = scale * image.size.height
//            let topLeftY = (imageView.frame.size.height - height) * 0.5
//            return CGRect(x: 0.0, y: topLeftY, width: imageView.frame.size.width, height: height)
//        }
//    }
}


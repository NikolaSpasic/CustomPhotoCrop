//
//  ViewController.swift
//  PhotoCrop
//
//  Created by VTS AppsTeam on 2/1/19.
//  Copyright © 2019 VTS AppsTeam. All rights reserved.
//

import UIKit

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
    
    var overlay: PassthroughView?
    var maskLayer: CAShapeLayer?
    
    var wButton = 0
    var hButton = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for button in aspectRatioBttns! {
            button.layer.cornerRadius = 15
        }
        originalImg = UIImage(named: "Slika")
        imageHolder.image = originalImg
        
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)              //Background view
        backgroundImage.image = UIImage(named: "Slika")
        backgroundImage.contentMode = .scaleAspectFill
        self.view.insertSubview(backgroundImage, at: 0)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)               //Background Blur
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImage.addSubview(blurEffectView)
        
        
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor.black.cgColor
        
        // Create a view filling the imageView.
        overlay = PassthroughView(frame: scrollView.frame)
        overlay!.layer.addSublayer(shapeLayer)
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
        scrollView.bounces = false
        scrollView.isUserInteractionEnabled = false
    }
    
    //MARK: Button Actions

    @IBAction func doneBttnPressed(_ sender: Any) {
        if let imgDidCrop = croppedImage {
            UIImageWriteToSavedPhotosAlbum(imgDidCrop, nil, nil, nil)
        }
    }
    
    @IBAction func cancelBttnPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
            self.overlay!.alpha = 0
        }, completion: { (finished: Bool) in
            self.imageHolder.image = self.originalImg
            self.overlay!.removeFromSuperview()
            self.maskLayer?.isHidden = true
            self.shapeLayer.isHidden = true
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
                self.scrollView.setZoomScale(0.0, animated: true)
            })
        })
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    @IBAction func cropBttnPressed(_ sender: Any) {
       
    }
    
    @IBAction func aspectRatioBttnsPressed(_ sender: Any) {
        scrollView.setZoomScale(1.0, animated: true)
        clear()
        guard let button = sender as? UIButton else {
            return
        }
        scrollView.isUserInteractionEnabled = true
        let imgSize = frame(for: originalImg!, inImageViewAspectFit: scrollView)
        var toRect: CGRect?
        
        switch button.tag {
        case 0:
            wButton = 1
            hButton = 1
        case 1:
            wButton = 16
            hButton = 9
        case 2:
            wButton = 4
            hButton = 3
        case 3:
            wButton = 2
            hButton = 3
        case 4:
            wButton = 3
            hButton = 4
        default:
            print("try again")
            return
        }
        let cropSize = calculateAspectRatio(width: wButton, height: hButton, originalImgFrame: imgSize)
        if imgSize.height > imgSize.width {
            toRect = CGRect(x: 0, y: 0, width: imgSize.width, height: cropSize)
        } else {
            toRect = CGRect(x: 0, y: 0, width: cropSize, height: imgSize.height)
        }
        let croppedImageRatio = cropImage(image: originalImg!, toRect: toRect!)

        let croppedImgFrame = frame(for: croppedImageRatio!, inImageViewAspectFit: scrollView)
        let lastPoint = CGPoint(x: croppedImgFrame.maxX, y: croppedImgFrame.maxY)
        updatePath(from: croppedImgFrame.origin, to: lastPoint)
        let imgframeafterzooming = framed(for: originalImg!, inImageViewAspectFit: imageHolder!)
        let zoomScale = rec.height / imgframeafterzooming.height
        scrollView.setZoomScale(zoomScale, animated: true)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageHolder
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let imgframe = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
        let point = imgframe.origin.y - rec.minY //rename point
        scrollView.contentInset = UIEdgeInsets(top: -point, left: rec.minX, bottom: -point, right: rec.minX)
        
        if imgframe.height < rec.height {
            let distance = (rec.height - imgframe.height) / 2    //rename distance
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            if rec.width > rec.height {
                scrollView.contentInset = UIEdgeInsets(top: -point + distance, left: offsetY, bottom: -point + distance, right: 0)
            } else {
                scrollView.contentInset = UIEdgeInsets(top: -point + distance, left: rec.minX, bottom: -point + distance, right: rec.minX)
            }
        }
        croppedImage = screenshot()
//        croppedImage = originalImg!.scaleImageToSize(newSize: scrollView.bounds.size, offset: scrollView.contentOffset, scrollViewFrame: scrollView.frame)
    }
    
//    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        croppedImage = screenshot()
////        croppedImage = originalImg!.scaleImageToSize(newSize: scrollView.bounds.size, offset: scrollView.contentOffset, scrollViewFrame: scrollView.frame)
//    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imgframe = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
        let point = imgframe.origin.y - rec.minY //rename point
        scrollView.contentInset = UIEdgeInsets(top: -point, left: rec.minX, bottom: -point, right: rec.minX)
        if imgframe.height < rec.height {
            let distance = (rec.height - imgframe.height) / 2    //rename distance
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            if rec.width > rec.height {
                scrollView.contentInset = UIEdgeInsets(top: -point + distance, left: offsetY, bottom: -point + distance, right: 0)
            } else {
                scrollView.contentInset = UIEdgeInsets(top: -point + distance, left: rec.minX, bottom: -point + distance, right: rec.minX)
            }
        }
        print(scrollView.zoomScale)
    }
    
    func calculateAspectRatio(width: Int, height: Int, originalImgFrame: CGRect) -> CGFloat {
        if width > height {
            let croppedSize = originalImgFrame.height * CGFloat(width) / CGFloat(height)
            return croppedSize
        } else if height > width {
            let croppedSize = originalImgFrame.height * CGFloat(width) / CGFloat(height)
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
        let cgImage :CGImage! = image.cgImage
        let croppedCGImage: CGImage! = cgImage.cropping(to: toRect)
        
        return UIImage(cgImage: croppedCGImage)
    }
    
    func clear() {
        imageHolder.layer.sublayers = nil
        overlay!.layer.addSublayer(shapeLayer)
        overlay!.alpha = 0
        self.view.addSubview(overlay!)
    }
    
    private func updatePath(from startPoint: CGPoint, to point: CGPoint) {
        maskLayer?.isHidden = false
        shapeLayer.isHidden = false
        let size = CGSize(width: point.x - startPoint.x, height: point.y - startPoint.y)
        rec = CGRect(origin: startPoint, size: size)
        shapeLayer.path = UIBezierPath(rect: rec).cgPath
        // Create the frame for the clear part
        let path = UIBezierPath(rect: overlay!.bounds)
        // Create the path.
        path.append(UIBezierPath(rect: rec))
        maskLayer!.path = path.cgPath
        maskLayer!.fillRule = CAShapeLayerFillRule.evenOdd
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.transitionFlipFromTop], animations: {
            self.overlay?.alpha = 0
        }, completion: { (finished: Bool) in
            self.view.addSubview(self.overlay!)
            UIView.animate(withDuration: 0.3, animations: {
                self.overlay?.alpha = 1
            })
        })
    }
    
    func frame(for image: UIImage, inImageViewAspectFit imageView: UIScrollView) -> CGRect { //and scrollview vars
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
    func framed(for image: UIImage, inImageViewAspectFit imageView: UIImageView) -> CGRect {                //rename framed
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
    
    func captureVisibleRect() -> UIImage{
        croppedImage = screenshot()//originalImg!.scaleImageToSize(newSize: rec.size, offset: scrollView.contentOffset)
//        croppedImage = originalImg!.scaleImageToSize(newSize: scrollView.bounds.size, offset: scrollView.contentOffset, scrollViewFrame: scrollView.frame)
        return croppedImage!
    }
    
    func screenshot() -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(self.rec.size, true, 0)
//        let offset = self.scrollView.contentOffset
//        let thisContext = UIGraphicsGetCurrentContext()
//        thisContext?.translateBy(x: -offset.x/*- ((scrollView.frame.width - rec.width) / 2)*/, y: -offset.y/*- ((scrollView.frame.height - rec.height) / 2)*/)
//        self.scrollView.layer.render(in: thisContext!)
//        let visibleScrollViewImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
        
        var visibleRectes = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        let theScale = 1 / scrollView.zoomScale     // probaj 0.5
//        visibleRectes.origin.x *= theScale
//        visibleRectes.origin.y *= theScale
        let imgframe = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
        visibleRectes.origin.x = (scrollView.contentOffset.x - ((imageHolder.frame.width - imgframe.width) / 2)) * (originalImg!.size.width / (imgframe.width))// * theScale//(imgframe.width - scrollView.frame.width) * theScale
        visibleRectes.origin.y = (scrollView.contentOffset.y - ((imageHolder.frame.height - imgframe.height) / 2)) * (originalImg!.size.height / imgframe.height)// * theScale//(imgframe.height - scrollView.frame.height) * theScale
        visibleRectes.size.width = rec.width * (originalImg!.size.width / imgframe.width)
        visibleRectes.size.height = rec.height * (originalImg!.size.height / imgframe.height)
//        print("w and h: \(visibleRectes.size.width), \(visibleRectes.size.height), \(imageHolder.frame.width / rec.width), offset: \(visibleRectes.origin), \(scrollView.contentOffset)")
        print("w and h: \(visibleRectes.size.width), \(visibleRectes.size.height), \(imageHolder.frame.width / rec.width), offset: \(visibleRectes.origin), \(scrollView.contentOffset)")
        let imageRef = originalImg!.cgImage!.cropping(to: visibleRectes)//originalImg!.cgImage!.cropping(to: rect)
        let croppedImage = UIImage(cgImage: imageRef!)
        
        
        return croppedImage
    }
    
    
    
    
    
//
//    func tappedCrop() {
//        print("tapped crop")
//        
//        var imgX: CGFloat = 0
//        if scrollView.contentOffset.x > 0 {
//            imgX = scrollView.contentOffset.x / scrollView.zoomScale
//        }
//
//        let gapToTheHole = view.frame.height/2 - rec.height/2
//        var imgY: CGFloat = 0
//        if scrollView.contentOffset.y + gapToTheHole > 0 {
//            imgY = (scrollView.contentOffset.y + gapToTheHole) / scrollView.zoomScale
//        }
//
//        let imgW = holeRect.width  / scrollView.zoomScale
//        let imgH = holeRect.height  / scrollView.zoomScale
//
//        print("IMG x: \(imgX) y: \(imgY) w: \(imgW) h: \(imgH)")
//
//        let cropRect = CGRect(x: imgX, y: imgY, width: imgW, height: imgH)
//        let imageRef = img.cgImage!.cropping(to: cropRect)
//        let croppedImage = UIImage(cgImage: imageRef!)
//
//        UIImageWriteToSavedPhotosAlbum(croppedImage, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
//
//        self.dismiss(animated: true, completion: nil)
//    }
//
//
    
    
    
//    func croppedImages() -> UIImage {
//        let zoomReciprocal = 1.0 / scrollView.zoomScale
//        let xOffset = -scrollView.contentOffset.x - ((scrollView.frame.width - rec.size.width) / 2)
//        let yOffset = -scrollView.contentOffset.y - ((scrollView.frame.height - rec.size.height) / 2)
//
//        let croppedRect = CGRect(x: -xOffset, y: -yOffset, width: originalImg!.size.width * zoomReciprocal, height: originalImg!.size.width * zoomReciprocal)
//        let croppedImgRef = originalImg?.cgImage?.cropping(to: croppedRect)
//        return UIImage(cgImage: croppedImgRef!)
//    }
}
class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}


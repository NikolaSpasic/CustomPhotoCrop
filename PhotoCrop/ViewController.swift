//
//  ViewController.swift
//  PhotoCrop
//
//  Created by VTS AppsTeam on 2/1/19.
//  Copyright © 2019 VTS AppsTeam. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageHolder: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 10.0
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var doneBttn: UIButton!
    @IBOutlet weak var imagePickerBttn: UIButton!
    
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
    
    var wButton = CGFloat(0.0)
    var hButton = CGFloat(0.0)
    var bttnAspectRatios = [AspectRatioBttn]()
    var imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneBttn.layer.cornerRadius = 15
        imagePickerBttn.layer.cornerRadius = 15
        self.collectionView.delegate = self
        self.collectionView.isUserInteractionEnabled = false
    
        bttnAspectRatios = [
            AspectRatioBttn(names: "Facebook post", widths: 1.91, heights: 1),
            AspectRatioBttn(names: "Facebook cover", widths: 2.64, heights: 1),
            AspectRatioBttn(names: "Twitter", widths: 2, heights: 1),
            AspectRatioBttn(names: "Pinterest", widths: 1, heights: 1.5),
            AspectRatioBttn(names: "LinkedIn post", widths: 1.76, heights: 1),
            AspectRatioBttn(names: "Instagram", widths: 1, heights: 1),
            AspectRatioBttn(names: "Google Plus", widths: 2.5, heights: 1),
            AspectRatioBttn(names: "Square", widths: 1, heights: 1),
            AspectRatioBttn(names: "16:9", widths: 16, heights: 9),
            AspectRatioBttn(names: "9:16", widths: 9, heights: 16),
            AspectRatioBttn(names: "4:3", widths: 4, heights: 3),
            AspectRatioBttn(names: "3:4", widths: 3, heights: 4)
        ]

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
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        if let selectedImage = info[.originalImage] as? UIImage {
            
            self.imageHolder.image = nil
            self.originalImg = nil
            
            self.imageHolder.image = selectedImage
            self.originalImg = selectedImage
            if let img = originalImg {

                originalImg = img.fixedOrientation()
                imageHolder.image = originalImg
            }
            
            let backgroundImage = UIImageView(frame: UIScreen.main.bounds)              //Background view
            backgroundImage.image = originalImg
            backgroundImage.contentMode = .scaleAspectFill
            self.view.insertSubview(backgroundImage, at: 0)
            
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)               //Background Blur
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundImage.addSubview(blurEffectView)
            
            var buttonIndex = 0
            for button in bttnAspectRatios {
                if button.name == "Original" {
                    bttnAspectRatios.remove(at: buttonIndex)
                }
                buttonIndex += 1
            }
            bttnAspectRatios.append(AspectRatioBttn(names: "Original", widths: imageHolder.image!.size.width, heights: imageHolder.image!.size.height))
            collectionView.isUserInteractionEnabled = true
            collectionView.reloadData()
            clear()
            scrollView.setZoomScale(1.0, animated: true)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Button Actions
    @IBAction func doneBttnPressed(_ sender: Any) {
        if let imgDidCrop = croppedImage {
            UIImageWriteToSavedPhotosAlbum(imgDidCrop, nil, nil, nil)
        }
    }
    
    @IBAction func imagePickerBttnPressed(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    //MARK: CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bttnAspectRatios.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! CollectionViewCell
        let aspectRatio = bttnAspectRatios[indexPath.row]
        cell.aspectRatioLabel.text = aspectRatio.name
        cell.aspectRatioImageView.image = aspectRatio.image
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell {
            let aspectRatio = bttnAspectRatios[indexPath.row]
            if aspectRatio.name.hasPrefix("Facebook") {
                cell.aspectRatioImageView.image = UIImage(named: "Facebookactive")
            } else {
                cell.aspectRatioImageView.image = UIImage(named: "\(aspectRatio.name)active")
            }
            
            scrollView.setZoomScale(1.0, animated: true)
            clear()
            
            scrollView.isUserInteractionEnabled = true
            let imgSize = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
            var toRect: CGRect?
            
            wButton = aspectRatio.width
            hButton = aspectRatio.height
            let cropSize = calculateAspectRatio(width: wButton, height: hButton, originalImgFrame: imgSize)
            if imgSize.height > imgSize.width {
                toRect = CGRect(x: 0, y: 0, width: cropSize, height: imgSize.height)
            } else {
                toRect = CGRect(x: 0, y: 0, width: cropSize, height: imgSize.height)
            }
            let croppedImageRatio = cropImage(image: originalImg!, toRect: toRect!)
            
            let croppedImgFrame = frame(for: croppedImageRatio!, inImageViewAspectFit: scrollView)
            
            let lastPoint = CGPoint(x: croppedImgFrame.maxX, y: croppedImgFrame.maxY)
            updatePath(from: croppedImgFrame.origin, to: lastPoint)                 //from and to are starting and ending points for selected area
    
            if imgSize.width > imgSize.height {
                let zoomScale = rec.height / imgSize.height
                scrollView.setZoomScale(zoomScale, animated: true)
            } else {
                let zoomScale = rec.width / imgSize.width
                scrollView.setZoomScale(zoomScale, animated: true)
            }
            
            let imgframe = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
            if originalImg!.size.width > originalImg!.size.height {
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
            } else {
                let point = imgframe.origin.y - rec.minY //rename point
                let point2 = imgframe.origin.x - rec.minX
                scrollView.contentInset = UIEdgeInsets(top: -point, left: -point2, bottom: -point, right: -point2)
                
                DispatchQueue.global(qos: .background).async {
                    if imgframe.width <= self.rec.width {
                        if self.rec.height > self.rec.width {
                            DispatchQueue.main.async {
                                let offsetX = max((self.scrollView.bounds.width - self.scrollView.contentSize.width) * 0.5, 0)
                                self.scrollView.contentInset = UIEdgeInsets(top: -point, left: offsetX, bottom: -point, right: 0)
                            }
                        }
                    }
                    if imgframe.width <= self.rec.width {
                        if self.rec.height > self.rec.width {
                            DispatchQueue.main.async {
                                let offsetX = max((self.scrollView.bounds.width - self.scrollView.contentSize.width) * 0.5, 0)
                                self.scrollView.contentInset = UIEdgeInsets(top: -point, left: offsetX, bottom: -point, right: 0)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let centerOffsetX = (self.scrollView.contentSize.width - self.scrollView.frame.size.width) / 2
                                self.scrollView.contentInset = UIEdgeInsets(top: -point, left: -centerOffsetX, bottom: -point, right: -centerOffsetX)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell {
            let aspectRatio = bttnAspectRatios[indexPath.row]
            if aspectRatio.name.hasPrefix("Facebook") {
                cell.aspectRatioImageView.image = UIImage(named: "Facebook")
            } else {
                cell.aspectRatioImageView.image = UIImage(named: "\(aspectRatio.name)")
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageHolder
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let imgframe = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
        if originalImg!.size.width > originalImg!.size.height {
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
        } else {
            let point = imgframe.origin.y - rec.minY //rename point
            let point2 = imgframe.origin.x - rec.minX
            scrollView.contentInset = UIEdgeInsets(top: -point, left: -point2, bottom: -point, right: -point2)
            
            DispatchQueue.global(qos: .background).async {
                if imgframe.width <= self.rec.width {
                    if self.rec.height > self.rec.width {
                        DispatchQueue.main.async {
                            let offsetX = max((self.scrollView.bounds.width - self.scrollView.contentSize.width) * 0.5, 0)
                            self.scrollView.contentInset = UIEdgeInsets(top: -point, left: offsetX, bottom: -point, right: 0)
                        }
                    }
                }
                if imgframe.width <= self.rec.width {
                    if self.rec.height > self.rec.width {
                        DispatchQueue.main.async {
                            let offsetX = max((self.scrollView.bounds.width - self.scrollView.contentSize.width) * 0.5, 0)
                            self.scrollView.contentInset = UIEdgeInsets(top: -point, left: offsetX, bottom: -point, right: 0)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let centerOffsetX = (self.scrollView.contentSize.width - self.scrollView.frame.size.width) / 2
                            self.scrollView.contentInset = UIEdgeInsets(top: -point, left: -centerOffsetX, bottom: -point, right: -centerOffsetX)
                        }
                    }
                }
            }
        }
        croppedImage = cropToSelectedSize()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imgframe = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
        if originalImg!.size.width > originalImg!.size.height {
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
        } else {
            let point = imgframe.origin.y - rec.minY //rename point
            let point2 = imgframe.origin.x - rec.minX
            scrollView.contentInset = UIEdgeInsets(top: -point, left: -point2, bottom: -point, right: -point2)
            
            DispatchQueue.global(qos: .background).async {
                if imgframe.width <= self.rec.width {
                    if self.rec.height > self.rec.width {
                        DispatchQueue.main.async {
                            let offsetX = max((self.scrollView.bounds.width - self.scrollView.contentSize.width) * 0.5, 0)
                            self.scrollView.contentInset = UIEdgeInsets(top: -point, left: offsetX, bottom: -point, right: 0)
                        }
                    }
                }
                if imgframe.width <= self.rec.width {
                    if self.rec.height > self.rec.width {
                        DispatchQueue.main.async {
                            let offsetX = max((self.scrollView.bounds.width - self.scrollView.contentSize.width) * 0.5, 0)
                            self.scrollView.contentInset = UIEdgeInsets(top: -point, left: offsetX, bottom: -point, right: 0)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let centerOffsetX = (self.scrollView.contentSize.width - self.scrollView.frame.size.width) / 2
                            self.scrollView.contentInset = UIEdgeInsets(top: -point, left: -centerOffsetX, bottom: -point, right: -centerOffsetX)
                        }
                    }
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != collectionView {
            croppedImage = cropToSelectedSize()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            if scrollView != collectionView {
                croppedImage = cropToSelectedSize()
            }
        }
    }
    
    func calculateAspectRatio(width: CGFloat, height: CGFloat, originalImgFrame: CGRect) -> CGFloat {
        let croppedSize = originalImgFrame.height * width / height
        return croppedSize
    }
    
    func cropImage(image: UIImage, toRect: CGRect) -> UIImage? {
        let cgImage:CGImage! = image.cgImage
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
        maskLayer?.path = path.cgPath
        maskLayer?.fillRule = CAShapeLayerFillRule.evenOdd
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
    
    func cropToSelectedSize() -> UIImage {
        var visibleRectes = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        let imgframe = framed(for: originalImg!, inImageViewAspectFit: imageHolder)
        let visibleAreaWidthMargin = (scrollView.frame.width - rec.width) / 2           //calculates the selected area
        let visibleAreaHeightMargin = (scrollView.frame.height - rec.height) / 2
        let ratioOfImgsHeight = originalImg!.size.height / imgframe.height          //calculates size ratio of displayed image and original, loaded image
        let ratioOfImgsWidth = originalImg!.size.width / imgframe.width
        
        visibleRectes.origin.x = (scrollView.contentOffset.x - ((imageHolder.frame.width - imgframe.width) / 2) + visibleAreaWidthMargin) * ratioOfImgsWidth                                                            //calculates image frame from imageview, adds selected area, and the whole value is substracted from original content offset. It is then multiplied by ratio of original image to image inside the imageview.
        visibleRectes.origin.y = (scrollView.contentOffset.y - ((imageHolder.frame.height - imgframe.height) / 2) + visibleAreaHeightMargin) * ratioOfImgsHeight
        visibleRectes.size.width = rec.width * ratioOfImgsWidth
        visibleRectes.size.height = rec.height * ratioOfImgsHeight
        
        let imageRef = originalImg!.cgImage!.cropping(to: visibleRectes)
        var croppedImage = UIImage(cgImage: imageRef!)
        
        
        if imgframe.width < rec.width {
            let blankSpace = (rec.width - imgframe.width) * ratioOfImgsWidth
            let expandedSize = CGSize(width: croppedImage.size.width + blankSpace, height: croppedImage.size.height)
            let imageOnWhiteCanvas = drawImageOnCanvas(croppedImage, canvasSize: expandedSize, canvasColor: .white)
            croppedImage = imageOnWhiteCanvas
        }
        if imgframe.height < rec.height {
            let blankSpace = (rec.height - imgframe.height) * ratioOfImgsHeight
            let expandedSize = CGSize(width: croppedImage.size.width, height: croppedImage.size.height + blankSpace)
            let imageOnWhiteCanvas = drawImageOnCanvas(croppedImage, canvasSize: expandedSize, canvasColor: .white)
            croppedImage = imageOnWhiteCanvas
        }
        
        return croppedImage
    }
    
    func drawImageOnCanvas(_ useImage: UIImage, canvasSize: CGSize, canvasColor: UIColor ) -> UIImage {
        let rect = CGRect(origin: .zero, size: canvasSize)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        
        // fill the entire image
        canvasColor.setFill()
        UIRectFill(rect)
        
        // calculate a Rect the size of the image to draw, centered in the canvas rect
        let centeredImageRect = CGRect(x: (canvasSize.width - useImage.size.width) / 2,
                                       y: (canvasSize.height - useImage.size.height) / 2,
                                       width: useImage.size.width,
                                       height: useImage.size.height)
        // get a drawing context
        let context = UIGraphicsGetCurrentContext();
        // "cut" a transparent rectanlge in the middle of the "canvas" image
        context?.clear(centeredImageRect)
        // draw the image into that rect
        useImage.draw(in: centeredImageRect)
        // get the new "image in the center of a canvas image"
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}

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


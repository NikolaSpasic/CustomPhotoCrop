
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
    
    let backgroundImage = UIImageView(frame: UIScreen.main.bounds)

    private let shapeLayer: CAShapeLayer = {
        let _shapeLayer = CAShapeLayer()
        _shapeLayer.fillColor = UIColor.clear.cgColor
        _shapeLayer.strokeColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor
        _shapeLayer.lineWidth = 1
        return _shapeLayer
    }()
    private var startPoint: CGPoint!
    
    var overlay: PassthroughView?
    var maskLayer: CAShapeLayer?
    
    var wButton = CGFloat(0.0)
    var hButton = CGFloat(0.0)
    var bttnAspectRatios = [AspectRatioBttn]()
    var imagePicker = UIImagePickerController()
    var lastSelectedItem: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.isUserInteractionEnabled = false
        
        scrollView.bounces = false
        scrollView.isUserInteractionEnabled = false
        doneBttn.isUserInteractionEnabled = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        doneBttn.layer.cornerRadius = 15
        imagePickerBttn.layer.cornerRadius = 15
        
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {

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
        
        
        self.view.addSubview(overlay!)
        
        backgroundImage.contentMode = .scaleAspectFill
        self.view.insertSubview(backgroundImage, at: 0)
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImage.addSubview(blurEffectView)
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
            
                          //Background view
            backgroundImage.image = originalImg
            
            var buttonIndex = 0
            for button in bttnAspectRatios {
                if button.name == "Original" {
                    bttnAspectRatios.remove(at: buttonIndex)
                }
                buttonIndex += 1
            }
            bttnAspectRatios = [
                AspectRatioBttn(names: "Original", widths: imageHolder.image!.size.width, heights: imageHolder.image!.size.height),
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
            collectionView.isUserInteractionEnabled = true
            collectionView.reloadData()
            overlay!.alpha = 0
            scrollView.setZoomScale(1.0, animated: true)
            doneBttn.isUserInteractionEnabled = true
            scrollView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Button Actions
    @IBAction func doneBttnPressed(_ sender: Any) {
        if lastSelectedItem == nil {
            UIImageWriteToSavedPhotosAlbum(originalImg!, nil, nil, nil)
        } else {
            cropToSelectedSize(completion: {resultImg in
                UIImageWriteToSavedPhotosAlbum(resultImg, nil, nil, nil)
            })
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
        
        if lastSelectedItem == aspectRatio.name {
            if lastSelectedItem!.hasPrefix("Facebook") {
                cell.aspectRatioImageView.image = UIImage(named: "Facebookactive")
            } else {
                cell.aspectRatioImageView.image = UIImage(named: "\(lastSelectedItem!)active")
            }
        } else {
            cell.aspectRatioImageView.image = aspectRatio.image
        }
        
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
            overlay!.alpha = 0
            lastSelectedItem = aspectRatio.name
            scrollView.isUserInteractionEnabled = true
            doneBttn.isUserInteractionEnabled = true
            let imgSize = frame(for: originalImg!, inImageViewAspectFit: imageHolder.frame)
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
            
            let croppedImgFrame = frame(for: croppedImageRatio!, inImageViewAspectFit: scrollView.frame)
            
            let lastPoint = CGPoint(x: croppedImgFrame.maxX, y: croppedImgFrame.maxY)
            updatePath(from: croppedImgFrame.origin, to: lastPoint)                 //from and to are starting and ending points for selected area
    
            if imgSize.width > imgSize.height {
                let zoomScale = rec.height / imgSize.height
                scrollView.setZoomScale(zoomScale, animated: true)
            } else {
                let zoomScale = rec.width / imgSize.width
                scrollView.setZoomScale(zoomScale, animated: true)
            }
            setScrollViewContentInset()
            collectionView.reloadData()
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageHolder
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        setScrollViewContentInset()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setScrollViewContentInset()
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
    
    func frame(for image: UIImage, inImageViewAspectFit viewRect: CGRect) -> CGRect { //and scrollview vars
        let imageRatio = (image.size.width / image.size.height)
        let viewRatio = viewRect.size.width / viewRect.size.height
        if imageRatio < viewRatio {
            let scale = viewRect.size.height / image.size.height
            let width = scale * image.size.width
            let topLeftX = (viewRect.size.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: viewRect.size.height)
        } else {
            let scale = viewRect.size.width / image.size.width
            let height = scale * image.size.height
            let topLeftY = (viewRect.size.height - height) * 0.5
            return CGRect(x: 0.0, y: topLeftY, width: viewRect.size.width, height: height)
        }
    }
    
    func cropToSelectedSize(completion: @escaping (UIImage) -> ()) {
        
        let scrollViewOffset = scrollView.contentOffset
        let imageHolderFrame = imageHolder.frame
        let scrollViewFrame = scrollView.frame

        var visibleRectes = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        let imgframe = frame(for: originalImg!, inImageViewAspectFit: imageHolder.frame)


        DispatchQueue.global(qos: .background).async {
            let visibleAreaWidthMargin = (scrollViewFrame.width - self.rec.width) / 2           //calculates the selected area
            let visibleAreaHeightMargin = (scrollViewFrame.height - self.rec.height) / 2

            let ratioOfImgsHeight = self.originalImg!.size.height / imgframe.height          //calculates size ratio of displayed image and original, loaded image
            let ratioOfImgsWidth = self.originalImg!.size.width / imgframe.width

            visibleRectes.size.width = self.rec.width * ratioOfImgsWidth
            visibleRectes.size.height = self.rec.height * ratioOfImgsHeight

            visibleRectes.origin.x = (scrollViewOffset.x - ((imageHolderFrame.width - imgframe.width) / 2) + visibleAreaWidthMargin) * ratioOfImgsWidth                                                            //calculates image frame from imageview, adds selected area, and the whole value is substracted from original content offset. It is then multiplied by ratio of original image to image inside the imageview.
            visibleRectes.origin.y = (scrollViewOffset.y - ((imageHolderFrame.height - imgframe.height) / 2) + visibleAreaHeightMargin) * ratioOfImgsHeight

            DispatchQueue.main.async {
                let imageRef = self.originalImg!.cgImage!.cropping(to: visibleRectes)
                var croppedImage = UIImage(cgImage: imageRef!)
                if imgframe.width < self.rec.width {
                    let blankSpace = (self.rec.width - imgframe.width) * ratioOfImgsWidth
                    let expandedSize = CGSize(width: croppedImage.size.width + blankSpace, height: croppedImage.size.height)
                    croppedImage = self.drawImageOnCanvas(croppedImage, canvasSize: expandedSize, canvasColor: .white)
                }
                if imgframe.height < self.rec.height {
                    let blankSpace = (self.rec.height - imgframe.height) * ratioOfImgsWidth
                    let expandedSize = CGSize(width: croppedImage.size.width, height: croppedImage.size.height + blankSpace)
                    croppedImage = self.drawImageOnCanvas(croppedImage, canvasSize: expandedSize, canvasColor: .white)
                }
                completion(croppedImage)
            }
        }
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
    
    func setScrollViewContentInset() {
        let imgframe = self.frame(for: self.originalImg!, inImageViewAspectFit: self.imageHolder.frame)
        DispatchQueue.global(qos: .background).async {
            if self.originalImg!.size.width > self.originalImg!.size.height {
                let point = imgframe.origin.y - self.rec.minY //rename point
                DispatchQueue.main.async {
                    self.scrollView.contentInset = UIEdgeInsets(top: -point, left: self.rec.minX, bottom: -point, right: self.rec.minX)
                }
                
                if imgframe.height < self.rec.height {
                    let distance = (self.rec.height - imgframe.height) / 2    //rename distance
                    DispatchQueue.main.async {
                        let offsetY = max((self.scrollView.bounds.height - self.scrollView.contentSize.height) * 0.5, 0)
                        if self.rec.width > self.rec.height {
                            self.scrollView.contentInset = UIEdgeInsets(top: -point + distance, left: offsetY, bottom: -point + distance, right: 0)
                        } else {
                            self.scrollView.contentInset = UIEdgeInsets(top: -point + distance, left: self.rec.minX, bottom: -point + distance, right: self.rec.minX)
                        }
                    }
                }
            } else {
                let point = imgframe.origin.y - self.rec.minY //rename point
                let point2 = imgframe.origin.x - self.rec.minX
                
                DispatchQueue.main.async {
                    self.scrollView.contentInset = UIEdgeInsets(top: -point, left: -point2, bottom: -point, right: -point2)
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

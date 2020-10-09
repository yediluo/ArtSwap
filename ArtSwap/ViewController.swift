//
//  ViewController.swift
//  ArtSwap
//
//  Created by yedi luo on 9/10/20.
//

import UIKit
import SceneKit
import ARKit
import Foundation

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var numberOfImageLabel: UILabel!
    @IBOutlet weak var detectAll: UIButton!
    @IBOutlet weak var sampleImageSwap: UIButton!
    @IBOutlet weak var libraryImageSwap: UIButton!
    @IBOutlet weak var saveImage: UIButton!
    @IBOutlet weak var currentStateLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var UIToggleButton: UIButton!
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
  //  @IBOutlet weak var imageView5: UIImageView!
    
    @IBOutlet weak var B1: UIButton!
    @IBOutlet weak var B2: UIButton!
    @IBOutlet weak var B3: UIButton!
    @IBOutlet weak var B4: UIButton!
   // @IBOutlet weak var B5: UIButton!
    
    
    // tag for imagePicker
    var tag = 1
    
    let imagePickerController = UIImagePickerController()

    
    let rectangleDetector = RectangleDetector()
    var currentTrackImage: ARImageAnchor?
    var isTrackingCurrenImage = false
    var refImageList:Set<ARReferenceImage> = []
    var refImageListArray:Array<ARReferenceImage> = []
    
    
    var isMulti = false
    static var instance: ViewController?
    var lastImage:ARReferenceImage? = nil
    let materialList = [UIImage(named: "1.png"),UIImage(named: "2.png"), UIImage(named: "3.png"),UIImage(named: "4.png"),UIImage(named: "lastSupper.png")]
    var libMaterialList = [UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png")]
    
    var imageToSwap = UIImage(named: "redFrame.png")
    // 0 = looking for rect and detect all image stage, 1 swap with sample image stage, 2 swap with lib image stage
    var stage = 0
    //state is for UIelement
    var state = 0
    
    //UItoggleFlag
    var UIFlag = true
    
    
    // Constant
    // size from 0.1 to 1
    let ImageDetectLabelTextSize:Float = 0.5
    let MaxNumberOfReference = 4
    let LookingForRectLabelText = "Looking For Rectangular Shaped Painting..."
    let ImageFoundLabelText = "Painting Found"
    let SampleImageLabelText = "Sample Image Used"
    let LibraryImageLabelText = "User Image Used"
    
    
    
    //helpping var
    var countImageTracked = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        rectangleDetector.delegate = self
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
       // sceneView.showsStatistics = true
        state0LookingUI()
        roundCornerButton(saveImage)
        roundCornerButton(detectAll)
        roundCornerButton(sampleImageSwap)
        roundCornerButton(libraryImageSwap)
        roundCornerButton(resetButton)
        roundCornerButton(B1)
        roundCornerButton(B2)
        roundCornerButton(B3)
        roundCornerButton(B4)
        //roundCornerButton(B5)
        roundCornerLabel(currentStateLabel)
        roundCornerLabel(numberOfImageLabel)
        currentStateLabel.text = self.LookingForRectLabelText
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ViewController.instance = self
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        runImageTrackingSessionMulti(with: [], runOptions: [.removeExistingAnchors, .resetTracking])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
        }else {
            return
        }
    }

    
    
    @IBAction func UIToggle(_ sender: UIButton) {
        if UIFlag {
            // hide everything
            UIToggleButton.setTitle("Show UI", for: .normal)
            currentStateLabel.isHidden = true
            resetButton.isHidden = true
            detectAll.isHidden = true
            sampleImageSwap.isHidden = true
            saveImage.isHidden = true
            libraryImageSwap.isHidden = true
            numberOfImageLabel.isHidden = true
            librarySelectButtonToggle(false)
            UIFlag = false
        }else {
            //show UI in original stage
            UIToggleButton.setTitle("Hide UI", for: .normal)

            switch state {
            case 0:
                state0LookingUI()
            case 1:
                state1SaveImagePressedUI()
            case 2:
                state2DetectAllPressedUI()
            case 3:
                state3SamplePressedUI()
            case 4:
                state4LibPressedUI()
            default:
                state0LookingUI()
            }
            UIFlag = true
            
        }
    }
    
    @IBAction func sampleSwapPressed(_ sender: UIButton) {
        // user saved at least one referenceImage
        if refImageList.count>0 {
            state3SamplePressedUI()
            stage = 1
            // stop the current tracking session
            isTrackingCurrenImage = false
            currentStateLabel.text = SampleImageLabelText
            runImageTrackingSessionMulti(with: refImageList)
        }
    }
    
    @IBAction func resetPressed(_ sender: UIButton) {
        isMulti = false
        state0LookingUI()
        refImageList.removeAll()
        refImageListArray.removeAll()
        numberOfImageLabel.text = ""
        isTrackingCurrenImage = false
        imageToSwap = UIImage(named: "redFrame.png")
        currentStateLabel.text = self.LookingForRectLabelText
        stage = 0
        libImagePreviewClean(true)
        libMaterialList = [UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png"), UIImage(named: "redFrame.png")]
        librarySelectButtonToggle(false)
        runImageTrackingSessionMulti(with: [], runOptions: [.removeExistingAnchors, .resetTracking])    }
    
    @IBAction func multiDetectPressed(_ sender: UIButton) {
        
        isMulti = true
        state2DetectAllPressedUI()
        imageToSwap = UIImage(named: "redFrame.png")
        currentStateLabel.text = "Detecting All..."
        runImageTrackingSessionMulti(with: refImageList)

    }
    @IBAction func saveImagePressed(_ sender: UIButton) {
        // lastImage exists and is still tracked
        if let saveLastImage = lastImage, isTrackingCurrenImage {
            
            state1SaveImagePressedUI()
            //no replicate
            // set the Limit of the image reference Saved
            if refImageList.count < MaxNumberOfReference {
                refImageList.insert(saveLastImage)
                if !refImageListArray.contains(saveLastImage) {
                    refImageListArray.append(saveLastImage)
                }
                print(refImageListArray.count)
                
                print("\(refImageList.count) image saved")
                if refImageList.count > 1 {
                    numberOfImageLabel.text = "\(refImageList.count) Paintings Tagged"
                }else {
                    numberOfImageLabel.text = "\(refImageList.count) Painting Tagged"
                }
                
                if refImageList.count == MaxNumberOfReference {
                    numberOfImageLabel.text = "Max \(MaxNumberOfReference) Images reached"
                }
            }else {
                numberOfImageLabel.text = "Max \(MaxNumberOfReference) Images reached"
            }
            
            print("number of refImage: \(refImageList.count)")
            
        }
    }
    @IBAction func libraryImageSwapPressed(_ sender: UIButton) {
        
        // user saved at least one referenceImage
        if refImageList.count>0 {
            state4LibPressedUI()
            stage = 2
           // librarySelectButtonToggle(true)
           // imageToSwap = materialList.randomElement() as? UIImage
            
            // stop the current tracking session
            isTrackingCurrenImage = false
            currentStateLabel.text = LibraryImageLabelText
            runImageTrackingSessionMulti(with: refImageList)
        }
    }
    
    /// - Tag: ImageTrackingSession MultiImage
    private func runImageTrackingSessionMulti(with trackingImages: Set<ARReferenceImage>,
                                         runOptions: ARSession.RunOptions = [.removeExistingAnchors]) {
        let configuration = ARImageTrackingConfiguration()
        configuration.maximumNumberOfTrackedImages = trackingImages.count
        configuration.trackingImages = trackingImages
        sceneView.session.run(configuration, options: runOptions)
    }

    


}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}


//MARK: - RectangleDetectorDelegate

extension ViewController: RectangleDetectorDelegate {
// image crop complete
func rectangleFound(rectangleContent: CIImage) {
   // print("recangleFound")
    DispatchQueue.main.async {
        guard let referenceImagePixelBuffer = rectangleContent.toPixelBuffer(pixelFormat: kCVPixelFormatType_32BGRA) else {
            print("Error: Could not convert rectangle content into an ARReferenceImage.")
            return
        }
        let possibleReferenceImage = ARReferenceImage(referenceImagePixelBuffer, orientation: .up, physicalWidth: CGFloat(0.5))
        possibleReferenceImage.validate {[weak self] (error) in
            if let error = error {
                print("Reference image validation failed: \(error.localizedDescription)")
                return
            }
            if self?.isTrackingCurrenImage == false {
                self?.lastImage = possibleReferenceImage
                print("reset cropped reference Image")
                if self?.isMulti == true {
                    self?.runImageTrackingSessionMulti(with: self!.refImageList)
                }else {
                    self?.runImageTrackingSessionMulti(with: [possibleReferenceImage])
                }
            }
            
        }
        
       /* if self.isTrackingCurrenImage == false {
            self.lastImage = possibleReferenceImage
            print("reset cropped reference Image")
            if self.isMulti {
                self.runImageTrackingSessionMulti(with: self.refImageList)
            }else {
                self.runImageTrackingSessionMulti(with: [possibleReferenceImage])
            }
        }
 */

    }
}
}

// MARK: - ARSCNViewDelegate


// Override to create and configure nodes for anchors added to the view's session.
/*   func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
}*/
extension ViewController: ARSCNViewDelegate {
/// - Tag: ImageWasRecognized
func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    print("imageRecognized")
    if let imageAnchor = anchor as? ARImageAnchor {
        isTrackingCurrenImage = true
        currentTrackImage = imageAnchor
        //image searching and detect all stage
        if stage == 0 {
            var nodeRank = refImageList.count + 1
            for image in refImageListArray {
                if image == imageAnchor.referenceImage {
                    nodeRank = refImageListArray.firstIndex(of: image)! + 1
                }
            }
            node.childNode(withName: "planeNode", recursively: true)?.removeFromParentNode()
            node.childNode(withName: "labelNode", recursively: true)?.removeFromParentNode()

            let material = imageToSwap
            let planeNode = createPlaneNode(size: imageAnchor.referenceImage.physicalSize, rotation: -Float.pi/2, contents: material)
            planeNode.name = "planeNode"
            node.addChildNode(planeNode)
            // set the text for display, depth 1, get z axis -.5 to .5, depth 0, get flat one side text, size:0.1 to 1
            let labelNode = createTextNode(text: "\(nodeRank)", depth: 0, content: UIColor.red, size: ImageDetectLabelTextSize)
            labelNode.name = "labelNode"
            node.addChildNode(labelNode)
            print("LabelNode added")
        // sample swap
        }else if stage == 1 {
            for image in refImageListArray {
                if image == imageAnchor.referenceImage {
                    
                    let i = refImageListArray.firstIndex(of: image)!
                    print("Here index i is \(i)")
                    print("Here materiallist size is \(materialList.count)")
                    imageToSwap = materialList[i]
                }
            }

            let material = imageToSwap
            let planeNode = createPlaneNode(size: imageAnchor.referenceImage.physicalSize, rotation: -Float.pi/2, contents: material)
            planeNode.name = "planeNode"
            
            // replace the old material plane with new material plane(here remove the red frame)
            node.childNode(withName: "planeNode", recursively: true)?.removeFromParentNode()
            node.childNode(withName: "labelNode", recursively: true)?.removeFromParentNode()
            node.addChildNode(planeNode)
        //lib swap
        }else {
            var nodeRank = 0
            for image in refImageListArray {
                if image == imageAnchor.referenceImage {
                    let i = refImageListArray.firstIndex(of: image)!
                    imageToSwap = libMaterialList[i]
                    nodeRank = i+1
                }
            }
            let material = imageToSwap
            let planeNode = createPlaneNode(size: imageAnchor.referenceImage.physicalSize, rotation: -Float.pi/2, contents: material)
            planeNode.name = "planeNode"
            let labelNode = createTextNode(text: "\(nodeRank)", depth: 0, content: UIColor.red, size: ImageDetectLabelTextSize)
            labelNode.name = "labelNode"
            print("Number of childNode we have here \(node.childNodes.description)")
            node.childNode(withName: "planeNode", recursively: true)?.removeFromParentNode()
            node.childNode(withName: "labelNode", recursively: true)?.removeFromParentNode()
            print("Number of childNode we have here \(node.childNodes.description)")
            node.addChildNode(labelNode)

            node.addChildNode(planeNode)
        }
        print("planeNode  added")


    }
}

//Depending on the session configuration, ARKit may automatically update anchors in a session. The view calls this method once for each updated anchor.
// Check if the reference image is still found and tracked in the physical world
// if not reset isTrackingCurrent Image to false.
func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    if isMulti {return}
    if let imageAnchor = anchor as? ARImageAnchor, currentTrackImage == anchor {
        currentTrackImage = imageAnchor
        // Reset the timeout if the app is still tracking an image.
        if imageAnchor.isTracked {
            DispatchQueue.main.async {
                self.currentStateLabel.text = self.ImageFoundLabelText
            }
            if(countImageTracked == 0) {
            print("the image is still tracked")
            }
            countImageTracked += 1
       //     resetImageTrackingTimeout()
        }else {
            DispatchQueue.main.async {
                self.currentStateLabel.text = self.LookingForRectLabelText
            }
            isTrackingCurrenImage = false
            print("Image Stopped Tracking")
            countImageTracked = 0
        }
    }
}
}


//MARK: - UIDesignBlock
extension ViewController {
    
    fileprivate func librarySelectButtonToggle(_ value: Bool) {
        B1.isHidden = !value
        B2.isHidden = !value
        B3.isHidden = !value
        B4.isHidden = !value
        //B5.isHidden = true
        imageView1.isHidden = !value
        imageView2.isHidden = !value
        imageView3.isHidden = !value
        imageView4.isHidden = !value
        //imageView5.isHidden = true

    }
    fileprivate func libImagePreviewClean(_ value:Bool) {
        if value {
            imageView1.image = nil
            imageView2.image = nil
            imageView3.image = nil
            imageView4.image = nil
          //  imageView5.image = nil

            imageView1.layer.borderWidth = 0
            imageView2.layer.borderWidth = 0
            imageView3.layer.borderWidth = 0
            imageView4.layer.borderWidth = 0
           // imageView5.layer.borderWidth = 0

        }
    }
    
    func roundCornerButton(_ button: UIButton) {
        button.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.7)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor(rgb: 0xfafcc2).cgColor
    }
    
    func roundCornerLabel(_ label: UILabel) {
        label.layer.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
        label.textColor = .white
        label.layer.cornerRadius = 10
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor(rgb: 0xf6d6ad).cgColor
        
    }
    
    func state0LookingUI() {
        state = 0
        currentStateLabel.isHidden = false
        resetButton.isHidden = false
        detectAll.isHidden = true
        sampleImageSwap.isHidden = true
        saveImage.isHidden = false
        libraryImageSwap.isHidden = true
        numberOfImageLabel.isHidden = true
        librarySelectButtonToggle(false)
    }
    func state1SaveImagePressedUI() {
        state = 1
        currentStateLabel.isHidden = false
        resetButton.isHidden = false
        detectAll.isHidden = false
        saveImage.isHidden = false
        sampleImageSwap.isHidden = true
        libraryImageSwap.isHidden = true
        numberOfImageLabel.isHidden = false
        librarySelectButtonToggle(false)
    }
    
    func state2DetectAllPressedUI() {
        state = 2
        currentStateLabel.isHidden = false
        resetButton.isHidden = false
        detectAll.isHidden = true
        saveImage.isHidden = true
        sampleImageSwap.isHidden = false
        libraryImageSwap.isHidden = false
        numberOfImageLabel.isHidden = false
        librarySelectButtonToggle(false)
    }
    //detectall pressed, then sampleImageSwap
    func state3SamplePressedUI() {
        state = 3
        currentStateLabel.isHidden = false
        resetButton.isHidden = false
        detectAll.isHidden = true
        saveImage.isHidden = true

        sampleImageSwap.isHidden = false
        libraryImageSwap.isHidden = false
        numberOfImageLabel.isHidden = false
        librarySelectButtonToggle(false)
    }
    //detectallpressed, then libraryImageSwap
    func state4LibPressedUI() {
        state = 4
        currentStateLabel.isHidden = false
        resetButton.isHidden = false
        detectAll.isHidden = true
        saveImage.isHidden = true
        sampleImageSwap.isHidden = false
        libraryImageSwap.isHidden = false
        numberOfImageLabel.isHidden = false
        librarySelectButtonToggle(true)
    }
}


//MARK: - UIImagePicker

extension ViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imageViewBorder(_ imageV:UIImageView) {
        imageV.layer.masksToBounds = true
        imageV.layer.borderWidth = 1.5
        imageV.layer.borderColor = UIColor.white.cgColor
        imageV.layer.cornerRadius = 10
        imageV.contentMode = .scaleAspectFill
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        print("My tag here is \(tag)")
        switch tag {
        case 1:
            imageView1.image = image
            imageViewBorder(imageView1)
            libMaterialList[0] = image
        case 2:
            imageView2.image = image
            imageViewBorder(imageView2)

            libMaterialList[1] = image
        case 3:
            imageView3.image = image
            imageViewBorder(imageView3)

            libMaterialList[2] = image
        case 4:
            imageView4.image = image
            imageViewBorder(imageView4)

            libMaterialList[3] = image
        default:
            imageView1.image = image
            imageViewBorder(imageView1)
            libMaterialList[0] = image
        }
        
        
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func imageSelectPressed(_ sender: UIButton) {
        switch sender.currentTitle {
        case "Image 1":
            tag = 1
        case "Image 2":
            tag = 2
        case "Image 3":
            tag = 3
        case "Image 4":
            tag = 4
        default:
            tag = 1
        }
        self.present(imagePickerController, animated: true, completion: nil)

    }
    
}

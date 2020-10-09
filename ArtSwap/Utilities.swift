

import Foundation
import ARKit
import CoreML
import VideoToolbox

extension CIImage {
    
    /// Returns a pixel buffer of the image's current contents.
    func toPixelBuffer(pixelFormat: OSType) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: NSNumber(value: true),
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: NSNumber(value: true)
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(extent.size.width),
                                         Int(extent.size.height),
                                         pixelFormat,
                                         options as CFDictionary, &buffer)
        
        if status == kCVReturnSuccess, let device = MTLCreateSystemDefaultDevice(), let pixelBuffer = buffer {
            let ciContext = CIContext(mtlDevice: device)
            ciContext.render(self, to: pixelBuffer)
        } else {
            print("Error: Converting CIImage to CVPixelBuffer failed.")
        }
        return buffer
    }
    
    /// Returns a copy of this image scaled to the argument size.
    func resize(to size: CGSize) -> CIImage? {
        return self.transformed(by: CGAffineTransform(scaleX: size.width / extent.size.width,
                                                      y: size.height / extent.size.height))
    }
}

extension CVPixelBuffer {
    
    /// Returns a Core Graphics image from the pixel buffer's current contents.
    func toCGImage() -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        
        if cgImage == nil { print("Error: Converting CVPixelBuffer to CGImage failed.") }
        return cgImage
    }
}

extension MLMultiArray {
    /// Zeros out all indexes in the array except for the argument index, which is set to one.
    func setOnlyThisIndexToOne(_ index: Int) {
        if index > self.count - 1 {
            print("Error: Invalid index #\(index)")
            return
        }
        for i in 0...self.count - 1 {
            self[i] = Double(0) as NSNumber
        }
        self[index] = Double(1) as NSNumber
    }
}

/// Creates a SceneKit node with plane geometry, to the argument size, rotation, and material contents.
func createPlaneNode(size: CGSize, rotation: Float, contents: Any?) -> SCNNode {
    let plane = SCNPlane(width: size.width, height: size.height)
    
    plane.firstMaterial?.diffuse.contents = contents
    let planeNode = SCNNode(geometry: plane)
    
    planeNode.eulerAngles.x = rotation
    return planeNode
}


func createTextNode(text: String, depth: CGFloat, content: Any, size: Float) -> SCNNode{
    // set the text for display, depth 1, get z axis -.5 to .5, depth 0, get flat one side text
    let labelText = SCNText(string: text, extrusionDepth: depth)
    labelText.firstMaterial?.diffuse.contents = content
    let labelNode = SCNNode(geometry: labelText)
    let scaleOfText = 0.005 * size
    labelNode.scale = SCNVector3(scaleOfText,scaleOfText,scaleOfText)
    labelNode.eulerAngles.x = -Float.pi/2
    let xadj = 0.005*(labelNode.boundingBox.max.x-labelNode.boundingBox.min.x)/2 * size
    let yadj = 0.03*(labelNode.boundingBox.max.y-labelNode.boundingBox.min.y)/2 * size
    let zadj = 0.005*(labelNode.boundingBox.max.z-labelNode.boundingBox.min.z)/2 * size
    print("x adjustment \(xadj) y adjustment \(yadj) z adjustment \(zadj)")
    labelNode.position = SCNVector3(labelNode.position.x-xadj, labelNode.position.y-yadj, labelNode.position.z + zadj)
    print("labeltext position \(labelNode.position)")
    return labelNode
}
extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}

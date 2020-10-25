//
//  File.swift
//  
//
//  Created by Justin Tan on 10/24/20.
//

import UIKit

import UIKit
import AVFoundation

protocol PreviewViewDelegate: NSObjectProtocol {
    func previewDidTap(_ devicePoint: CGPoint, layerPoint: CGPoint)
}

class PreviewView: UIView {
    private var focusView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    weak var delegate: PreviewViewDelegate? {
        didSet {
            if delegate == nil {
                return
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
            self.addGestureRecognizer(tap)
        }
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    @objc private func onTap(_ recognizer: UITapGestureRecognizer) {
        let layerPoint = recognizer.location(in: self)
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
        self.delegate?.previewDidTap(devicePoint, layerPoint: layerPoint)
    }
    
    func animateFocusAt(_ center: CGPoint) {
        focusView.center = center
        focusView.isHidden = false
        focusView.alpha = 1
        focusView.layer.borderColor = UIColor.red.cgColor
        focusView.layer.borderWidth = 1
        self.addSubview(focusView)
        UIView.animate(withDuration: 0.25, delay: 2, options: .curveEaseInOut) {
            self.focusView.alpha = 0
        } completion: { (ok) in
            self.focusView.isHidden = ok
        }
    }
}

//
//  File.swift
//  
//
//  Created by Justin Tan on 10/23/20.
//

import UIKit
import AVKit

open class PhotoCamera: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let output = AVCapturePhotoOutput()
    private var input: AVCaptureDeviceInput!
    private(set) var isRunning = false
    private let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .unspecified)
    typealias Completion = (_ data:Data?, _ error:Error?) -> ()
    private var completion: Completion?
    var flashEnabled = false
    
    override init() {
        super.init()
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        session.sessionPreset = .photo
        guard let device = getDefaultVideoDevice() else {
            return
        }
        self.input = try? AVCaptureDeviceInput(device: device)
        if self.input == nil {
            return
        }
        if !session.canAddInput(input) {
            return
        }
        session.addInput(input)
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.isHighResolutionCaptureEnabled = true
            output.isPortraitEffectsMatteDeliveryEnabled = output.isPortraitEffectsMatteDeliverySupported
            output.maxPhotoQualityPrioritization = .quality
        }
    }
    
    var torchEnabled = false {
        didSet {
            self.input.device.torchMode = .on
        }
    }
    
    var numOfDevices: Int {
        get {
            return deviceDiscoverySession.uniqueDevicePositionsCount
        }
    }
    
    func start()  {
        if isRunning {
            return
        }
        sessionQueue.async {
            self.session.startRunning()
            self.isRunning = self.session.isRunning
        }
    }
    
    func stop()  {
        if !isRunning {
            return
        }
        sessionQueue.async {
            self.session.stopRunning()
            self.isRunning = self.session.isRunning
        }
    }
    
    func focus(_ point: CGPoint) -> Bool {
        let d = self.input.device
        do {
            if !d.isFocusPointOfInterestSupported {
                return false
            }
            try d.lockForConfiguration()
            if d.isFocusModeSupported(.continuousAutoFocus) {
                d.focusPointOfInterest = point
                d.focusMode = .continuousAutoFocus
            }
            
            if d.isExposurePointOfInterestSupported && d.isExposureModeSupported(.continuousAutoExposure) {
                d.exposurePointOfInterest = point
                d.exposureMode = .continuousAutoExposure
            }
            d.unlockForConfiguration()
            return true
        } catch (_) {
            print("cannot lock device for configuration")
            return false
        }
    }
    
    func switchDevice() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position
            let typ: AVCaptureDevice.DeviceType
            switch self.input.device.position {
            case .unspecified, .front:
                pos = .back
                typ = .builtInDualCamera
            case .back:
                pos = .front
                typ = .builtInTrueDepthCamera
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                pos = .back
                typ = .builtInDualCamera
            }
            let devices = self.deviceDiscoverySession.devices
            var newDevice: AVCaptureDevice? = nil
            if let d = devices.first(where: { $0.position == pos && $0.deviceType == typ }) {
                newDevice = d
            } else if let d = devices.first(where: { $0.position == pos }) {
                newDevice = d
            }
            
            if newDevice == nil {
                return
            }
            
            guard let newVideoInput = try? AVCaptureDeviceInput(device: newDevice!) else {
                return
            }
                    
            self.session.beginConfiguration()
            self.session.removeInput(self.input)
            if self.session.canAddInput(newVideoInput) {
                self.session.addInput(newVideoInput)
                self.input = newVideoInput
            } else {
                self.session.addInput(self.input)
            }
            self.output.maxPhotoQualityPrioritization = .quality
            self.session.commitConfiguration()        }
    }
    
    func capture(_ completion: @escaping Completion) {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
        self.completion = completion
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // TODO:
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                self.completion?(nil, error)
            }
            return
        }
        DispatchQueue.main.async {
            self.completion?(photo.fileDataRepresentation(), nil)
        }
    }
}

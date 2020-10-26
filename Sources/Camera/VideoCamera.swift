//
//  File.swift
//  
//
//  Created by Justin Tan on 10/23/20.
//

import UIKit
import AVKit


protocol VideoCameraDelegate: NSObject {
    func didStartRecording()
    func didFinishRecording(_ url:URL, err: Error?)
}

open class VideoCamera: NSObject, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let output = AVCaptureMovieFileOutput()
    private var input: AVCaptureDeviceInput!
    private(set) var isRunning = false
    private let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .unspecified)
    typealias Completion = (_ url:URL?, _ error:Error?) -> ()
    private var completion: Completion?
    var flashEnabled = false
    private(set) var isRecording = false
    private var backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
    weak var delegate: VideoCameraDelegate?
    
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
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            return
        }
        guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            return
        }
        
        if !session.canAddInput(audioInput) {
            return
        }
        session.addInput(audioInput)
        if session.canAddOutput(output) {
            session.addOutput(output)
            self.session.sessionPreset = .high
            if let connection = output.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
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
            self.session.commitConfiguration()
        }
    }
    
    func startRecording(_ previewOrientation: AVCaptureVideoOrientation) {
        sessionQueue.async {
            if self.output.isRecording {
                return
            }
            if UIDevice.current.isMultitaskingSupported {
                self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            
            // Update the orientation on the movie file output video connection before recording.
            guard let conn = self.output.connection(with: .video) else {
                return
            }
            conn.videoOrientation = previewOrientation
            let availableVideoCodecTypes = self.output.availableVideoCodecTypes
            if availableVideoCodecTypes.contains(.hevc) {
                self.output.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: conn)
            }
            
            // Start recording video to a temporary file.
            let fileName = (NSUUID().uuidString as NSString).appendingPathExtension("mov")!
            let path = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
            self.output.startRecording(to: URL(fileURLWithPath: path), recordingDelegate: self)
        }
    }
    
    func stopRecording() {
        sessionQueue.async {
            self.output.stopRecording()
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop recording.
        DispatchQueue.main.async {
            self.isRecording = self.output.isRecording
            self.delegate?.didStartRecording()
        }
    }
    
    /// - Tag: DidFinishRecording
    public func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        var success = true
        if error != nil {
            let err = error! as NSError
            success = ((err.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        DispatchQueue.main.async {
            self.isRecording = self.output.isRecording
            if self.backgroundRecordingID != .invalid{
                UIApplication.shared.endBackgroundTask(self.backgroundRecordingID)
                self.backgroundRecordingID = .invalid
            }
            if success {
                self.delegate?.didFinishRecording(outputFileURL, err: nil)
                return
            }
            self.delegate?.didFinishRecording(outputFileURL, err: error)
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
        }
    }
}

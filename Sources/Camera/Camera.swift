import AVKit
import UIKit

func getDefaultVideoDevice() -> AVCaptureDevice? {
    if let d = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
        return d
    }
    
    if let d = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
        return d
    }
    
    if let d = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
        return d
    }
    
    return nil
}


func openSystemSettings() {
    let url = URL(string: UIApplication.openSettingsURLString)!
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}


extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        
        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }
        
        return uniqueDevicePositions.count
    }
}

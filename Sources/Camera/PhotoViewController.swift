//
//  File.swift
//  
//
//  Created by Justin Tan on 10/23/20.
//

import UIKit
import AVKit
import SnapKit
import JGProgressHUD

public protocol PhotoViewControllerDelegate: NSObjectProtocol {
    func didCapturePhoto(_ data: Data)
}

open class PhotoViewController: UIViewController, PreviewViewDelegate {
    private var preview: PreviewView!
    private var toolbar: UIView!
    private var closeButton: UIButton!
    private var captureButton: UIButton!
    private var switchButton: UIButton!
    private var camera: PhotoCamera!
    public weak var delegate: PhotoViewControllerDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        setupToolbar()
        configure()
    }
    
    open override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera?.start()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        camera?.stop()
    }
    
    private func setupToolbar() {
        toolbar = UIView()
        toolbar.backgroundColor = .black
        self.view.addSubview(toolbar)
        toolbar.snp.makeConstraints { (maker) in
            maker.height.equalTo(60)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular, scale: .medium)
        
        closeButton = UIButton()
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "chevron.down.circle", withConfiguration: config), for: .normal)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        toolbar.addSubview(closeButton)
        closeButton.snp.makeConstraints { (maker) in
            maker.left.equalTo(20)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(44)
        }
        
        let captureConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular, scale: .large)
        captureButton = UIButton()
        captureButton.tintColor = .white
        captureButton.setImage(UIImage(systemName: "circle.dashed.inset.fill", withConfiguration: captureConfig), for: .normal)
        captureButton.addTarget(self, action: #selector(onCapture), for: .touchUpInside)
        toolbar.addSubview(captureButton)
        captureButton.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(44)
        }
        
        switchButton = UIButton()
        switchButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera", withConfiguration: config), for: .normal)
        switchButton.tintColor = .white
        switchButton.addTarget(self, action: #selector(onSwitch), for: .touchUpInside)
        toolbar.addSubview(switchButton)
        switchButton.snp.makeConstraints { (maker) in
            maker.right.equalTo(-20)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(44)
        }
        
        preview = PreviewView()
        preview.delegate = self
        let previewLayer = preview.layer as! AVCaptureVideoPreviewLayer
        previewLayer.videoGravity = .resizeAspectFill
        self.view.addSubview(preview)
        preview.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.bottom.equalTo(toolbar.snp.top)
        }
    }
    
    private func configure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            if getDefaultVideoDevice() == nil {
                let hud = JGProgressHUD(style: .light)
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = "无法获取摄像头"
                hud.show(in: self.view)
                hud.dismiss(afterDelay: 2)
                return
            }
            camera = PhotoCamera()
            preview.session = camera.session
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
                    self.camera = PhotoCamera()
                    self.preview.session = self.camera.session
                    return
                }
                let c = UIAlertController(title: "请允许使用摄像头", message: "", preferredStyle: .alert)
                c.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                c.addAction(UIAlertAction(title: "设置", style: .`default`, handler: {_ in openSystemSettings()}))
                self.present(c, animated: true, completion: nil)
            })
        default:
            let hud = JGProgressHUD(style: .light)
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "开启摄像头失败"
            hud.show(in: self.view)
            hud.dismiss(afterDelay: 2)
        }
    }
    
    @objc private func onClose() {
        self.preview.isHidden = true
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onCapture() {
        self.captureButton.isEnabled = false
        self.camera.capture { (data, error) in
            self.captureButton.isEnabled = true
            if let err = error {
                let hud = JGProgressHUD(style: .light)
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = err.localizedDescription
                hud.show(in: self.view)
                hud.dismiss(afterDelay: 2)
                return
            }
            self.delegate?.didCapturePhoto(data!)
        }
    }
    
    @objc private func onSwitch() {
        self.camera.switchDevice()
    }
    
    func previewDidTap(_ devicePoint: CGPoint, layerPoint: CGPoint) {
        if self.camera.focus(devicePoint) {
            self.preview.animateFocusAt(layerPoint)
        }
    }
}

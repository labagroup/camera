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

public protocol VideoViewControllerDelegate: NSObjectProtocol {
    func didCaptureVideo(_ url: URL)
}

open class VideoViewController: UIViewController, PreviewViewDelegate, VideoCameraDelegate {
    private var preview: PreviewView!
    private var toolbar: UIView!
    private var closeButton: UIButton!
    private var recordButton: UIButton!
    private var switchButton: UIButton!
    private var camera: VideoCamera!
    private var timerLabel: UILabel!
    private weak var timer: Timer?
    public weak var delegate: VideoViewControllerDelegate?
    private var recordButtonImageConfig: UIImage.SymbolConfiguration!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.recordButtonImageConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular, scale: .large)
        setupToolbar()
        setupTimerLabel()
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
        timer?.invalidate()
    }
    
    private func setupTimerLabel() {
        self.timerLabel = UILabel()
        self.timerLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        self.timerLabel.textColor = .white
        self.timerLabel.isHidden = true
        self.timerLabel.textAlignment = .center
        self.view.addSubview(self.timerLabel)
        self.timerLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(40)
            maker.width.equalToSuperview()
            maker.centerX.equalToSuperview()
            maker.top.equalTo(40)
        }
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
        
        recordButton = UIButton()
        recordButton.tintColor = .white
        recordButton.setImage(UIImage(systemName: "circle.dashed.inset.fill", withConfiguration: self.recordButtonImageConfig), for: .normal)
        recordButton.addTarget(self, action: #selector(onRecord), for: .touchUpInside)
        toolbar.addSubview(recordButton)
        recordButton.snp.makeConstraints { (maker) in
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
            camera = VideoCamera()
            camera.delegate = self
            preview.session = camera.session
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
                    self.camera = VideoCamera()
                    self.camera.delegate = self
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
    
    @objc private func onRecord() {
        if self.camera.isRecording {
            self.camera.stopRecording()
        } else {
            self.camera.startRecording(self.preview.videoPreviewLayer.connection?.videoOrientation ?? .portrait)
        }
        self.recordButton.isEnabled = false
    }
    
    @objc private func onSwitch() {
        // TODO:
        self.camera.switchDevice()
    }
    
    func previewDidTap(_ devicePoint: CGPoint, layerPoint: CGPoint) {
        if self.camera.focus(devicePoint) {
            self.preview.animateFocusAt(layerPoint)
        }
    }
    
    func didStartRecording() {
        self.recordButton.setImage(UIImage(systemName: "stop.circle", withConfiguration: self.recordButtonImageConfig), for: .normal)
        self.recordButton.isEnabled = true
        var secs = 0
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (t) in
            secs += 1
            let h = secs / 3600
            let m = (secs % 3600) / 60
            let s = secs % 60
            self?.timerLabel.isHidden = false
            self?.timerLabel.text = String(format: "%02d:%02d:%02d", h, m, s)
        })
    }
    
    func didFinishRecording(_ url: URL, err: Error?) {
        self.timer?.invalidate()
        self.timerLabel.isHidden = true
        self.recordButton.setImage(UIImage(systemName: "circle.dashed.inset.fill", withConfiguration: self.recordButtonImageConfig), for: .normal)
        self.recordButton.isEnabled = true
        if err != nil {
            let hud = JGProgressHUD(style: .light)
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = err!.localizedDescription
            hud.show(in: self.view)
            hud.dismiss(afterDelay: 2)
            return
        }
        self.delegate?.didCaptureVideo(url)
    }
    
    open override var shouldAutorotate: Bool {
        if self.camera == nil {
            return true
        }
        return !self.camera.isRecording
    }
    
}

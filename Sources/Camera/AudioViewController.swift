//
//  File.swift
//  
//
//  Created by Justin Tan on 10/26/20.
//

import UIKit

open class AudioViewController: UIViewController {
    private var recordButton: UIButton!
    private var timerLabel: UILabel!
    private var titleLabel: UILabel!
    private weak var timer: Timer?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        
        let config = UIImage.SymbolConfiguration(pointSize: 120, weight: .bold, scale: .large)
        self.recordButton = UIButton()
        self.recordButton.setImage(UIImage(systemName: "mic.circle.fill", withConfiguration: config), for: .normal)
        self.recordButton.tintColor = .green
        self.recordButton.addTarget(self, action: #selector(onRecord), for: .touchUpInside)
        self.view.addSubview(self.recordButton)
        self.recordButton.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(120)
        }
        
        self.timerLabel = UILabel()
        self.timerLabel.textColor = .lightText
        self.timerLabel.text = "00:00:00"
        self.timerLabel.textAlignment = .center
        self.timerLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
//        self.timerLabel.isHidden = true
        self.view.addSubview(self.timerLabel)
        self.timerLabel.snp.makeConstraints { (maker) in
            maker.width.equalToSuperview()
            maker.height.greaterThanOrEqualTo(20)
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.recordButton.snp.top).offset(-30)
        }
        
        self.titleLabel = UILabel()
        self.titleLabel.textColor = .lightText
        self.titleLabel.text = "正在录音"
        self.titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        self.titleLabel.textAlignment = .center
//        self.titleLabel.isHidden = true
        self.view.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (maker) in
            maker.width.equalToSuperview()
            maker.height.greaterThanOrEqualTo(20)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.recordButton.snp.bottom).offset(30)
        }
        
        
        let smallConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold, scale: .large)
        let closeButton = UIButton()
        closeButton.tintColor = .lightGray
        closeButton.setImage(UIImage(systemName: "xmark.circle", withConfiguration: smallConfig), for: .normal)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        self.view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(16)
            maker.width.height.equalTo(44)
        }
    }
    
    
    open override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc private func onRecord() {

    }
    
    @objc private func onClose() {
        self.dismiss(animated: true, completion: nil)
    }
}

//
//  PrivateChatPopupViewController.swift
//  UiKitQa
//
//  Created by Amose Vasanth on 20/07/23.
//

import UIKit
import ImageIO
import Lottie

class PrivateChatPopupViewController: UIViewController {

    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var optionBaseView: UIView!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var animateImageView: LottieAnimationView!


    public var delegate: PrivateChatDelegate?
    public var seletedOption = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        animateImageView.contentMode = .scaleAspectFit
        animateImageView.loopMode = .loop
        animateImageView.play()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        optionBaseView.layer.cornerRadius = 10
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addGestures()
    }
    
    func setupUI() {
        viewButton.titleLabel?.font = AppFont.Regular.size(14)
        cancelButton.titleLabel?.font = AppFont.Regular.size(14)
    }
    
    @IBAction func viewAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }
    
    func setOption(text: String?) {
        if let selectedText = text {
            self.delegate?.onPrivateChatAlertSelected(option: selectedText)
        }
        self.dismiss(animated: false)
    }
    
    private func addGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tap.delegate = self
        backgroundView.addGestureRecognizer(tap)
    }
    
    @objc func tapAction() {
        self.dismiss(animated: true)
    }
}
extension PrivateChatPopupViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.optionBaseView) == true {
            return false
        }
        return true
    }
}

//
//  ProgressBar.swift
//  view-animations-starter
//
//  Created by Siva Nagarajan on 20/03/23.
//  Copyright © 2023 Barney. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ProgressBar: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var centerLeading: NSLayoutConstraint!
    @IBOutlet weak var centerTrailing: NSLayoutConstraint!
    @IBOutlet weak var cebterWidth: NSLayoutConstraint!
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewWidth: NSLayoutConstraint!
    let nibName = "ProgressBar"
    @IBInspectable open var primaryColor: UIColor! {
        get {
            return .white
        }
        set {
            progressView.backgroundColor = newValue
            centerView.backgroundColor = newValue
        }
    }

    @IBInspectable open var borderColor: UIColor! {
        get {
            return .lightGray
        }
        set {
            outerView.layer.borderColor = newValue.cgColor
        }
    }

    @IBInspectable open var bgColor: UIColor! {
        get {
            return .clear
        }
        set {
            outerView.backgroundColor = newValue
        }
    }

    enum positons {
        case left
        case right
        case hidden
        case stop
        case visible
    }

    var current: positons = .stop {
        didSet {
            startMove(position: current)
        }
    }

    var progressOn = false {
        didSet {
            self.progressView.isHidden = !progressOn
            self.centerView.isHidden = progressOn
        }
    }

//    deinit {
//        stopLoading()
//    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public func stopLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
            self.current = .stop
        })
    }

    private func commonInit() {
        let view = loadViewFromNib()
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
        contentView.fixInView(self)
    }

    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: ProgressBar.self)
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }

    private func startMove(position: positons) {
        switch position {
        case .left:
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else {return}
                self.centerLeading.priority = UILayoutPriority(750)
                self.centerTrailing.priority = UILayoutPriority(250)
                self.outerView.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if !self.progressOn {
                    self.current = .visible
                }
            })
        case .right:
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else {return}
                self.centerLeading.priority = UILayoutPriority(250)
                self.centerTrailing.priority = UILayoutPriority(750)
                self.outerView.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if !self.progressOn {
                    self.current = .hidden
                }
            })
            break
        case .hidden:
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else {return}
                self.changebarSize(0)
                self.outerView.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if !self.progressOn {
                    self.current = .left
                }
            })
            break
        case .stop:
            self.centerLeading.priority = UILayoutPriority(750)
            self.centerTrailing.priority = UILayoutPriority(250)
            self.changebarSize(0)
            self.progressOn = true
            break
        case .visible:
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else {return}
                self.changebarSize(self.frame.width/2)
                self.outerView.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if !self.progressOn {
                    self.current = .right
                }
            })
        }
    }

    private func changebarSize(_ size: CGFloat) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else {return}
            if !self.progressOn {
                self.cebterWidth.constant = size
            } else {
                self.progressViewWidth.constant = size
            }
            self.layoutIfNeeded()
        }
    }

    public func setProg(per: CGFloat) {
        if per < 1 || per == 100 {
            self.progressOn = false
            current = .left
        } else {
            self.progressOn = true
            self.changebarSize((self.bounds.width * per) / 100)
        }
    }
}

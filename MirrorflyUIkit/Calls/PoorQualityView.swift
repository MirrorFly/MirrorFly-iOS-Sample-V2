//
//  PoorQualityView.swift
//  MirrorflyUIkit
//
//  Created by User on 25/04/24.
//

import UIKit

class PoorQualityView: UIView {
    

    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var parentStackView: UIStackView!
    
    @IBOutlet weak var qualityImageView: UIImageView!
    
    @IBOutlet weak var closeButton: UIImageView!
    
    @IBOutlet weak var closeView: UIView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    
    private func commonInit() {
        let nibName = String(describing: PoorQualityView.self)
        Bundle.main.loadNibNamed(nibName, owner: self, options: nil)
        mainView.frame = self.bounds
        mainView.autoresizingMask = [.flexibleWidth]
        addSubview(mainView)
        mainView.layer.cornerRadius = 10
        mainView.layer.masksToBounds = true
    }
    
}

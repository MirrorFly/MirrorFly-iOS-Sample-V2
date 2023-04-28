//
//  ImageView.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 10/11/21.
//

import Foundation
import BSImagePicker

extension UIImageView {
    func setCircleView() {
        self.layer.cornerRadius = (self.frame.size.width ) / 2
        self.clipsToBounds = true
        self.layer.borderWidth = 3.0
        self.layer.borderColor = UIColor.white.cgColor
    }
}

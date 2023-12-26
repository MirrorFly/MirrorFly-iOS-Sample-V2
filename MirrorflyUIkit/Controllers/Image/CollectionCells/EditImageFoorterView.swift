//  EditImageFoorterView.swift
//  MirrorflyUIkit
//  Created by User on 02/09/21.

import UIKit

class EditImageFoorterView: UICollectionReusableView {
    @IBOutlet weak var name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    func setupUI() {
        name.font = UIFont.font10px_appSemibold()
    }
}

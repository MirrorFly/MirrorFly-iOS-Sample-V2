//
//  EditFooterView.swift
//  MirrorflyShareKit
//
//  Created by Sowmiya on 01/03/23.
//

import UIKit

class EditImageSharedFoorterView: UICollectionReusableView {
    @IBOutlet weak var name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    func setupUI() {
        name.font = UIFont.font10px_appSemibold()
    }
}

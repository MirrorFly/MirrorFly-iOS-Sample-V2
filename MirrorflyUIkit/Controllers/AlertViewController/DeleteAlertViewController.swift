//
//  DeleteAlertViewController.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 13/12/21.
//

import UIKit

class DeleteAlertViewController: UIViewController {
    @IBOutlet weak var contentStackView: UIView?
    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var deleteButton: UIButton?
    @IBOutlet weak var deleteDecriptionLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentStackView?.layer.cornerRadius = 10.0
    }

}

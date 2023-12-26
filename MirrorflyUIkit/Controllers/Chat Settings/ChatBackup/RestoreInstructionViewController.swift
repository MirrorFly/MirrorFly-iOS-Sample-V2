//
//  RestoreInstructionViewController.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 22/11/22.
//

import UIKit

class RestoreInstructionViewController: UIViewController {

    @IBOutlet weak var instructionTableview: UITableView!
    @IBOutlet weak var switchBaseView: UIView!
    @IBOutlet weak var autoBackupSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    var vcTitle: String!
    
    private var instructionList = [instructionOne, instructionTwo, instructionThree, instructionFour]
    private var instructionImageList = [instructionOneImage, instructionTwoImage, instructionThreeImage, instructionFourImage]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switchBaseView.layer.borderColor = Color.recentChatSelectionColor.cgColor
        switchBaseView.layer.borderWidth = 0.7
        switchBaseView.layer.cornerRadius = 2
        instructionTableview.register(UINib(nibName: Identifiers.restoreInstructionsTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.restoreInstructionsTableViewCell)
        instructionTableview.delegate = self
        instructionTableview.dataSource = self
        autoBackupSwitch.isUserInteractionEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        autoBackupSwitch.transform = CGAffineTransform(scaleX: 0.60, y: 0.60)
        autoBackupSwitch.layer.borderColor = autoBackupSwitch.isOn ? Color.muteSwitchColor.cgColor : UIColor.darkGray.cgColor
        autoBackupSwitch.thumbTintColor = autoBackupSwitch.isOn ? Color.muteSwitchColor : UIColor.darkGray
        autoBackupSwitch.layer.borderWidth = 2
        autoBackupSwitch.layer.cornerRadius = autoBackupSwitch.bounds.height/2
        autoBackupSwitch.decreaseThumb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.autoBackupSwitch.setOn(true, animated: true)
            self.viewDidLayoutSubviews()
        }
    }
    
    @IBAction func doneAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func autoBackupSwitchAction(_ sender: UISwitch) {
        sender.layer.borderColor = sender.isOn ? Color.muteSwitchColor.cgColor : UIColor.darkGray.cgColor
        sender.thumbTintColor = sender.isOn ? Color.muteSwitchColor : UIColor.darkGray
    }
    

}
extension RestoreInstructionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        instructionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.restoreInstructionsTableViewCell, for: indexPath) as? RestoreInstructionsTableViewCell {
            let index = indexPath.row
            cell.separatorInset = .init(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            cell.numberLabel.text = "\(index+1)."
            cell.infoImageView.image = UIImage(named: instructionImageList[index])
            cell.infoLabel.text = instructionList[index]
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
}

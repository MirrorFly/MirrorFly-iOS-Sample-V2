//
//  StarredMessagesListViewController.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya on 05/12/22.
//

import Foundation
import UIKit

class StarredMessagesListViewController : UIViewController {
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var starredMessageLabel: UILabel?
    @IBOutlet weak var navigationBar: UIView?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func onTapBackButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension StarredMessagesListViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

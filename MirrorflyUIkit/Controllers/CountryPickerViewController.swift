
//  CountryPickerViewController.swift
//  MirrorflyUIkit
//  Created by User on 17/08/21.

import UIKit

protocol CountryPickerDelegate: class {
    func selectedCountry(country: Country)
}
class CountryPickerViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var countrytable: UITableView!
    public var countryArray = [Country]()
    var searchCountry = [Country]()
    weak var delegate: CountryPickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDefaults()
        self.title = selectCountry
        searchBar.placeholder = search
        setupAutomation()
    }
    
    // MARK: Automation Setup
    func setupAutomation() {
        searchBar.setAutomationIdentifier(label: countrySearchString, id: countrySearchAM)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func configureDefaults()   {
        searchCountry = countryArray
        countrytable.reloadData()
    }
    
    func dismiss () {
        self.navigationController?.popViewController(animated: true)
    }
}

// UITableView Delegate Methods
extension CountryPickerViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchCountry.count > 0 {
            return searchCountry.count
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.country)
        if searchCountry.count > 0 {
            cell?.textLabel?.font = UIFont.font15px_appRegular()
            cell?.textLabel?.text = searchCountry[indexPath.row].name
            cell?.textLabel?.font = UIFont.font15px_appRegular()
            cell?.textLabel?.textAlignment = .left
            cell?.isUserInteractionEnabled = true
            return cell!
        }else{
            cell?.textLabel?.font = UIFont.font15px_appMedium()
            cell?.textLabel?.textAlignment = .center
            cell?.textLabel?.text = ErrorMessage.noCountriesFound
            cell?.isUserInteractionEnabled = false
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        delegate?.selectedCountry(country: searchCountry[indexPath.row])
        dismiss()
    }
}

// SearchBar Delegate Method
extension CountryPickerViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){

            searchCountry = searchText.isEmpty ? countryArray : countryArray.filter{ $0.name.contains(searchText.capitalized) || $0.dial_code.contains(searchText.capitalized) ||
                $0.code.contains(searchText.uppercased())
        }
        
        countrytable.reloadData()
    }
}

//
//  QRCodeScanner.swift
//  MirrorflyUIkit
//
//  Created by John on 17/01/22.
//

import UIKit
import MirrorFlySDK


enum Browsers : String {
    
    case chrome = "chrome"
    case edge = "edge"
    case firefox = "firefox"
    case safari = "safari"
    case ie = "ie"
    case opera = "opera"
    case uc = "uc"
}

class QRCodeScanner: UIViewController {

    var qrCodeScannerModel : QRCodeScannerViewModel?
    @IBOutlet weak var blackView: UIView!
    @IBOutlet weak var linkLabel: UILabel!
    
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var addDeviceButton: UIButton!
    @IBOutlet weak var webLoginInfoStackView: UIStackView!
    @IBOutlet weak var scannerStackView: UIStackView!
    @IBOutlet weak var logoutText: UILabel!
    @IBOutlet weak var logoutImage: UIImageView!
    @IBOutlet weak var webLoginInfoTable: UITableView!
    
    var webLoginList = [WebLoginInfo?]()
    
    @IBOutlet weak var scannerView: QRScannerView? {
        didSet {
            scannerView?.delegate = self
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        setUpUI()
        checkForLogin()
    }
    
    private func configure() {
        qrCodeScannerModel = QRCodeScannerViewModel()
        WebLoginsManager.shared.webLogoutDelegate = self
    }
    
    private func setUpUI() {
        qrCodeScannerModel?.resetConnection()
        setUpStatusBar()
        webLoginInfoTable.delegate = self
        webLoginInfoTable.dataSource = self
        
        webLoginInfoTable.register(UINib(nibName: Identifiers.webSettingsCell , bundle: .main), forCellReuseIdentifier: Identifiers.webSettingsCell)
        
        logoutText.isUserInteractionEnabled = true
        logoutText.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(logoutWebLogin(_:))))
        
        logoutImage.isUserInteractionEnabled = true
        logoutImage.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(logoutWebLogin(_:))))
        
        linkLabel.text = "Visit "+WEB_LOGIN_URL+" on \n your computer and scan the QR code"
    }
    
    func checkForLogin() {
        let webLogingsInfo = qrCodeScannerModel?.getRecentWebLogin()
        let isEmpty = webLogingsInfo?.isEmpty ?? false
        if isEmpty {
            showScannerView(show: true)
            scannerView?.startScanning()
            addNewDevice()
        } else {
            showScannerView(show: false)
            scannerView?.stopScanning()
            webLoginList = webLogingsInfo ?? [WebLoginInfo]()
            resetTable()
        }
    }
    
    func resetTable() {
        webLoginInfoTable.reloadData()
    }
    
    func removeLoginFromTable(socketId : String) {
        webLoginList = webLoginList.filter{$0?.token != socketId}
        resetTable()
        if webLoginList.isEmpty {
            navigateBack()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !(scannerView?.isRunning ?? false) {
            scannerView?.stopScanning()
        }
    }
    
    private func navigateBack() {
        scannerView?.stopScanning()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        navigateBack()
    }
    
    private func hanldeBlackView(showScanner : Bool){
        if showScanner {
            scannerView?.isHidden = false
            blackView.isHidden = true
        } else {
            scannerView?.isHidden = true
            blackView?.isHidden = false
        }
    }
    
    @objc private func logoutWebLogin(_ sender : Any) {
        if NetworkReachability.shared.isConnected {
            AppAlert.shared.showAlert(view: self, title: nil, message: youWantToLogout, buttonOneTitle: noButton, buttonTwoTitle: yesButton)
            AppAlert.shared.onAlertAction = { [weak self] (result)  ->
                Void in
                if result == 1 {
                    self?.qrCodeScannerModel?.logoutFromAllDevice()
                }else {
                    
                }
            }
            
           
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    @IBAction func addDevice(_ sender: Any) {
        if NetworkReachability.shared.isConnected {
            showScannerView(show: true)
            hanldeBlackView(showScanner: false)
            addNewDevice()
            
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    func addNewDevice() {
        scannerView?.stopScanning()
        qrCodeScannerModel?.resetConnection()
        qrCodeScannerModel?.getSocketId(completionHandler: { [weak self] isSuccess, message in
            self?.hanldeBlackView(showScanner: false)
            if isSuccess {
                self?.hanldeBlackView(showScanner: true)
                self?.scannerView?.startScanning()
            }else {
                AppAlert.shared.showToast(message: errorOccurred)
                self?.navigateBack()
            }
            
        })
    }
    
    private func showScannerView(show : Bool) {
        if show {
            scannerStackView.isHidden = false
            webLoginInfoStackView.isHidden = true
            headerTitle.text = scanCode
            addDeviceButton.isHidden = true
        } else {
            scannerView?.stopScanning()
            scannerStackView.isHidden = true
            webLoginInfoStackView.isHidden = false
            headerTitle.text = webSettings
            addDeviceButton.isHidden = false
        }
    }
}


extension QRCodeScanner: QRScannerViewDelegate {
    func qrScanningDidStop() {
      //  resetScanner()
        print("QRCodeScanner qrScanningDidStop")
    }
    
    func qrScanningDidFail() {
      //  resetScanner()
        print("QRCodeScanner qrScanningDidFail")
        AppAlert.shared.showAlert(view: self, title: error, message: qrCodeErrorMessage, buttonTitle: okButton)
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
       // hanldeBlackView(showScanner: false)
        self.startLoading(withText: pleaseWait)
        print("QRCodeScanner qrScanningSucceededWithCode \(str)")
        qrCodeScannerModel?.decryptQRCodeData(qrData: str ?? "", completionHandler: {  [weak self] isSuccess, message in
            print("QRCodeScanner qrScanningSucceededWithCode decryptQRCodeData \(isSuccess) \(message)")
            if isSuccess {
                self?.navigateBack()
            } else {
                AppAlert.shared.showToastWithDuration(message: invalidQRMessage, duration: 1.0)
                self?.checkForLogin()
            }
            self?.stopLoading()
        })
    }
    
    
}

extension QRCodeScanner : WebLogoutDelegate {
    func didLogoutWeb(socketId: String) {
        print("QRCodeScanner didGetLogoutMessage \(socketId)")
        removeLoginFromTable(socketId: socketId)
    }
}

extension QRCodeScanner : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return webLoginList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.webSettingsCell, for: indexPath) as? WebSettingsCell)!
        let webLoginInfo = webLoginList[indexPath.row]
        
        var browser = webLoginInfo?.browser ?? ""
        cell.browserName?.text = browser
        
        browser = browser.lowercased()
        
        if browser.contains(Browsers.chrome.rawValue) {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_chrome)
        } else if browser.contains(Browsers.edge.rawValue) {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_edge)
        } else if browser.contains(Browsers.firefox.rawValue) {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_fireFox)
        } else if browser.contains(Browsers.safari.rawValue) {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_safari)
        } else if browser.contains(Browsers.ie.rawValue) {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_internetExp)
        } else if browser.contains(Browsers.opera.rawValue) {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_opera)
        } else if browser.contains(Browsers.uc.rawValue) {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_ucBrowser)
        } else {
            cell.browserIcon?.image = UIImage(named: ImageConstant.ic_web_login_internetExp)
        }
        
        cell.loginTime?.text =  DateFormatterUtility.shared.convertMillisecondsToWebLoginTime(milliSeconds: webLoginInfo?.loginTime ?? 0)
        
        if indexPath.row != 0 {
            cell.topDividerHeight.constant = 0
        } else {
            cell.topDividerHeight.constant = 0.5
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
}




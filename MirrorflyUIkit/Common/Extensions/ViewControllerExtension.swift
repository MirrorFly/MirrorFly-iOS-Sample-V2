//
//  ViewControllerExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 19/08/21.
//

import Foundation
import UIKit
import MirrorFlySDK

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setUpStatusBar() {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            let statusBarFrame = window?.windowScene?.statusBarManager?.statusBarFrame
            let statusBarView = UIView(frame: statusBarFrame!)
            self.view.addSubview(statusBarView)
            statusBarView.backgroundColor = Color.navigationColor
        } else {
            let statusBarFrame = UIApplication.shared.statusBarFrame
            let statusBarView = UIView(frame: statusBarFrame)
            self.view.addSubview(statusBarView)
            statusBarView.backgroundColor = Color.navigationColor
        }
    }
    
    func handleBackgroundAndForground() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(didMoveToBackground), name: UIScene.willDeactivateNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willCometoForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didMoveToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willCometoForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }

    
    @objc func didMoveToBackground() {
        print("UIViewController moved to background")
        
    }
    
    @objc func willCometoForeground() {
        print("UIViewController appComestoForeground")
    }
    
    func exitApp() {
        executeOnMainThread {
            exit(0)
        }
    }
    
    func lightUpAndFadeOut(button: UIButton){
        UIView.animate(withDuration: 1) {
            button.backgroundColor = UIColor.gray
        }
        UIView.animate(withDuration: 1) {
            button.alpha = 0
        }
        UIView.animate(withDuration: 0.5) {
            button.alpha = 1
            button.backgroundColor = UIColor.clear
        }
        
    }
    func addButtonRipple(button: UIButton) {
        let colorAnimation = CABasicAnimation(keyPath: "backgroundColor")
        colorAnimation.fromValue = UIColor.lightGray.cgColor
        colorAnimation.duration = 0.5  // animation duration
        button.layer.add(colorAnimation, forKey: "ColorPulse")
    }
}

// For admin blocking and unblocking
extension UIViewController {
    func removeAdminBlockedContact(profileList : [ProfileDetails], jid : String, isBlockedByAdmin : Bool) -> [ProfileDetails]{
        var tempProfileList = profileList
        if tempProfileList.isEmpty {
            return tempProfileList
        }
        
        tempProfileList.filter({$0.jid == jid}).first?.isBlockedByAdmin = isBlockedByAdmin
        tempProfileList = tempProfileList.filter({!$0.isBlockedByAdmin}).sorted { getUserName(jid: $0.jid, name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName, contactType: $1.contactType).capitalized }
        
        return tempProfileList
    }
    
    func addUnBlockedContact(profileList:  [ProfileDetails], jid: String, isBlockedByAdmin : Bool) -> [ProfileDetails]{
        var tempProfileList = profileList
        if tempProfileList.isEmpty {
            return tempProfileList
        }
        
        if let _ = tempProfileList.filter({$0.jid == jid}).first {
            return tempProfileList
        }
        
        if let profile = ChatManager.profileDetaisFor(jid: jid) {
            tempProfileList.append(profile)
        }
        
        tempProfileList = tempProfileList.sorted { getUserName(jid: $0.jid, name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName, contactType: $1.contactType).capitalized }
        
        return tempProfileList
    }
    
    func checkAndAddRecentChat(recentChatList : [RecentChat], jid : String, isBlockedByAdmin : Bool) -> [RecentChat] {
        var tempRecent = recentChatList
        if tempRecent.isEmpty {
            return tempRecent
        }
        
        if let _ = tempRecent.filter({$0.jid == jid}).first {
            return tempRecent
        }
        
        if let recent = ChatManager.getRechtChat(jid: jid) {
            tempRecent.append(recent)
        }
        
        return tempRecent
    }
    
    func removeAdminBlockedRecentChat(recentChatList : [RecentChat], jid : String, isBlockedByAdmin : Bool) -> [RecentChat] {
        var tempRecent = recentChatList
        if tempRecent.isEmpty {
            return tempRecent
        }
        
        tempRecent.filter({$0.jid == jid}).first?.isBlockedByAdmin = isBlockedByAdmin
        tempRecent = tempRecent.filter({!$0.isBlockedByAdmin})
        
        return tempRecent
    }
}

// For reporting
extension UIViewController {
    
    func showConfirmDialogToReport(profileDetail : ProfileDetails?, isFromMessage : Bool = false, completionHandler : @escaping (_ didTapReport : Bool) -> Void) {
        guard let profileDetail = profileDetail else {
            return
        }
        let title = report + " " + getUserName(jid: profileDetail.jid, name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType) + "?"
        let message = isFromMessage ? reportMessage : (profileDetail.profileChatType == .groupChat ? reportGroupMessage : reportLastFiveMessage)
        AppAlert.shared.showAlert(view: self, title: title, message: message, buttonOneTitle: cancelUppercase, buttonTwoTitle: report)
        AppAlert.shared.onAlertAction = { result in
            if result == 1 {
                if NetworkReachability.shared.isConnected {
                    completionHandler(true)
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }
        }
    }
    
    func showReportingGroupOptions( completionHandler : @escaping (_ reportAction : String) -> Void){
        let values : [String] = ChatActions.allCases.map { $0.rawValue }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        
        AppActionSheet.shared.showActionSeet(title: reportThisGroup, message: reportGroupMessage, actions: actions, titleBold: true) { didCancelTap, tappedOption in
            if !didCancelTap {
                completionHandler(tappedOption)
            }
        }
    }
    
    func showReportSuccessDialog() {
        AppAlert.shared.showAlert(view: self, title: reportSend, message: "", buttonTitle: okButton)
    }
    
    func reportForJid(profileDetails : ProfileDetails, isFromGroupInfo : Bool = false) {
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        
        if isFromGroupInfo {
            startLoading(withText: pleaseWait)
            reportUserOrGroup(jid: profileDetails.jid)
            return
        }
        
        showConfirmDialogToReport(profileDetail: profileDetails) { [weak self] didTapReport in
            if didTapReport {
                self?.startLoading(withText: pleaseWait)
                self?.reportUserOrGroup(jid: profileDetails.jid)
            }
        }
    }
    
    private func reportUserOrGroup(jid : String) {
        ChatUtils.reportFor(chatUserJid: jid) { [weak self] isSuccess, error, data in
            if isSuccess{
                self?.stopLoader(isSuccess: isSuccess)
            }else{
                self?.stopLoading()
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? reportFailure)
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
        }
    }
    
    public func reportAndExitFromGroup(jid : String, completionHandler : @escaping (_ isReported : Bool) -> Void) {
        startLoading(withText: pleaseWait)
        ChatUtils.reportFor(chatUserJid: jid) { [weak self] isSuccess, error, data in
            self?.stopLoading()
            completionHandler(isSuccess)
            if !isSuccess {
                //AppAlert.shared.showToast(message: reportFailure)
                
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? reportFailure)
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
        }
    }
    
    func reportFromMessage(chatMessage : ChatMessage, profileDetail: ProfileDetails? = nil) {
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        
        showConfirmDialogToReport(profileDetail: profileDetail, isFromMessage: true) { [weak self] didTapReport in
            if didTapReport {
                self?.startLoading(withText: pleaseWait)
                ChatUtils.reportFrom(message: chatMessage) { [weak self]  isSuccess, error, data in
                    
                    if isSuccess{
                        self?.stopLoader(isSuccess: isSuccess)
                    }else{
                        self?.stopLoading()
                        let message = AppUtils.shared.getErrorMessage(description: error?.description ?? reportFailure)
                        AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                        return
                    }
                }
            }
        }
    }
    
    private func stopLoader(isSuccess : Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.stopLoading()
            if isSuccess {
                self?.showReportSuccessDialog()
            } else {
                AppAlert.shared.showToast(message: pleaseTryAgain)
            }
        }
    }
}

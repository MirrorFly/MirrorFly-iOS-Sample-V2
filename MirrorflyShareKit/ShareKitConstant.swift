//
//  ShareKitConstant.swift
//  MirrorflyUIkit
//
//  Created by John on 17/02/23.
//

import Foundation

let TAG = "ShareKit"

let pleaseLogIn = "Please Log In"
let needToLogIntoMirrorFly = "You need to log into MirrorFly app to continue"
let ok = "Ok"
let chatTextMinimumLines = 0
let chatTextMaximumLines = 5

let passwordResetTimer = 60
let addCaption = NSLocalizedString("addCaption", comment: "")

//MARK:- Font Names
let fontHeavy = "SFUIDisplay-Heavy"
let fontBold = "SFUIDisplay-Bold"
let fontRegular = "SFUIDisplay-Regular"
let fontLight = "SFUIDisplay-Light"
let fontMedium = "SFUIDisplay-Medium"
let fontSemibold = "SFUIDisplay-Semibold"

let cancelUppercase = "Cancel"
let processingVideo = "Processsing Video..."

//MARK: - Identifiers
enum Identifiers {
    //MARK: - APPLOCKPIN
    static let appLockTableViewCell = "AppLockTableViewCell"
    static let authenticationPINViewController = "AuthenticationPINViewController"
    static let appLockPasswordViewController = "AppLockPasswordViewController"
    static let changeAppLockViewController = "ChangeAppLockViewController"
    static let pinEnteredCollectionViewCell = "PINenteredCollectionViewCell"
    static let authenticationPINCollectionViewCell = "AuthenticationPINCollectionViewCell"
    static let AppLockDescriptionCell = "AppLockDescriptionCell"
    static let participantCell = "ShareKitParticipantCell"
    static let ncProfileUpdate =  "ncProfileUpdate"
    static let editImageCell = "EditImageCell"
    static let listImageCell = "ListImageCell"
    static let imageCell = "ImageCell"
    static let warningCell = "WarningCell"
}


// Error messages
public struct SuccessMessage {
    
    public static let successAuth = NSLocalizedString("successAuth", comment: "")
    public static let successOTP = NSLocalizedString("successOTP", comment: "")
    public static let PINsetsuccessfully = NSLocalizedString("PIN set successfully", comment: "")
}

// Error messages
public struct ErrorMessage {
    
    public static let otpAttempts = NSLocalizedString("otpAttempts", comment: "")
    public static let noInternet = NSLocalizedString("noInternet", comment: "")
    public static let shortMobileNumber = NSLocalizedString("shortMobileNumber", comment: "")
    public static let validphoneNumber = NSLocalizedString("validphoneNumber", comment: "")
    public static let invalidOtp = NSLocalizedString("invalidOtp", comment: "")
    public static let otpMismatch = NSLocalizedString("otpMismatch", comment: "")
    public static let enterOtp = NSLocalizedString("enterOtp", comment: "")
    public static let enterMobileNumber = NSLocalizedString("enterMobileNumber", comment: "")
    public static let restrictedMoreImages = NSLocalizedString("Can't share more than 10 media items", comment: "")
    public static let restrictedforwardUsers = NSLocalizedString("You can only forward with up to 5 users or groups", comment: "")
    public static let restrictedShareUsers = NSLocalizedString("You can only share with up to 5 users or groups", comment: "")
    public static let checkYourInternet = NSLocalizedString("Please check your internet connection", comment: "")
    public static let fileSizeLarge = NSLocalizedString("File size is too large", comment: "")
    public static let largeImageFile = NSLocalizedString("File size is too large. Try uploading file size below 10MB", comment: "")
    public static let largeVideoFile = NSLocalizedString("File size is too large. Try uploading file size below 30MB", comment: "")
    public static let numberDoesntMatch =  NSLocalizedString("mobileNumberDoesntMatch", comment: "")
    public static let invalidPIN = NSLocalizedString("Invalid PIN! Try again", comment: "")
    public static let invalidOLDPIN = NSLocalizedString("Invalid old PIN", comment: "")
    public static let enternewPIN = NSLocalizedString("Enter the New PIN", comment: "")
    public static let enterconfirmPIN = NSLocalizedString("Enter the Confirm PIN", comment: "")
    public static let enterValidPIN = NSLocalizedString("PIN must be of 4 digits", comment: "")
    public static let enterthePIN = NSLocalizedString("Enter the PIN", comment: "")
    public static let passwordShouldbeSame = NSLocalizedString(" PIN and Confirm PIN must be same", comment: "")
    public static let oldPINnewPINsholdnotSame = NSLocalizedString("Old PIN and new PIN should not be same", comment: "")
    public static let validateAppLock = NSLocalizedString("Invalid PIN! Try again", comment: "")
    public static let fingerPrintIsNotRegisteredinDevice = NSLocalizedString("Fingerprint is not registered in device", comment: "")
    public static let pleaseEnablefingerPrintonYourdevice = NSLocalizedString("Please enable fingerprint on your device", comment: "")
    public static let sessionExpired = NSLocalizedString("sessionExpired", comment: "")
    
    
}

let retry = NSLocalizedString("retry", comment: "")
let pleaseWait = NSLocalizedString("pleaseWait", comment: "")
let resendOtpTxt = NSLocalizedString("resendOtp", comment: "")
let okButton = NSLocalizedString("Ok", comment: "")
let okayButton = NSLocalizedString("okay", comment: "")
let yesButton = NSLocalizedString("yes", comment: "")
let noButton = NSLocalizedString("no", comment: "")
let warning = NSLocalizedString("warning", comment: "")

let isProfileSaved = "isProfileSaved"
let googleToken = "googleToken"
let voipToken = "voipToken"
let isLoggedIn = "isLoggedIn"
let youCantSelectTheGroup = "You're no longer a participant in this group"
let groupNoLongerAvailable = "This group is no longer available"
let senderDeletedMessage = "You deleted this message"
let receiverDeletedMessage = "This message was deleted"
let contactSelect = "1"
let contactUnselect = "0"
let emptyContact = "Please select atleast one contact"
let noContactNumberAlert = "Selected contact doesn't have any mobile number"

let unSupportedFileFormate = "You can upload only .pdf, .xls, .xlsx, .doc, .docx, .txt, .ppt, .zip, .rar, .pptx, .csv files"
let unsupportedFile = "Unsupported file format"

enum ImageConstant {
    static let remove_PIN = "remove_PIN"
    static let otppinDatk = "otppinDatk"
    static let otpPin = "otpPin"
    static let hide_Password = "hide_Password"
    static let showeye_password = "showeye_password"
    static let ic_check_box = "ic_uncheckbox"
    static let ic_checked = "ic_checkbox"
    static let ic_profile_placeholder = "ic_profile_placeholder"
    static let ic_group_small_placeholder = "smallGroupPlaceHolder"
    static let ic_rcaudio = "audio"
    static let ic_rcvideo = "video"
    static let ic_rclocation = "location"
    static let ic_rccontact = "contact"
    static let ic_rcimage = "imageGallery"
    static let ic_rcdocument = "document"
    static let ic_audio_filled = "ic_audio_filled"
    static let ic_sent = "ic_sent"
    static let ic_seen = "ic_seen"
    static let ic_hour = "ic_hour"
    static let ic_delivered = "ic_delivered"
}

public struct FlyConstants {
    static let messageTypeText = "text"
    
    static let messageTypeImage = "image"
    
    static let messageTypeVideo = "video"
    
    static let messageTypeAudio = "audio"
    
    static let messageTypeLocation = "location"
    
    static let messageTypeContact = "contact"
    
    static let messageTypeDocument = "file"
    
    static let messageTypeNotification = "notification"

    static let data = "data"
}

/// Defines the type of chat messages as enum
public enum MessageType : String, CustomStringConvertible {
    
    case text = "text"
    
    case image = "image"
    
    case video = "video"
    
    case audio = "audio"
    
    case location = "location"
    
    case document = "file"
    
    case contact = "contact"
    
    case notification = "notification"
    
    public var description: String {
        
        switch self {
        case .text:
            return FlyConstants.messageTypeText
        case .image:
            return FlyConstants.messageTypeImage
        case .video:
            return FlyConstants.messageTypeVideo
        case .audio:
            return FlyConstants.messageTypeAudio
        case .location:
            return FlyConstants.messageTypeLocation
        case .document:
            return FlyConstants.messageTypeDocument
        case .contact:
            return FlyConstants.messageTypeContact
        case .notification:
            return FlyConstants.messageTypeNotification
        }
    }
    
}

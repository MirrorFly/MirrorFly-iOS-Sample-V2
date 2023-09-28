//
//  Constants.swift
//  MirrorFly
//
//  Created by User on 18/05/21.
//

import Foundation

//MARK:- Font Names
let fontHeavy = "SFUIDisplay-Heavy"
let fontBold = "SFUIDisplay-Bold"
let fontRegular = "SFUIDisplay-Regular"
let fontLight = "SFUIDisplay-Light"
let fontMedium = "SFUIDisplay-Medium"
let fontSemibold = "SFUIDisplay-Semibold"

//MARK: - Language Selection
let english = "English"
let arabic = "Arabic"


//MARK: - Profile
//MARK: - Profile - Field Validation
let userNameMaxLength = 100
let userNameMinLength = 3
let emptyUserName = "Please enter your username"
let userNameValidation = "Maximum of 30 characters"
let userMobileNumber = "Maximum of 17 characters"
let userNameMinValidation = "Username is too short"
let emptyEmail = "Email should not be empty"
let emailValidation = "emailid is not valid"
let updateAndContinue = "Update & Continue"
let save = "Save"
let deleteText = "Delete"
let emoji = "emoji"
let userBlocked = "USER_#_BLOCKED"

//MARK: - Profile Picture
let takePhoto = "Take Photo"
let chooseFromGallery = "Choose from gallery"
let removePhoto = "Remove Photo"
let cancelUppercase = "Cancel"
let error = "Error"
let cameraAccessDenied = "MirrorFlyUIkit does not have access to your camera. To enable access, tap Settings and turn on Camera"
let libraryAccessDenied = "MirrorFlyUIkit does not have access to your Photo Library. To enable access, tap Settings and turn on Photo Library"
let galleryAccessDenied = "MirrorFlyUIkit does not have access to your photos. To enable access, tap Settings and turn on Photos"
let microPhoneAccessDenied = "MirrorFlyUIkit does not have access to your microphone. To enable access, tap Settings and turn on microphone"
let needAccess = "Need Camera Access"
let settings = "Settings"
let allowCamera = "Allow Camera"

//MARK: - Profile Edit Status
let editStatusSectionTitle = "Select your new status"
let editBusyStatusSectionTitle = "Select your busy status"
let meeting = "Meeting"
let atTheMovies = "At the movies"
let urgentCalls = "Urgent Calls Only"
let busy = "I am busy"
let available = "Available"
let sleeping = "Sleeping"
let inMirrorfly = "I am in MirrorFly"
let emptyStatus = "Status cannot be empty"
let busyEmptyStatus = "Busy status cannot be empty"

let iamIn = "I am in"
let statusEmpty = "Status is Empty"
let typeHere = "Type here"
let noCamera = "No Camera"
let noCameraMessage = "Sorry, this device has no camera"

//MARK: - Notification Tone
let chooseAlertTypeforIncomingMessages = "Choose alert type for incoming messages"
let learnMoreInOurHelpCentre = "Learn more in our Help Center"
let playSoundsForIncomingMessages = "Play sounds for incoming messages"
let showingPopUpforIncomingMessages = "Showing popup for incoming messages "
let vibrateWhenANewMessageArrivesWhileApplicationArrives = "Vibrate when a new message arrives while application is running "
let  thisWillMuteAllNotificationsAlertsForIncomingMessages = "This will mute all notification alerts for incoming messages"

//MARK : Toast
//MARK : Profile

//MARK: EmptyTable Handler
let noResultFound = "No results found"
let noNewMessage = "No new Messages"
let noPrivateMessage = "No Private chats"

//MARK: RecentChat HeaderSection Title
let chatTitle = "Chats"
let messageTitle = "Messages"
let contactTitle = "Contact"


let profileUpdateSuccess = "Profile updated successfully"
let groupImageUpdateSuccess = "Group Image updated successfully"
let enterGroupName = "Please enter Group name"
let statusUpdateSuccess = "Status updated successfully"
let jpg = ".jpg"
let jpeg = ".jpeg"
let png = ".png"
let unsupportedFile = "Unsupported file format"

//Chat
let emptyContact = "Please select atleast one contact"
let copyText = "Copy"
let reply = "Reply"
let emptyChatMessage = "Message should not be empty"

let allowLocation = "Allow location from settings"
let copyAlert = "Text copied successfully to the clipboard"

//Chat - Contacts
let noContactNumberAlert = "Selected contact doesn't have any mobile number"
let contactSelect = "1"
let contactUnselect = "0"
let contactDenyAlert = "Read contacts permission is needed for syncing contacts"

//Chat - Reply
let you = "You"

let cancelUpperCase = "CANCEL"
let deleteForMe = "DELETE FOR ME"
let deleteAlert = "Are you sure you want to delete selected Message?"

/// Group Info Alert


let startChat = "Start Chat"
let viewInfo = "View Info"
let removeFromGroup = "Remove from Group"
let makeAdminStatus = "Make admin successfully"
let removeUserStatus = "Removed user successfully"
let adminAccess = "Only admin can perform this action"
let exitGroup = "Exit Group"
let exitGroupMessage = "Are you sure you want to exit from group?"
let exitButton = "Exit"
let leftFromgroup = "You left from group"
let addParticipants = "Add Participants"
let leavegroup = "Leave Group"
let deleteGroup = "Delete Group"
let deleteGroupDescription = "Are you sure want to delete group?"
let makeAdminText = "Make Admin"
let makeAdminDescription = "Are you sure you want make admin?"
let adminText = "Admin"
let removeTitle = "Remove"
let removeDescription = "Are you sure you want remove?"
let deleteGroupMessage = "Group deleted successfully"

//Finger Print Set
let biometricAuthentication = "You need to set pin first in order to enable bio metric authentication"
let pinAuthentication = "You need to enable PIN Lock first in order to enable bio metric authentication"

/// Contact access permission
let contactAccessTitle = "Allow Contact Access"
let contactAccessMessage = "Allow Contact access in your device settings"

let invalidQRMessage = "No valid QR Code detected"

let cancel = NSLocalizedString("cancel", comment: "")
let warning = NSLocalizedString("warning", comment: "")
let alert = NSLocalizedString("alert", comment: "")
let success = NSLocalizedString("success", comment: "")
let camera = NSLocalizedString("camera", comment: "")
let gallery = NSLocalizedString("gallery", comment: "")
let documents = NSLocalizedString("documents", comment: "")
let audio = NSLocalizedString("audio", comment: "")
let location = NSLocalizedString("location", comment: "")
let fileformat_NotSupport = NSLocalizedString("fileformat_NotSupport", comment: "")
let fileSize = NSLocalizedString("fileSize", comment: "")

let okButton = NSLocalizedString("OK", comment: "")
let okayButton = NSLocalizedString("okay", comment: "")
let yesButton = NSLocalizedString("yes", comment: "")
let unblock = NSLocalizedString("Unblock", comment: "")
let noButton = NSLocalizedString("no", comment: "")
let chat = NSLocalizedString("chat", comment: "")
let profile = NSLocalizedString("profile", comment: "")
let call = NSLocalizedString("call", comment: "")
let setting = NSLocalizedString("setting", comment: "")
let loginAlert = NSLocalizedString("loginAlert", comment: "")
let contact = NSLocalizedString("contacts", comment: "")
let search = NSLocalizedString("search", comment: "")
let selectCountry = NSLocalizedString("selectCountry", comment: "")
let sentMedia = NSLocalizedString("sentMedia", comment: "")
let receivedMedia = NSLocalizedString("receivedMedia", comment: "")
let addCaption = NSLocalizedString("addCaption", comment: "")
let placeHolder = NSLocalizedString("Start Typing...", comment: "")
let retry = NSLocalizedString("retry", comment: "")
let pleaseWait = NSLocalizedString("pleaseWait", comment: "")
let resendOtpTxt = NSLocalizedString("resendOtp", comment: "")

let removePhotoAlert = NSLocalizedString("removePhotoAlert", comment: "")
let removeButton = NSLocalizedString("removeButton", comment: "")
let deleteStatusAlert = NSLocalizedString("deleteStatusAlert", comment: "")
let profilePictureRemoved = NSLocalizedString("profilePictureRemoved", comment: "")
let continueButton = NSLocalizedString("Continue", comment: "")

//MARK: -  Url
let mainUrl = Bundle.main.url(forResource: "countries", withExtension: "json")

//Strings
let isLoggedIn = "isLoggedIn"
let isProfileSaved = "isProfileSaved"
let googleToken = "googleToken"
let voipToken = "voipToken"
let password = "password"
let username = "username"
let revokeMediaAccess = "revokeMediaAccess"
let isLoginContactSyncDone = "isLoginContactSyncDone"
let firstTimeSandboxContactSyncDone = "firstTimeSandboxContactSyncDone"
let senderDeletedMessage = "You deleted this message"
let receiverDeletedMessage = "This message was deleted"
let isLocationDenied = "isLocationDenied"

let  enableTranslateMessageToChooseTranslationLanguage = "Enable Translate Message to choose Translation Language"
let chooseTranslationLaguage = "Choose Translation Language"
let doubleTapTheReceivedMessageToTranslate = "Double Tap the received message to translate"
let hidingLastSeenActivityToOtherusers = "Hiding the last seen activity to other users"
let enableAutodownlaodToTurnAllTypes = "Enable \"Auto download\" to turn all types of files received readily viewable"
let dataUsageSettings = "Data Usage Settings"
let setupYourMobileAndWifiDataUsageBasedOnMediaType = "Setup your mobile and wifi data usage based on media type"
let ArchiveSettingsDescription = "Archived chats will remain archived when you receive a new message"

let addMoresecurityWith4DigitsecretPIN = "Add more security with 4 digit secret PIN"
let useFingerPrintIDorFaceID = "Use Fingerprint ID or Face id to unlock your phone"
let changeThe4DigitSecurityPIN = "Change the 4 digit security PIN"
let changePIN = "Change PIN"
let tooManyFailedAttempts = "You have exceeded login attempts"
let settingsNavigateMessage = "Please go to settings and authenticate Touch ID/Face ID & Passcode to open application again"
let openSettingsMessage = "Open settings"

//MARK: - Chat

let chatTimeFormat = "hh:mm a"
let online = "Online"
let lastSeen = "last seen"
let startTyping = "Start Typing..."
let sent = "Sent"
let acknowledged = "Acknowledged"
let delivered = "Delivered"
let seen = "Seen"
let notAcknowledged = "Not Acknowledged"
let typing = "typing..."
let processingVideo = "Processsing Video..."
let waitingForNetwork = "Waiting for Network"
let adminEmail = "mirrorflyadminsupport@gmail.com"
let chatActions = "Chat Actions"
let message = "Message"
let clearChatMessage = "Do you want to clear all Conversation?"
let clearCalllog = "Do you want to clear all call log?"
let clearSelectedCalllog = "Do you want to clear selected call log?"

let clearAllChat = "Are you sure you want to clear your conversation history?"
let unblockTOMakeAudioCall = "Unblock to make an audio call"
let unblockToMakeVideocall = "Unblock to make a video call"
let allYourConversationareCleared = "All your conversation are cleared"
let allYourChatsAreCleared = "All your chats are cleared"
let serverError = "Server error, kindly try again later" 
let clearAll = "Clear All"
let clearExceptStarred = "Clear except starred"
let deleteforMe = "Delete for me"
let deleteforEveryone = "Delete for everyone"
let thereIsNoConversation = "There is no conversation"
let setBusyStatusDescription = "Set busy status as the Auto response to the message recieved from the individuals"
let editBusyStatus = "Edit Busy Status Message"

//MARK: Group
let groupNameRequired = "Please provide group name"
let groupNameCharLimit = 25
let minimumGroupParticipant = 2
let atLeastTwoParticipant = "Add at least two contacts"
let maximumGroupUsers = "250 contacts are allowed"
let groupCreatedSuccess = "Group created successfully"
let groupCreatedFailure = "Group creation failure"
let isText = "is"
let groupNoLongerAvailable = "This group is no longer available"
let messageNoLongerAvailable = "This message is no longer available"
let youCantSendMessagesToThiGroup = "You can't send messages to this group because you're no longer a participant."
let thisUerIsNoLonger = "This user is no longer available"
let youCantSelectTheGroup = "You're no longer a participant in this group"

//MARK: QRCodeScanner
let qrCodeErrorMessage = "Scanning Failed. Please try again"
let errorOccurred = "Error occurred. Please try again"
let scanCode = "Scan Code"
let webSettings = "Web Settings"
let youWantToLogout = "Are you sure you want to logout?"

//MARK: ContactInfo
let email = "Email"
let mobileNumber = "Mobile Number"
let status = "Status"
let unarchiveForPrivateLock = "This chat is Archived. To lock this chat Unarchive it."

// MARK: notification name
let foregroundNotification = "foregroundNotification"

// MARK: rporting user or group or message
let report = "Report"
let reportMessage = "This message will be forwarded to admin. This contact will not be notified."
let reportLastFiveMessage = "The last 5 messages from this contact will be forwarded to admin. This contact will not be notified."
let reportSend = "Report Sent"
let reportGroup = "Report Group"
let reportThisGroup = "Report this group?"
let reportGroupMessage = "The last 5 message from this group will be forwarded to admin. No one in this group will be notified."
let reportAndExit = "Report and exit"
let pleaseTryAgain = "Please try again"
let reportFailure = "Reporting Failure. Please try again"
let noMessgesToReport = "No messges to Report"
let unableToReportDeletedUser = "Cannot report deleted user"
let unableToReportDeletedUserMessage =  "Cannot report deleted user's message"

let didBecomeActive = "didBecomeActive"
let didEnterBackground = "DidEnterBackground"
let recordingReachedMaximumTime = "You can record maximum 300 seconds for audio recording"
let recordingIsTooSmall = "Recorded audio time is too short"
let cannotRecordAudioDuringCall = "Can’t record audio during a phone call"

//MARK: Message Info
let messageSentNotDelivered = "Message Sent, not delivered yet"
let yourMessageIsNotRead = "Your message is not read"


//MARK: View All media
let photos = "Photos"
let videos = "Videos"
let audios = "Audios"
let noMediaFound = "No media found"
let document = "Document"
let doucmentSMedia = "Documents"
let noDocumentFound = "No document found"
let links = "Links"
let link = "link"
let noLinkFound = "No link found"


// MARK: Multiple Selection Title
let deleteTitle = "Delete"
let forwardTitle = "Forward"
let starTitle = "Star"
let shareTitle = "Share"
let unStarTitle = "Unstar"

let cannotShareMoreThan10 = "Cannot share more than 10 files."

//MARK: DeleteMessages
let originalMessageDeleted = "Can't forward because the original message is deleted"



//MARK: Backup Restore Info
let optionsHeader = "Schedule to run backups\nautomatically"
let optionsNetworkHeader = "Schedule to run backups\nover"
let instructionOne = "Open iPhone Settings."
let instructionTwo = "Tap “iCloud” and make sure you’re signed in."
let instructionThree = "Tap “iCloud Drive” and set it to ON."
let instructionFour = "In “iCloud Drive”, make sure “MirrorFly App” is also ON"
let instructionOneImage = "restore_settings"
let instructionTwoImage = "restore_cloud_ic"
let instructionThreeImage = "restore_cloud_ic"
let instructionFourImage = "restore_app"
let iCloudNotAvailable = "iCloud not available"

let backupFound = "Backup Found"
let nobBackupFound = "No Backup Found"
let backupFoundDescription = "Restore your messages and media from iCloud. If you don’t restore now, you wont be able to restore later."
let noBackupFoundDescription = "In order to check and restore messages from iCloud backups, please sign in with your iCloud account."
let restoring = "Restoring"
let backupDownloading = "Backup Downloading..."
let restoreSuccess = "Data Restored Successfully"
let backupSuccess = "Backup downloaded successfully."
let noBackupMessage = "No messages available"
let backupUploadSuccess = "Backup uploaded successfully."
let containerError = "ContainerId invalid or not available"
let iCloudStorageError = "Couldn’t initiate/complete backup because there’s not enough free space on your iCloud storage."

// Error messages
public struct ErrorMessage {
    
    public static let otpAttempts = NSLocalizedString("otpAttempts", comment: "")
    public static let noInternet = NSLocalizedString("noInternet", comment: "")
    public static let shortMobileNumber = NSLocalizedString("shortMobileNumber", comment: "")
    public static let validphoneNumber = NSLocalizedString("validphoneNumber", comment: "")
    public static let invalidOtp = NSLocalizedString("invalidOtp", comment: "")
    public static let otpMismatch = NSLocalizedString("otpMismatch", comment: "")
    public static let noCountriesFound = NSLocalizedString("noCountriesFound", comment: "")
    public static let noContactsFound = NSLocalizedString("noContactsFound", comment: "")
    public static let enterOtp = NSLocalizedString("enterOtp", comment: "")
    public static let enterMobileNumber = NSLocalizedString("enterMobileNumber", comment: "")
    public static let sessionExpired = NSLocalizedString("sessionExpired", comment: "")
    public static let restrictedMoreImages = NSLocalizedString("Can't share more than 10 media items", comment: "")
    public static let restrictedforwardUsers = NSLocalizedString("You can only forward with up to 5 users or groups", comment: "")
    public static let checkYourInternet = NSLocalizedString("Please check your internet connection", comment: "")
    public static let fileSizeLarge = NSLocalizedString("File size is too large", comment: "")
    public static let largeImageFile = NSLocalizedString("File size is too large. Try uploading file size below 10MB", comment: "")
    public static let largeVideoFile = NSLocalizedString("File size is too large. Try uploading file size below 30MB", comment: "")
    public static let numberDoesntMatch =  NSLocalizedString("mobileNumberDoesntMatch", comment: "")
    public static let invalidPIN = NSLocalizedString("Invalid PIN! Try again", comment: "")
    public static let invalidOLDPIN = NSLocalizedString("Invalid old PIN", comment: "")
    public static let enternewPIN = NSLocalizedString("Enter the new PIN", comment: "")
    public static let enterconfirmPIN = NSLocalizedString("Enter the confirm PIN", comment: "")
    public static let enterValidPIN = NSLocalizedString("PIN must be of 4 digits", comment: "")
    public static let enterthePIN = NSLocalizedString("Enter the PIN", comment: "")
    public static let passwordShouldbeSame = NSLocalizedString(" PIN and Confirm PIN must be same", comment: "")
    public static let oldPINnewPINsholdnotSame = NSLocalizedString("Old PIN and new PIN should not be same", comment: "")
    public static let validateAppLock = NSLocalizedString("Invalid PIN! Try again", comment: "")
    public static let fingerPrintIsNotRegisteredinDevice = NSLocalizedString("Fingerprint/Face ID is not registered in device", comment: "")
    public static let pleaseEnablefingerPrintonYourdevice = NSLocalizedString("Please enable fingerprint/faceID on your device", comment: "")
    public static let fileNoLongerExists = NSLocalizedString("File no longer exists", comment: "")

    
}
// Error messages
public struct SuccessMessage {
    
    public static let successAuth = NSLocalizedString("successAuth", comment: "")
    public static let successOTP = NSLocalizedString("successOTP", comment: "")
    public static let PINsetsuccessfully = NSLocalizedString("PIN set successfully", comment: "")
    public static let pinChangedSuccessfully = NSLocalizedString("PIN changed successfully", comment: "")
}

public struct AppRegex {
    public static let urlFormat = "http[s]?://(([^/:.[:space:]]+(.[^/:.[:space:]]+)*)|([0-9](.[0-9]{3})))(:[0-9]+)?((/[^?#[:space:]]+)([^#[:space:]]+)?(#.+)?)?"
}

public let KEY_STRING = "keyString"


public let cameraMediaTypeVideo = "public.movie"
public let cameraMediaTypeImage = "public.image"

enum CreateGroupOptions : String, CaseIterable {
    case createGroup = "Create Group"
   // case broadCastList = "Broadcast List"
    case web = "Web"
}

enum ChatActions : String, CaseIterable {
    case clearAllConversation = "Clear All Conversation"
    case emailChat = "Email Chat"
    case report = "Report"
    case search = "Search"
    case block = "Block"
    case unblock = "Unblock"
}

enum AppLockActions : String, CaseIterable {
    case disablePin = "Disable PIN"
    case changePin = "Change PIN"
    case forgotPin = "Forgot PIN?"
}

enum MessageActions : String, CaseIterable {
    case reply = "Reply"
    case share = "Share"
    case copy = "Copy"
    case forward = "Forward"
    case info = "Info"
    case report = "Report"
    case delete = "Delete"
    case star = "Star"
    case unStar = "Unstar"
}

enum GroupReportActions : String, CaseIterable {
    case reportAndExit = "Report and exit"
    case report = "Report"
}

enum ImagePickingOptions : String, CaseIterable {
    case chooseFromGallery = "Choose from Gallery"
    case takePhoto = "Take Photo"
    case removePhoto = "Remove Photo"
}

public struct TermsAndConditionsUrl {
    public static let aboutUs = "https://www.contus.com/overview.php"
    public static let termsAndConditions = "https://www.mirrorfly.com/terms-and-conditions.php"
    public static let privacyPolicy = "https://www.mirrorfly.com/privacy-policy.php"
}


// MARK: Automation Constants

// MARK: Login Ids

let numTextAM = "Login_Number_TextField"
let otp1TextAM = "Login_OtpOne_TextField"
let otp2TextAM = "Login_OtpTwo_TextField"
let otp3TextAM = "Login_OtpThree_TextField"
let otp4TextAM = "Login_OtpFour_TextField"
let otp5TextAM = "Login_OtpFive_TextField"
let otp6TextAM = "Login_OtpSix_TextField"
let countrySearchAM = "Login_Search_TextField"


let getOtpBtnAM = "Login_GetOtp_Button"
let verifyOtpBtnAM = "Login_VerifyOtp_Button"
let resendOtpBtnAM = "Login_ResendOtp_Button"
let changeNumberBtnAM = "Login_ChangeNumber_Button"
let countryPickerBtnAM = "Login_CountryPicker_Button"

// MARK: Login Strings

let numTextString = "PhoneNumberTextField"
let otp1TextString = "OtpOneTextField"
let otp2TextString = "OtpTwoTextField"
let otp3TextString = "OtpThreeTextField"
let otp4TextString = "OtpFourTextField"
let otp5TextString = "OtpFiveTextField"
let otp6TextString = "OtpSixTextField"

let countrySearchString = "CountrySearchTextField"

let countryPickerString = "CountryPicker"

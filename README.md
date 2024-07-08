# Mirrorfly Sample App

## Overview
Our sample app provides basic UI integrated with latest Mirrorfly SDK where you can customize and build your own app easily.

## Before getting started

This section shows you the prerequisites you need for testing **Mirrorfly Sample App**.

### Requirements
The minimum requirements to run the Sample App:

```groovy
- Xcode 15 or later
- iOS 13.0 or later
- Swift 5.0 or later
```

## Getting started

This section gives you information you need to get started with MirrorFly UIKit for iOS.

**Try the sample app**

Our sample app has all the core features of MirrorFly SDK with an integrated UI. You can download the source code from our GitHub repository to get an idea of what you can build with the actual UI before building your own project.

**Step 1:** Install SDK for iOS

SDK for iOS can be installed through <a href="https://cocoapods.org/" target="_self">CocoaPods</a>

**- CocoaPods**

1. Add `MirrorflySDK` into your `Podfile` in Xcode as below:

```gradle
platform :ios, '13.0'
use_frameworks!

target YOUR_PROJECT_TARGET do
    pod 'MirrorflySDK'
end
   ```

2. Add the below given pod hook code block at the end of the pod file and thus, finally install the pods.

```gradle
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end

```

3. Install the `MirrorflySDK` framework through `CocoaPods`.
   
```gradle
$ pod install
```
4. Update the `MirrorflySDK` framework through `CocoaPods`.
   
```gradle
$ pod update
```

**Step 2:** Get `GoogleSerive-Info Plist` API Key and Adding to your `MirrorFlyUIKit-Info Plist`
```gradle
<key>googleApiKey</key>
<string>****************</string>
<key>googleApiKeyStaticMap</key>
<string>****************</string>
<key>googleApiKey_Translation</key>
<string>****************</string>
```

**Step 3:** To log in and run the app, you need to add the LICENCSE key in the app. To generate the license key, you need to sign up in the <a href="https://console.mirrorfly.com/" target="_self">MirrorFly console</a> , and you can get it from there.

**Step 4:** Initialize with License Key.

You can copy the license key from the Overview section in the Console dashboard and paste it in the Appdelegate like below.
   ```gradle
let LICENSE_KEY = "xxxxxxxxxxxxxxxxxxxxxx" //"YOUR_LICENSE_KEY"
   ```

## Initialize ChatSDK

Add the following import statement below before accessing SDK anywhere in your project.

```gradle
import MirrorFlySDK
```
In `Appdelegate` didFinishLaunchingWithOptions function add SDK initialize method with valid Licensekey

```gradle
 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ChatManager.initializeSDK(licenseKey: LICENSE_KEY) { isSuccess, error, data in

    }
 }
```

In `NotificationService` didReceive function add SDK initialize method with valid Licensekey

```gradle
override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    ChatManager.initializeSDK(licenseKey: LICENSE_KEY) { isSuccess, error, data in

    }
}
```
In `ShareKitViewModel` initialize function add SDK initialize method with valid Licensekey

```gradle
 func initialize() {
    ChatManager.initializeSDK(licenseKey: LICENSE_KEY) { isSuccess, error, data in

    }
}
```

Feel free to proceed with running the app once you've gone through all the provided information. Please check our official docs <a href="https://www.mirrorfly.com/docs/" target="_self">MirrorFly Docs</a> to know more about MirrorFlySDK.


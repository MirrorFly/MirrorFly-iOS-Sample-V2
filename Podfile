platform :ios, '13.0'

workspace 'MirrorflyUIkit.xcworkspace'

use_frameworks!

def uikit_pods

  pod 'PhoneNumberKit', :git => 'https://github.com/marmelroy/PhoneNumberKit.git', :commit => '6edd6e38a30aec087cb97f7377edf876c29a427e'
  pod 'IQKeyboardManagerSwift','7.0.3'
  pod 'Firebase/Auth','10.23.0'
  pod 'Firebase/Crashlytics','10.23.0'
  pod 'Firebase/Analytics','10.23.0'
  pod 'Firebase/Messaging','10.23.0'
  pod 'SDWebImage'
  pod 'GrowingTextViewHandler-Swift', '1.2'
  pod "BSImagePicker", "~> 3.1"
  pod 'GoogleMaps'
  pod 'Tatsi'
  pod 'QCropper'
  pod 'KMPlaceholderTextView', '~> 1.4.0'
  pod 'NicoProgress'
  pod 'Firebase/RemoteConfig','10.23.0'
  pod 'Floaty', '~> 4.2.0'
  pod "PulsingHalo"
  pod 'MenuItemKit', '~> 4.0.0'
  pod 'MarqueeLabel'
  pod 'RxSwift', '6.7.1'
  pod 'RxCocoa', '6.7.1'
  pod 'SwiftLinkPreview'
  pod 'lottie-ios', '4.4.3'
  pod 'BottomSheet', :git => 'https://github.com/joomcode/BottomSheet'
  
  #submodule dependency pods

  pod 'Alamofire', '5.9.1'
  pod 'XMPPFramework/Swift'
  pod 'libPhoneNumber-iOS', '0.9.15'
  pod 'RealmSwift', '~> 10.49.2'
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift', '16.0.1'
  pod 'Starscream', '4.0.4'
  pod 'GoogleWebRTC'
  pod 'IDZSwiftCommonCrypto', '~> 0.16'
  
  pod 'MirrorFlySDK', '5.18.4'

end

def notification_pods

  #submodule dependency pods


  pod 'Alamofire', '5.9.1'
  pod 'XMPPFramework/Swift'
  pod 'libPhoneNumber-iOS', '0.9.15'
  pod 'RealmSwift', '~> 10.49.2'
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift', '16.0.1'
  pod 'Starscream', '4.0.4'
  pod 'GoogleWebRTC'
  pod 'IDZSwiftCommonCrypto', '~> 0.16'
  
  pod 'MirrorFlySDK', '5.18.4'

end

target 'UiKitQa' do
  uikit_pods
end

target 'UiKitQaNotificationExtention' do
  notification_pods
end

target 'Mirrorfly' do
  uikit_pods
end

target 'MirrorflyNotificationExtention' do
  notification_pods
end

target 'UikitQaShareKit' do
  uikit_pods
end

target 'MirrorflyShareKit' do
  uikit_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      shell_script_path = "Pods/Target Support Files/#{target.name}/#{target.name}-frameworks.sh"
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
      if File::exist?(shell_script_path)
        shell_script_input_lines = File.readlines(shell_script_path)
        shell_script_output_lines = shell_script_input_lines.map { |line| line.sub("source=\"$(readlink \"${source}\")\"", "source=\"$(readlink -f \"${source}\")\"") }
        File.open(shell_script_path, 'w') do |f|
          shell_script_output_lines.each do |line|
            f.write line
          end
        end
      end
    end
  end
end

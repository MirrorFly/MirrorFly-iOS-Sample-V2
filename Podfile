platform :ios, '12.1'

workspace 'MirrorflyUIkit.xcworkspace'

use_frameworks!

def uikit_pods

  pod 'PhoneNumberKit', :git => 'https://github.com/marmelroy/PhoneNumberKit.git', :commit => '6edd6e38a30aec087cb97f7377edf876c29a427e'
  pod 'IQKeyboardManagerSwift'
  pod 'Firebase/Auth'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'
  pod 'SDWebImage'
  pod 'GrowingTextViewHandler-Swift', '1.2'
  pod "BSImagePicker", "~> 3.1"
  pod 'GoogleMaps'
  pod 'Tatsi'
  pod 'QCropper'
  pod 'KMPlaceholderTextView', '~> 1.4.0'
  pod 'NicoProgress'
  pod 'Firebase/RemoteConfig'
  pod 'Floaty', '~> 4.2.0'
  pod "PulsingHalo"
  pod 'MenuItemKit', '~> 4.0.0'
  pod 'MarqueeLabel'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'SwiftLinkPreview'
  
  #submodule dependency pods
  
  pod 'MirrorFlySDK', '5.9.1'

end

def notification_pods

  #submodule dependency pods

  pod 'MirrorFlySDK', '5.9.1'
  
end

target 'UiKitQa' do
  uikit_pods
end

target 'UiKitQaNotificationExtention' do
  notification_pods
end

target 'UikitQaShareKit' do
    uikit_pods
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.1'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      shell_script_path = "Pods/Target Support Files/#{target.name}/#{target.name}-frameworks.sh"
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

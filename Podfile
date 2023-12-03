# Uncomment the next line to define a global platform for your project
# platform :ios, '14.0'

# Note; name needs to be all lower-case.
def shared_pods
    pod 'Firebase/Auth'
    pod 'Firebase/Messaging'
    pod 'CCHDarwinNotificationCenter'
end

target 'hamuwemu' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for hamuwemu
  shared_pods
  # pod 'FirebaseUI/Auth'
  # pod 'FirebaseUI/Phone'
  # pod 'Firebase/Firestore'
  pod 'Firebase/Database'
  pod ‘Firebase/AnalyticsWithoutAdIdSupport’

  # Optionally, include the Swift extensions if you're using Swift.
#  pod 'FirebaseFirestoreSwift', '~> 8.0-beta'
  # Swift 5.3
  pod 'MessageKit'
  
  target 'Payload Modification' do
    shared_pods
  end

end

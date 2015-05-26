Pod::Spec.new do |s|
  s.name             = "RespokeSDK"
  s.version          = "0.0.9"
  s.summary          = "Add live voice, video, text and data features to your mobile app."
  s.homepage         = "https://www.respoke.io"
  s.license          = 'MIT'
  s.author           = {
    "Respoke" => "info@respoke.io"
  }
  s.source           = {
    :git => "https://github.com/respoke/respoke-sdk-ios.git",
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '7.0'
  s.requires_arc = true
  s.source_files = 'RespokeSDK/**/*.{h,m}'

  s.dependency 'RespokeSocket.IO', '~> 0.5.3'
  s.dependency 'libjingle_peerconnection', '9208.0.0'
end

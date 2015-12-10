Pod::Spec.new do |s|
  s.name             = "RespokeSDK"
  s.version          = "1.2.3"
  s.summary          = "Add live voice, video, text and data features to your mobile app."
  s.homepage         = "https://www.respoke.io"
  s.license          = 'MIT'
  s.author           = {
    "Respoke" => "info@respoke.io"
  }
  s.source           = {
    :git => "https://github.com/respoke/respoke-sdk-ios.git",
    :tag => "v#{s.version}"
  }

  s.ios.deployment_target = '7.0'
  s.requires_arc = true
  s.source_files = 'RespokeSDK/**/*.{h,m}'

  s.dependency 'RespokeSocket.IO', '~> 0.5.3'
  s.dependency 'libjingle_peerconnection', '10842.2.0'
end

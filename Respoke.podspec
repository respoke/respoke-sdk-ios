Pod::Spec.new do |s|
  s.name             = "Respoke"
  s.version          = "0.0.9"
  s.summary          = "Respoke goodness."
  s.homepage         = "https://stash.digium.com/stash/scm/scl/respoke-sdk-ios"
  s.license          = 'MIT'
  s.author           = {
    "Respoke" => "info@respoke.io"
  }
  s.source           = {
    :git => "https://stash.digium.com/stash/scm/scl/respoke-sdk-ios.git",
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '7.0'
  s.requires_arc = true
  s.source_files = 'RespokeSDK/**/*.{h,m}'

  s.dependency 'RespokeSocket.IO', '~> 0.5.3'
  s.dependency 'libjingle_peerconnection'
end

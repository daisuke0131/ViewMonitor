Pod::Spec.new do |s|
  s.name             = "ViewMonitor"
  s.version          = "1.0.4"
  s.summary          = "view detail monitor"
  s.description      = <<-DESC
                       You can measure view detail.
                       DESC
  s.homepage         = "https://github.com/daisuke0131/ViewMonitor"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Daisuke Yamashita" => "dai.tachikoma@gmail.com" }
  s.source           = { :git => "https://github.com/daisuke0131/ViewMonitor.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/daisuke0131'
  s.source_files = 'Source/**/*.swift'
  s.resources    = 'Source/**/*.png'
  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.requires_arc = true
end
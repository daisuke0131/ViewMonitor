Pod::Spec.new do |s|
  s.name             = "ViewMonitor"
  s.version          = "2.4.0"
  s.summary          = "view detail monitor"
  s.description      = <<-DESC
                       You can measure view detail.
                       DESC
  s.homepage         = "https://github.com/daisuke0131/ViewMonitor"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Daisuke Yamashita" => "dai.tachikoma@gmail.com" }
  s.source           = { :git => "https://github.com/daisuke0131/ViewMonitor.git", :tag => s.version.to_s }

  s.source_files     = 'Sources/ViewMonitor/**/*.swift'
  s.resource_bundles = { 'ViewMonitor' => ['Sources/ViewMonitor/Resources/*.png'] }

  s.swift_versions   = ['6.0']
  s.platform         = :ios
  s.ios.deployment_target = "15.0"
end

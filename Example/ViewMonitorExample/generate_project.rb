#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates ViewMonitorExample.xcodeproj so the project can be recreated
# without going through the Xcode GUI.
#
#   bundle exec ruby Example/ViewMonitorExample/generate_project.rb
#
# The generated project is committed. To change a project setting, edit this
# script and re-run it rather than editing the project in Xcode.

require 'xcodeproj'
require 'fileutils'

ROOT        = File.expand_path('../..', __dir__)
EXAMPLE_DIR = File.join(ROOT, 'Example', 'ViewMonitorExample')
APP_DIR     = File.join(EXAMPLE_DIR, 'ViewMonitorExample')
PROJECT_PATH = File.join(EXAMPLE_DIR, 'ViewMonitorExample.xcodeproj')
TARGET_NAME = 'ViewMonitorExample'
BUNDLE_ID   = 'daisuke.ViewMonitorExample'
DEPLOYMENT_TARGET = '15.0'
XCCONFIG_NAME = 'Signing.xcconfig'

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  config.build_settings['SWIFT_VERSION'] = '6.0'
end

target = project.new_target(:application, TARGET_NAME, :ios, DEPLOYMENT_TARGET)

# `new_target` links Foundation.framework by default, but its file reference
# hardcodes the version of the installed SDK into the path (e.g.
# iPhoneOS26.0.sdk, sourceTree = DEVELOPER_DIR). The link is unnecessary
# (Swift/UIKit apps link Foundation automatically) and it bakes the generating
# machine's SDK version into the pbxproj, so regenerating elsewhere produces a
# spurious diff. Drop it from the build phase and also remove the file
# reference and its parent group (Frameworks/iOS) from the project entirely.
target.frameworks_build_phase.clear
if (ios_frameworks_group = project.frameworks_group['iOS'])
  ios_frameworks_group.children.each(&:remove_from_project)
  ios_frameworks_group.remove_from_project
end

group = project.new_group(TARGET_NAME, 'ViewMonitorExample')

sources = %w[AppDelegate.swift SceneDelegate.swift ViewController.swift]
sources.each do |name|
  file = group.new_reference(File.join(APP_DIR, name))
  target.add_file_references([file])
end

resources = [
  'Base.lproj/Main.storyboard',
  'Base.lproj/LaunchScreen.xib',
  'Images.xcassets'
]
resources.each do |name|
  file = group.new_reference(File.join(APP_DIR, name))
  target.add_resources([file])
end

# Reference the root Package.swift locally and link ViewMonitor from it.
package_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package_ref.relative_path = '../..'
project.root_object.package_references << package_ref

product_ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_ref.product_name = 'ViewMonitor'
target.package_product_dependencies << product_ref

# DEVELOPMENT_TEAM differs per developer, so it is not baked into the pbxproj.
# It comes from a git-ignored Local.xcconfig instead; see Signing.xcconfig.
xcconfig_ref = project.main_group.new_reference(File.join(EXAMPLE_DIR, XCCONFIG_NAME))

target.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig_ref

  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  settings['SWIFT_VERSION'] = '6.0'
  settings['INFOPLIST_FILE'] = 'ViewMonitorExample/Info.plist'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  # Don't require signing for the simulator: CI has neither a signing
  # certificate nor a DEVELOPMENT_TEAM, so the example build job fails without
  # this. Devices (iphoneos) can't install an unsigned build, so the setting is
  # conditioned on the SDK and device builds sign as usual.
  settings['CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]'] = 'NO'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  # Images.xcassets has no AccentColor.colorset, so the gem's default value
  # makes every build warn "Accent color 'AccentColor' is not present in any
  # asset catalogs". We don't intend to define an accent color, so drop the
  # setting altogether.
  settings.delete('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME')
end

project.save

# Create a shared scheme so CI can refer to it with -scheme ViewMonitorExample.
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(PROJECT_PATH, TARGET_NAME, true)

puts "Generated #{PROJECT_PATH}"

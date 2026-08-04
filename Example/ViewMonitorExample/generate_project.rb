#!/usr/bin/env ruby
# frozen_string_literal: true

# ViewMonitorExample.xcodeproj を生成する。
# Xcode の GUI を使わずにプロジェクトを再生成できるようにするためのスクリプト。
#
#   bundle exec ruby Example/ViewMonitorExample/generate_project.rb
#
# 生成物はコミットする。プロジェクト設定を変えたいときはこのスクリプトを編集して再実行する。

require 'xcodeproj'
require 'fileutils'

ROOT        = File.expand_path('../..', __dir__)
EXAMPLE_DIR = File.join(ROOT, 'Example', 'ViewMonitorExample')
APP_DIR     = File.join(EXAMPLE_DIR, 'ViewMonitorExample')
PROJECT_PATH = File.join(EXAMPLE_DIR, 'ViewMonitorExample.xcodeproj')
TARGET_NAME = 'ViewMonitorExample'
BUNDLE_ID   = 'daisuke.ViewMonitorExample'
DEPLOYMENT_TARGET = '15.0'

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  config.build_settings['SWIFT_VERSION'] = '6.0'
end

target = project.new_target(:application, TARGET_NAME, :ios, DEPLOYMENT_TARGET)

# `new_target` は Foundation.framework をデフォルトでリンクするが、
# そのファイル参照はインストール済み SDK のバージョンを直接パスに埋め込む
# (例: iPhoneOS26.0.sdk、sourceTree = DEVELOPER_DIR)。リンクには不要
# （Swift/UIKit アプリは Foundation を自動リンクする）な上、生成のたびに
# 実行環境の SDK バージョンが pbxproj に焼き込まれ、他の環境で再生成すると
# 差分が生まれてしまう。ビルドフェーズから外すだけでなく、ファイル参照と
# その親グループ（Frameworks/iOS）も project から完全に取り除く。
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

# ルートの Package.swift をローカル参照として追加し、ViewMonitor をリンクする。
package_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package_ref.relative_path = '../..'
project.root_object.package_references << package_ref

product_ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_ref.product_name = 'ViewMonitor'
target.package_product_dependencies << product_ref

target.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  settings['SWIFT_VERSION'] = '6.0'
  settings['INFOPLIST_FILE'] = 'ViewMonitorExample/Info.plist'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  settings['CODE_SIGNING_ALLOWED'] = 'NO'
  settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  # Images.xcassets に AccentColor.colorset が無いため、gem のデフォルト値の
  # ままだと「Accent color 'AccentColor' is not present in any asset
  # catalogs」という警告がビルドのたびに出る。アクセントカラーを定義する
  # つもりが無いので設定自体を消す。
  settings.delete('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME')
end

project.save

# CI から -scheme ViewMonitorExample で参照できるよう共有スキームを作る。
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(PROJECT_PATH, TARGET_NAME, true)

puts "Generated #{PROJECT_PATH}"

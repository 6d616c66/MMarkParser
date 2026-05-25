Pod::Spec.new do |s|
  s.name         = "MMarkParser"
  s.version      = "1.0.0"
  s.summary      = "iOS Markdown parser and renderer using TextKit2"
  s.description  = "A Markdown parsing and rendering library for iOS with TextKit2 support, GFM complete syntax"
  s.homepage     = "https://github.com/6d616c66/MMarkParser"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "malf" => "malongfei@immotors.com" }
  s.platform     = :ios, "15.0"
  s.source       = { :git => "https://github.com/6d616c66/MMarkParser.git", :tag => s.version.to_s }
  s.source_files = "MMarkParser/Sources/**/*.{swift,h,m}"
  s.resources = ['MMarkParser/Sources/Resources/MMarkParser.bundle']
  s.swift_version = "5.7"
  s.frameworks   = "UIKit", "QuartzCore"
  s.dependency "md4c/Core"
  s.dependency "iosMath"
  s.dependency "Kingfisher"
end

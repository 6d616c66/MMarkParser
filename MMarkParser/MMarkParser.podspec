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
  s.swift_version = "5.9"
  s.frameworks   = "UIKit", "QuartzCore"

  s.source_files = [
    "MMarkParser.swift",
    "Parser/**/*.{swift,h,m}",
    "Renderer/**/*.{swift,h,m}"
  ]
  s.resources = ['Resources/MMarkParser.bundle']
  
  s.dependency "Splash"
  s.dependency "BeautifulMermaidSwift"
  
  s.dependency "md4c/Core"
  s.dependency "iosMath"
  s.dependency "Kingfisher"
end

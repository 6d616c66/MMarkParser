Pod::Spec.new do |s|
  s.name         = "MMarkParser"
  s.version      = "1.0.0"
  s.summary      = "iOS Markdown parser and renderer using TextKit2"
  s.description  = "A Markdown parsing and rendering library for iOS with TextKit2 support, GFM complete syntax"
  s.homepage     = "https://github.com/example/MMarkParser"
  s.license      = "MIT"
  s.author       = { "Author" => "author@example.com" }
  s.platform     = :ios, "15.0"
  s.source       = { :path => "." }
  s.source_files = "Sources/**/*.{swift,h,m}"
  s.resources = ['Sources/Resources/MMarkParser.bundle']
  s.swift_version = "5.7"
  s.frameworks   = "UIKit", "QuartzCore"
  s.dependency "libcmark_gfm", "~> 0.29.4"
  s.dependency "iosMath"
  s.dependency "Kingfisher"
end

Pod::Spec.new do |s|
  s.name         = "Splash"
  s.version      = "1.0.0"
  s.summary      = "A Swift syntax highlighter"
  s.homepage     = "https://github.com/6d616c66/MMarkParser"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "malf" => "malongfei@immotors.com" }
  s.platform     = :ios, "15.0"
  s.source       = { :git => "https://github.com/6d616c66/MMarkParser.git", :tag => s.version.to_s }
  s.source_files = "**/*.{swift,h,m}"
  s.swift_version = "5.9"
end

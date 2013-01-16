Pod::Spec.new do |s|
  s.name         = "AEHelpers"
  s.version      = "0.0.5"
  s.summary      = "Cocoa helpers."
  s.homepage     = "https://github.com/ap4y/cocoa_helpers"
  s.license      = 'MIT'
  s.author       = { "ap4y" => "lod@pisem.net" }
  s.source       = { :git => "https://github.com/ap4y/cocoa_helpers.git", :tag => "0.0.5" }
  s.platform     = :ios

  s.subspec 'REST' do |rest|
    rest.source_files = 'Categories', 'Client', 'Common'
    rest.dependency 'JSONKit'
    rest.dependency 'AFNetworking'
  end

  s.subspec 'Social' do |soc|
    soc.source_files = 'Social'
    soc.dependency 'Facebook-iOS-SDK'
    soc.dependency 'NSData+Base64'
  end
end

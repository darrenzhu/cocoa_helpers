Pod::Spec.new do |s|
  s.name         = "AEHelpers"
  s.version      = "0.0.4"
  s.summary      = "My useful cocoa helpers."
  s.homepage     = "https://github.com/ap4y/cocoa_helpers"
  s.license      = 'MIT'
  s.author       = { "ap4y" => "lod@pisem.net" }
  s.source       = { :git => "https://github.com/ap4y/cocoa_helpers.git", :tag => "0.0.4" }
  s.platform     = :ios

  s.subspec 'REST' do |rest|
    rest.source_files = 'Categories', 'Client', 'Common'
    rest.dependency 'JSONKit',      '~> 1.4'
    rest.dependency 'AFNetworking', '0.10.0'
  end

  s.subspec 'Social' do |soc|
    soc.source_files = 'Social'
    soc.dependency 'Facebook-iOS-SDK'
    soc.dependency 'NSData+Base64'
  end
end

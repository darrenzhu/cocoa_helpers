Pod::Spec.new do |s|
  s.name         = "AEHelpers"
  s.version      = "0.1.3"
  s.summary      = "Cocoa helpers."
  s.homepage     = "https://github.com/ap4y/cocoa_helpers"
  s.license      = 'MIT'
  s.author       = { "ap4y" => "lod@pisem.net" }
  s.source       = { :git => "https://github.com/ap4y/cocoa_helpers.git", :tag => "0.1.3" }
  s.platform     = :ios, '5.0'

  s.subspec 'REST' do |rest|
    rest.source_files = 'AEHelpers/Categories', 'AEHelpers/Client', 'AEHelpers/Common'
    rest.dependency 'AFNetworking'
  end

  s.subspec 'Social' do |soc|
    soc.source_files = 'AEHelpers/Social'
    soc.dependency 'AFNetworking'
    soc.dependency 'NSData+Base64'
    soc.dependency 'SSKeychain'
  end
end

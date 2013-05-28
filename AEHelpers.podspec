Pod::Spec.new do |s|
  s.name         = "AEHelpers"
  s.version      = "0.2.0"
  s.summary      = "Cocoa helpers."
  s.homepage     = "https://github.com/ap4y/cocoa_helpers"
  s.license      = 'MIT'
  s.author       = { "ap4y" => "lod@pisem.net" }
  s.source       = { :git => "https://github.com/ap4y/cocoa_helpers.git", :tag => "0.2.0" }
  s.platform     = :ios, '5.0'

  s.subspec 'CoreData' do |cd|
    cd.source_files = 'AEHelpers/CoreData'
  end

  s.subspec 'REST' do |rest|
    rest.source_files = 'AEHelpers/Client'
    rest.dependency 'AEHelpers/CoreData'
    rest.dependency 'AFNetworking'
  end

  s.subspec 'UI' do |ui|
    ui.source_files = 'AEHelpers/UI'
  end

  s.subspec 'Social' do |soc|
    soc.source_files = 'AEHelpers/Social'
    soc.dependency 'AFNetworking'
    soc.dependency 'NSData+Base64'
    soc.dependency 'SSKeychain'
  end

  s.subspec 'Tests' do |tests|
    tests.source_files = 'AEHelpers/Tests'
    tests.dependency 'OHHTTPStubs'
    tests.framework    = 'SenTestingKit'
    tests.xcconfig     = { 'FRAMEWORK_SEARCH_PATHS'       => '$(inherited) "$(SDKROOT)/Developer/Library/Frameworks" "$(DEVELOPER_LIBRARY_DIR)/Frameworks"',
                           'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) OCUNIT=1' }
  end
end

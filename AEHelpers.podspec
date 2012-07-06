Pod::Spec.new do |s|
  s.name         = "AEHelpers"
  s.version      = "0.0.1"
  s.summary      = "My useful cocoa helpers."
  s.homepage     = "https://github.com/ap4y/cocoa_helpers"
  s.license      = 'MIT'
  s.author       = { "ap4y" => "lod@pisem.net" }
  s.source       = { :git => "https://github.com/ap4y/cocoa_helpers.git", :tag => "0.0.1" }
  s.platform     = :ios

  s.subspec 'REST' do |rest|
    rest.source_files = 'Categories', 'Client', 'Common'
    rest.dependency 'JSONKit',          '~> 1.4'
    rest.dependency 'AFNetworking',     '~> 0.10.0'
  end

  s.subspec 'Social' do |soc|
    soc.source_files = 'Social'
    soc.dependency 'Facebook-iOS-SDK'
  end

  s.subspec 'Tests' do |tests|
    tests.source_files = 'Tests'
    tests.framework    = 'SenTestingKit'
    tests.xcconfig     = { 'FRAMEWORK_SEARCH_PATHS' => '"$(SDKROOT)/Developer/Library/Frameworks" "$(DEVELOPER_LIBRARY_DIR)/Frameworks"', 'GCC_PREPROCESSOR_DEFINITIONS' => '"$(GCC_PREPROCESSOR_DEFINITIONS) OCUNIT=1"' }
    tests.dependency 'OCMock'
  end
end

Pod::Spec.new do |s|
  s.name         = "AETestHelpers"
  s.version      = "0.1.1"
  s.summary      = "Helper for test OCUINT test cases."
  s.homepage     = "https://github.com/ap4y/cocoa_helpers"
  s.license      = 'MIT'
  s.author       = { "ap4y" => "lod@pisem.net" }
  s.source       = { :git => "https://github.com/ap4y/cocoa_helpers.git", :tag => "0.1.1" }
  s.platform     = :ios
  s.source_files = 'AEHelpers/Tests'
  s.framework    = 'SenTestingKit'
  s.xcconfig     = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(SDKROOT)/Developer/Library/Frameworks" "$(DEVELOPER_LIBRARY_DIR)/Frameworks"',
                     'GCC_PREPROCESSOR_DEFINITIONS' => '$(GCC_PREPROCESSOR_DEFINITIONS) OCUNIT=1' }

  s.dependency 'OHHTTPStubs'
end

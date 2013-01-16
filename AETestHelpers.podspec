Pod::Spec.new do |s|
  s.name         = "AETestHelpers"
  s.version      = "0.0.4"
  s.summary      = "My useful cocoa tests helpers."
  s.homepage     = "https://github.com/ap4y/cocoa_helpers"
  s.license      = 'MIT'
  s.author       = { "ap4y" => "lod@pisem.net" }
  s.source       = { :git => "https://github.com/ap4y/cocoa_helpers.git", :tag => "0.0.4" }
  s.platform     = :ios
  s.source_files = 'Tests'
  s.framework    = 'SenTestingKit'
  s.xcconfig     = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(SDKROOT)/Developer/Library/Frameworks" "$(DEVELOPER_LIBRARY_DIR)/Frameworks"',
                     'GCC_PREPROCESSOR_DEFINITIONS' => '$(GCC_PREPROCESSOR_DEFINITIONS) OCUNIT=1' }
  s.dependency 'OCMock'
end
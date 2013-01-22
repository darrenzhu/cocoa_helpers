guard :ocunit,
      :derived_data     => '/tmp/tests',
      :build_variables  => 'ONLY_ACTIVE_ARCH=NO',
      :test_paths       => ['AEHelpersTests'],
      :workspace        => 'AEHelpers.xcworkspace',
      :scheme           => 'AEHelpersTests',
      :test_bundle      => 'AEHelpersTests' do

  watch(%r{^AEHelpersTests/.+Tests\.m})
  watch(%r{^AEHelpers/Common/(.+)\.[m,h]$}) { |m| "AEHelpersTests/#{m[1]}Tests.m" }
  watch(%r{^AEHelpers/Client/(.+)\.[m,h]$}) { |m| "AEHelpersTests/#{m[1]}Tests.m" }
  watch(%r{^AEHelpers/Categories/(.+)\.[m,h]$}) { |m| "AEHelpersTests/#{m[1]}Tests.m" }
end

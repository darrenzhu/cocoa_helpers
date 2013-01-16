guard :ocunit,
      :derived_data     => '/tmp/tests',
      :build_variables  => 'ONLY_ACTIVE_ARCH=NO',
      :test_paths       => ['AEHelpersTests'],
      :workspace        => 'AEHelpers.xcworkspace',
      :scheme           => 'AEHelpers',
      :test_bundle      => 'AEHelpersTests' do

  watch(%r{^AEHelpersTests/.+Tests\.m})
  watch(%r{^Common/(.+)\.[m,h]$}) { |m| "AEHelpersTests/#{m[1]}Tests.m" }
  watch(%r{^Client/(.+)\.[m,h]$}) { |m| "AEHelpersTests/#{m[1]}Tests.m" }
  watch(%r{^Categories/(.+)\.[m,h]$}) { |m| "AEHelpersTests/#{m[1]}Tests.m" }
end

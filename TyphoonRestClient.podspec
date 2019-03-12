Pod::Spec.new do |s|
  s.name     = 'TyphoonRestClient'
  s.version  = '1.7.2'
  s.license  = 'Apache2.0'
  s.summary  = 'Flexible HTTP client for Objective-C and Swift'
  s.homepage = 'https://github.com/appsquickly/TyphoonRestClient'
  s.author   = { 'Aleksey Garbarev, Jasper Blues & Contributors' => 'aleksey@appsquick.ly' } 
  s.source   = { :git => 'https://github.com/appsquickly/TyphoonRestClient.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.9'
  
  s.source_files = 'TyphoonRestClient/**/*.{h,m}'
  s.requires_arc = true
  
  s.documentation_url = 'http://appsquickly.github.io/TyphoonRestClient/docs/latest/api/'
  
end

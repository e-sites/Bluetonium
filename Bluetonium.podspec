Pod::Spec.new do |s|
  s.name     = 'Bluetonium'
  s.version  = '1.0.0'
  s.license  = { :type => 'MIT' }
  s.summary  = 'Bluetooth library written in Swift. Mapping services and characteristics to models.'
  s.authors  = { 'Dick Verbunt' => 'dick@e-sites.nl', 'Dominggus Salampessy' => 'dominggus@e-sites.nl' }
  s.homepage = 'https://www.e-sites.nl'
  s.source   = { :git => 'https://github.com/e-sites/Bluetonium.git', :tag => "#{s.version}" }
  s.source_files = 'Bluetonium/*.{swift}'
  s.requires_arc = true
  s.osx.deployment_target = '10.10'
  s.ios.deployment_target = '8.0'
end
Pod::Spec.new do |s|
  s.name     = 'Bluetonium'
  s.version  = '2.0.1'
  s.license  = { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'Bluetooth library written in Swift. Mapping services and characteristics to models.'
  s.authors  = { 'Dick Verbunt' => 'dick@e-sites.nl', 'Dominggus Salampessy' => 'dominggus@e-sites.nl', 'Bas van Kuijck' => 'bas@e-sites.nl' }
  s.homepage = 'http://www.e-sites.nl'
  s.source   = { :git => 'https://github.com/e-sites/Bluetonium.git', :tag => "#{s.version}" }
  s.source_files = 'Source/**/*.swift'
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
end

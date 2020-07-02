Pod::Spec.new do |s|
  s.name         = 'Parsicle'
  s.version      = '0.1.0'
  s.summary      = 'A Swift parser combinator framework for iOS'
  s.homepage     = 'https://github.com/tolo/Parsicle'
  s.license      = 'MIT'
  s.authors      = { 'Tobias Löfstrand' => 'tobias@leafnode.se' }
  s.source       = { :git => 'https://github.com/tolo/Parsicle.git', :tag => s.version.to_s }
  s.swift_version = '5.1'
  s.ios.deployment_target = '9.0'
  #s.osx.deployment_target  = '10.10'
  s.tvos.deployment_target = '9.0'
  s.frameworks = 'Foundation'
  s.source_files = 'Sources/**/*.{swift}'
end

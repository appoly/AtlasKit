Pod::Spec.new do |spec|

  spec.name         = "AtlasKit"
  spec.version      = "0.2.0"
  spec.license      = "MIT"
  spec.summary      = "A swift library for quickly integrating a location search in your app."
  spec.homepage     = "https://github.com/appoly/AtlasKit"
  spec.authors = "James Wolfe"
  spec.source = { :git => 'https://github.com/appoly/AtlasKit.git', :tag => spec.version }

  spec.ios.deployment_target = "11.4"
  spec.framework = "Foundation"
  spec.framework = "CoreLocation"
  spec.framework = "MapKit"
  spec.framework = "Contacts"

  spec.swift_versions = ["5.0", "5.1"]
  
  spec.source_files = "Sources/AtlasKit/*.swift"
  

end

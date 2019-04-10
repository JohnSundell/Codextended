Pod::Spec.new do |spec|
    spec.name = "Codextended"
    spec.version = "0.2.0"
    spec.summary = "Extensions giving Swift's Codable API type inference super powers."
    spec.description = "Codextended adds a set of extensions on top of Swift's Codable API to give it type inference super powers."
    spec.homepage = "https://github.com/JohnSundell/Codextended"
    spec.license = { :type => "MIT", :file => "LICENSE" }
    spec.author = { "John Sundell" => "john@sundell.co" }
    spec.source = { :git => "https://github.com/JohnSundell/Codextended.git", :tag => "#{spec.version}" }
    spec.source_files = "Sources/Codextended/*.swift"
    spec.ios.deployment_target = "9.0"
    spec.osx.deployment_target = "10.9"
    spec.watchos.deployment_target = "3.0"
    spec.tvos.deployment_target = "9.0"
end

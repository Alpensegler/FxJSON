 Pod::Spec.new do |s|

  s.name         = "FxJSON"
  s.version      = "0.9.3"
  s.summary      = "FxJSON."

  s.description  = <<-DESC
                   DESC

  s.homepage     = "http://github.com/FrainL/FxJSON"
  s.license      = "MIT"
 
  s.author             = { "FrainL" => "frainl@outlook.com" }

  s.ios.deployment_target = "8.0"
 
  s.source       = { :git => "http://github.com/FrainL/FxJSON.git", :tag => s.version }

  s.source_files  = "FxJSON"

  s.framework  = "Foundation"
  
end

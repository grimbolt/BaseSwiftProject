Pod::Spec.new do |s|

  s.name = "BaseSwiftProject"
  s.version = "1.2.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Base classes for swift project."
  s.homepage = "https://github.com/grimbolt/BaseSwiftProject/"
  s.author = { "Grimbolt" => "topik105@gmail.com" }
  s.source = { :git => 'https://github.com/grimbolt/BaseSwiftProject.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'BaseSwiftProject/Sources/**/*.swift'
  
  s.dependency 'Alamofire', '~> 4.5'
  s.dependency 'AlamofireObjectMapper', '~> 5.0'
  s.dependency 'GzipSwift'
  s.dependency 'SDWebImage', '~> 4.0'
  s.dependency 'SnapKit', '~> 4.0.0'
end

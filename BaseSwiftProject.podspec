Pod::Spec.new do |s|

  s.name = "BaseSwiftProject"
  s.version = "1.1.4"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Base classes for swift project."
  s.homepage = "https://github.com/grimbolt/BaseSwiftProject/"
  s.author = { "Grimbolt" => "topik105@gmail.com" }
  s.source = { :git => 'https://github.com/grimbolt/BaseSwiftProject.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'BaseSwiftProject/Sources/**/*.swift'
  
  s.dependency 'Alamofire', '~> 4.0'
  s.dependency 'AlamofireObjectMapper', '~> 4.0'
  s.dependency 'GzipSwift'
  s.dependency 'SDWebImage', '~> 3.8'
  s.dependency 'SnapKit', '~> 3.2.0'
end

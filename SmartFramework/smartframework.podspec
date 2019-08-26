Pod::Spec.new do |spec|
  spec.name         = 'smartframework'
  spec.version      = '1.0.0'
  spec.license      = { :type => 'BSD' }
  spec.authors      = { 'Li Hejun' => 'lihejun@yy.com' }
  spec.summary      = 'Social services'
  spec.homepage     = 'https://github.com/hejun-lyne'
  spec.source       = { :git => 'https://github.com/hejun-lyne/SmartFramework.git' }

  spec.ios.deployment_target = '9.0'
  spec.static_framework = true
  spec.default_subspec = 'All'

  spec.subspec 'All' do |ss|
    ss.dependency 'smartframework/Core'
    ss.dependency 'smartframework/Event'
    ss.dependency 'smartframework/Route'
  end

  spec.subspec 'Core' do |ss|
    ss.public_header_files = 'SmartFramework/SFContext.h'
    ss.source_files = 'SmartFramework/Core/*.{h,m}'
  end

  spec.subspec 'Event' do |ss|
    ss.public_header_files = 'SmartFramework/Event/SFEvent.h'
    ss.source_files = 'SmartFramework/Event/*.{h,m}'
  end

  spec.subspec 'Route' do |ss|
    ss.public_header_files = 'SmartFramework/Route/SFRouter.h'
    ss.source_files = 'SmartFramework/Route/*.{h,m}'
  end

end

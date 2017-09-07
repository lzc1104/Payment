#
# Be sure to run `pod lib lint Payment.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Payment'
  s.version          = '0.1.0'
  s.summary          = 'Fuck Payment.'
  s.description      = 'Fuck Payment....'

  s.homepage         = 'https://github.com/lzc1104/Payment'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lzc1104' => '527004184@QQ.COM' }
  s.source           = { :git => 'https://github.com/lzc1104/Payment.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Payment/*'
  s.subspec 'Alipay' do |as|
    as.vendored_frameworks = 'Payment/Alipay/*.framework'
    as.source_files = 'Payment/Alipay/*'
    as.public_header_files = 'Payment/Alipay/*.h'
    as.frameworks = 'UIKit' , 'CoreTelephony','SystemConfiguration' , 'QuartzCore' , 'CoreText' , 'CoreGraphics' , 'CFNetwork' , 'CoreMotion'
    as.libraries = 'c++' , 'z'
  end

end

Pod::Spec.new do |s|
  s.name             = 'Fyber_Marketplace_MoPubAdapter'
  s.version          = '7.8.5'
  s.author           = { 'Fyber' => 'publisher.support@fyber.com' }
  s.summary          = 'Fyber Marketplace SDK MoPub Adapter'
  s.description      = <<-DESC
The adapter that makes possible showing the Fyber ads on top of the MoPub ads.
                       DESC
  s.homepage         = 'https://marketplace-supply.fyber.com/docs/integrating-ios-sdk'
  s.license          = { :type => 'Commercial', :file => 'license.md' }
  s.social_media_url = 'https://www.facebook.com/fybernv/'
  s.source           = { :git => 'https://github.com/inner-active/MoPubAdapter.git', :branch => s.version.to_s, :tag => s.version.to_s }
  s.platforms        = { :ios => "10.0" }
  s.ios.source_files = '5.16/*.{h,m}'
  s.static_framework = true
  s.dependency         'Fyber_Marketplace_SDK', s.version.to_s
  s.dependency         'mopub-ios-sdk/Core', '>= 5.13.1'
end

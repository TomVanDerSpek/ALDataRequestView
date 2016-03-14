#
# Be sure to run `pod lib lint ALDataRequestView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "ALDataRequestView"
s.version          = "0.1.0"
s.summary          = "A view representation for data requests."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
s.description      = "A view representation for data requests. Support for ReactiveCocoa and RXSwift included."

s.homepage         = "https://github.com/<GITHUB_USERNAME>/ALDataRequestView"
# s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
s.license          = 'MIT'
s.author           = { "Antoine van der Lee" => "a.vanderlee@triple-it.nl" }
s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/ALDataRequestView.git", :tag => s.version.to_s }
# s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

s.platform     = :ios, '8.0'
s.requires_arc = true

s.default_subspec = "Core"

s.subspec "Core" do |ss|
ss.source_files  = "Source/*.swift"
ss.dependency "PureLayout"
ss.dependency "ReachabilitySwift"
ss.framework  = "Foundation"
end

# s.subspec "RxSwift" do |ss|
#   ss.source_files = "Source/RxSwift/*.swift"
#   ss.dependency "Moya/RxSwift"
#   ss.dependency "Moya-SwiftyJSONMapper/Core"
#   ss.dependency "RxSwift", "~> 2.0.0"
# end

s.subspec "ReactiveCocoa" do |ss|
ss.source_files = "Source/ReactiveCocoa/*.swift"
ss.dependency "ReactiveCocoa"
ss.dependency "PureLayout"
ss.dependency "ALDataRequestView/Core"
end
end

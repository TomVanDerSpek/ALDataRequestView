Pod::Spec.new do |s|
    s.name             = "ALDataRequestView"
    s.version          = "1.0.0"
    s.summary          = "A view representation for data requests. Support for ReactiveCocoa and RXSwift."
    s.description      = "A view representation for data requests. Support for ReactiveCocoa and RXSwift by attached it to signalproducers and observables."
    s.homepage         = "https://github.com/AvdLee/ALDataRequestView"
    s.license          = 'MIT'
    s.author           = { "Antoine van der Lee" => "info@avanderlee.com" }
    s.source           = { :git => "https://github.com/AvdLee/ALDataRequestView.git", :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/twannl'

    s.platform     = :ios, '8.0'
    s.requires_arc = true

    s.default_subspec = "Core"

    s.subspec "Core" do |ss|
        ss.source_files  = "Source/*.swift"
        ss.dependency "PureLayout"
        ss.dependency "ReachabilitySwift"
        ss.framework  = "Foundation"
    end

    s.subspec "RxSwift" do |ss|
        ss.source_files = "Source/RxSwift/*.swift"
        ss.dependency "RxSwift", "~> 2.0.0"
        ss.dependency "RxCocoa", "~> 2.0.0"
        ss.dependency "ALDataRequestView/Core"
    end

    s.subspec "ReactiveCocoa" do |ss|
        ss.source_files = "Source/ReactiveCocoa/*.swift"
        ss.dependency "ReactiveCocoa"
        ss.dependency "ALDataRequestView/Core"
    end
end

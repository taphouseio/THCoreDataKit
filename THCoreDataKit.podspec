#
# Be sure to run `pod lib lint THCoreDataKit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "THCoreDataKit"
  s.version          = "0.6"
  s.summary          = "A group of Core Data helper classes"
  s.description      = <<-DESC
                       You'll find subclasses for NSManagedObject, a persistence controller, and a helper to use as a delegate for an NSFetchedResultsController
                       DESC
  s.homepage         = "https://github.com/taphouseio/THCoreDataKit"
  s.license          = 'MIT'
  s.author           = { "Jared Sorge" => "contact@taphouse.io" }
  s.source           = { :git => "https://github.com/taphouseio/THCoreDataKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/taphouseio'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'THCoreDataKit' => ['Pod/Assets/*.png']
  }
end

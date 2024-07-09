require 'action_view'
require 'rails_responsive_images/version'
require 'rails_responsive_images/configuration'
require 'rails_responsive_images/engine'

module RailsResponsiveImages
  def self.configuration
    @configuration ||= RailsResponsiveImages::Configuration.new
  end

  def self.configuration=(new_configuration)
    @configuration = new_configuration
  end

  def self.configure
    yield configuration if block_given?
  end

  def self.reset
    @configuration = nil
  end
end


ActionView::Helpers::AssetTagHelper.module_eval do
  
  def image_tag_with_responsiveness(path, options = {})
    options = options.dup
    responsive = options.delete(:responsive) { true }
    skip_pipeline = options.delete(:skip_pipeline)
    if responsive
      content_tag :picture do
        original_file = path.sub(/\A\/assets/, '')
        ::RailsResponsiveImages.configuration.image_sizes.each do |size|
          responsive_image_path = path_to_image("responsive_images_#{size}/#{original_file}", skip_pipeline: skip_pipeline)
          concat content_tag(:source, '', media: "(max-width: #{size}px)", srcset: URI::Parser.new.escape(responsive_image_path))
        end
        concat image_tag(path, options = {})
      end
    else
      image_tag(path, options = {})
    end
  end
  
  def resolve_image_source(source, skip_pipeline)
    if source.is_a?(Symbol) || source.is_a?(String)
      path_to_image(source, skip_pipeline: skip_pipeline)
    else
      polymorphic_url(source)
    end
  rescue NoMethodError => e
    raise ArgumentError, "Can't resolve image into URL: #{e}"
  end
end

require 'rails/generators/base'

module Webvalve
  module Generators
    class FakeServiceGenerator < Rails::Generators::Base
      desc "Creates a WebValve fake service"

      argument :service_name, required: true

      def create_webvalve_fake_service_file
        require_config!
        create_fake_service_file
        register_fake_in_config
      end

      private

      def create_fake_service_file
        create_file full_file_path, <<-FILE.strip_heredoc
          class #{fake_service_class_name} < WebValve::FakeService
            # # define your routes here
            #
            # get '/widgets' do
            #   json result: 'it works!'
            # end
            #
            # # set the base url for this API via ENV
            #
            # export #{parsed_service_name.upcase}_API_URL='http://whatever.dev'
            #
            # # toggle this service on via ENV
            #
            # export #{parsed_service_name.upcase}_ENABLED=true
          end
        FILE
      end

      def register_fake_in_config
        append_to_file config_file_path do <<~RUBY
          WebValve.register "#{fake_service_class_name}"
        RUBY
        end
      end

      def require_config!
        raise 'No WebValve configuration file found. Please run `rails generate webvalve:install` first' unless File.exists?(config_file_path)
      end

      def config_file_path
        "config/webvalve.rb"
      end

      def full_file_path
        "webvalve/#{fake_service_filename}.rb"
      end

      def fake_service_class_name
        fake_service_filename.camelize
      end

      def fake_service_filename
        "fake_#{parsed_service_name.underscore}"
      end

      def parsed_service_name
        service_name.sub(/fake/i, '')
      end
    end
  end
end

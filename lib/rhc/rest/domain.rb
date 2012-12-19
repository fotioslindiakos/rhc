require 'rhc/rest/base'

module RHC
  module Rest
    class Domain < Base
      define_attr :id

      #Add Application to this domain
      # options
      # cartrdige
      # template
      # scale
      # gear_profile
      def add_application(name, options)
        debug "Adding application #{name} to domain #{id}"

        payload = {:name => name}
        options.each do |key, value|
          payload[key] = value
        end
        options = {:timeout => options[:scale] && 0 || nil}
        rest_method "ADD_APPLICATION", payload, options
      end

      define_rest_method :applications, :LINK => "LIST_APPLICATIONS"

      # TODO: Need to specify timeout of 0
      define_rest_method :update, :PARAMS => [:id]
      alias :save :update

      # TODO: Add test to see if we're actually forcing the delete
      define_rest_method :destroy, :LINK => "DELETE", :PARAMS => [:force]
      alias :delete :destroy

      def find_application(name, options={})
        if name.is_a?(Hash)
          options = name.merge(options)
          name = options[:name]
        end
        framework = options[:framework]

        debug "Finding application :name => #{name}, :framework => #{framework}"
        applications.each do |app|
          return app if (name.nil? or app.name == name) and (framework.nil? or app.framework == framework)
        end

        raise RHC::ApplicationNotFoundException.new("Application #{name} does not exist")
      end
    end
  end
end

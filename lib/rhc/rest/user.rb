require 'rhc/rest/base'

module RHC
  module Rest
    class User < Base
      define_attr :login

      define_rest_method :add_key, :PARAMS => [:name,:content,:type]
      define_rest_method :keys,    :LINK => "LIST_KEYS"

      #Find Key by name
      def find_key(name)
        #TODO do a regex caomparison
        keys.detect { |key| key.name == name }
      end
    end
  end
end

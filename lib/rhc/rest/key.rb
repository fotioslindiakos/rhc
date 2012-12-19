require 'rhc/rest/base'

module RHC
  module Rest
    class Key < Base
      define_attr :name, :type, :content

      define_rest_method :update,  :PARAMS => [:type, :content]
      define_rest_method :destroy, :LINK => "DELETE"

      alias :delete :destroy

      def fingerprint
        begin
          public_key = Net::SSH::KeyFactory.load_data_public_key("#{type} #{content}")
          public_key.fingerprint
        rescue NotImplementedError, OpenSSL::PKey::PKeyError => e
          'Invalid key'
        end
      end
    end
  end
end

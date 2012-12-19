require 'uri'
require 'rhc/rest/base'

module RHC
  module Rest
    class Application < Base
      include Rest

      define_attr :domain_id, :name, :creation_time, :uuid, :aliases,
                  :git_url, :app_url, :gear_profile, :framework,
                  :scalable, :health_check_path, :embedded, :gear_count,
                  :ssh_url, :building_app
      alias_method :domain_name, :domain_id

      define_rest_method :gear_groups,  :LINK => "GET_GEAR_GROUPS"
      define_rest_method :threaddump,   :LINK => "THREAD_DUMP",  :event => "thread-dump"

      define_event_rest_method :tidy
      define_event_rest_method :start
      define_event_rest_method :restart
      define_event_rest_method :destroy,      :LINK => "DELETE"
      define_event_rest_method :reload
      define_event_rest_method :stop
      define_event_rest_method :force_stop,   :LINK => "STOP",         :event => "force-stop"
      define_event_rest_method :add_alias,    :event => "add-alias",   :PARAMS => [:alias]
      define_event_rest_method :remove_alias, :event => "remove-alias", :PARAMS => [:alias]

      alias :delete :destroy


      # Query helper to say consistent with cartridge
      def scalable?
        scalable
      end

      def scalable_carts
        return [] unless scalable?
        carts = cartridges.select(&:scalable?)
        scales_with = carts.map(&:scales_with)
        carts.delete_if{|x| scales_with.include?(x.name)}
      end

      def add_cartridge(name, options={})
        debug "Adding cartridge #{name}"
        @cartridges = nil
        options[:timeout] ||= 0
        rest_method "ADD_CARTRIDGE", {:name => name}, options
      end

      # TODO: Need this to cache cartridges
      #define_rest_method :cartridges,    :LINK => "LIST_CARTRIDGES"
      def cartridges
        debug "Getting all cartridges for application #{name}"
        @cartridges ||= rest_method "LIST_CARTRIDGES"
      end

      #Find Cartridge by name
      def find_cartridge(sought, options={})
        debug "Finding cartridge #{sought} in app #{name}"

        type = options[:type]

        cartridges.each { |cart| return cart if cart.name == sought and (type.nil? or cart.type == type) }

        suggested_msg = ""
        valid_cartridges = cartridges.select {|c| type.nil? or c.type == type}
        unless valid_cartridges.empty?
          suggested_msg = "\n\nValid cartridges:"
          valid_cartridges.each { |cart| suggested_msg += "\n#{cart.name}" }
        end
        raise RHC::CartridgeNotFoundException.new("Cartridge #{sought} can't be found in application #{name}.#{suggested_msg}")
      end

      #Find Cartridges by name or regex
      def find_cartridges(name, options={})
        if name.is_a?(Hash)
          options = name
          name = options[:name]
        end

        type = options[:type]
        regex = options[:regex]
        debug "Finding cartridge #{name || regex} in app #{@name}"

        filtered = Array.new
        cartridges.each do |cart|
          if regex
            filtered.push(cart) if cart.name.match(regex) and (type.nil? or cart.type == type)
          else
            filtered.push(cart) if cart.name == name and (type.nil? or cart.type == type)
          end
        end
        filtered
      end

      def host
        @host ||= URI(app_url).host
      end

      def ssh_string
        uri = URI(ssh_url)
        "#{uri.user}@#{uri.host}"
      end

      def <=>(other)
        c = name <=> other.name
        return c unless c == 0
        domain_id <=> other.domain_id
      end
    end
  end
end

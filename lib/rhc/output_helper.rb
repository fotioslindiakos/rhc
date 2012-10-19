module RHC
  module OutputHelpers
    def say_app_info(app)
      header "%s @ %s" % [app.name, app.app_url]
      say "  Created: #{date(app.creation_time)}"
      say "     UUID: #{app.uuid}"
      say "Gear Size: #{app.gear_profile}"
      say " Scalable: #{app.scalable}"
      say "  Git URL: #{app.git_url}" if app.git_url
      say "  SSH URL: #{app.ssh_url}" if app.ssh_url
      say "  Aliases: #{app.aliases.join(', ')}" if app.aliases and not app.aliases.empty?
      carts = app.cartridges
      if carts.present?
        say "\nCartridges:"
        carts.each do |c|
          connection_url = c.property(:cart_data, :connection_url) || c.property(:cart_data, :job_url) || c.property(:cart_data, :monitoring_url)
          value = connection_url ? " - #{connection_url['value']}".rstrip : ""
          say "  #{c.name}#{value}"
        end
      else
        say "Cartridges: none"
      end
    end

    # Issues collector collects a set of recoverable issues and steps to fix them
    # for output at the end of a complex command
    def add_issue(reason, commands_header, *commands)
      @issues ||= []
      issue = {:reason => reason,
               :commands_header => commands_header,
               :commands => commands}
      @issues << issue
    end

    def format_issues(indent)
      return nil unless issues?

      indentation = " " * indent
      reasons = ""
      steps = ""

      @issues.each_with_index do |issue, i|
        reasons << "#{indentation}#{i+1}. #{issue[:reason].strip}\n"
        steps << "#{indentation}#{i+1}. #{issue[:commands_header].strip}\n"
        issue[:commands].each { |cmd| steps << "#{indentation}  $ #{cmd}\n" }
      end

      [reasons, steps]
    end

    def issues?
      not @issues.nil?
    end

    ##
    # These functions will display the relevation information for an object
    #
    # The first element is the title, and the rest are tables
    #   If the table is blank, it will be skipped
    #   If there are no tables, the "no_info_table" will be used
    #
    @@indent = 0

    # This is a little different because we don't want to recreate the display_app function
    def display_domain(domain)
      say "No domain exists.  You can use 'rhc domain create' to create a namespace for applications." and return unless domain
      paragraph do
        header "Applications in %s" % domain.id
        @@indent += 1
        domain.applications.each_with_index do |a,i|
          section(:top => (i == 0 ? 1 : 2)) do
            display_app(a)
          end
        end.blank? and say "No applications. You can use 'rhc app create' to create new applications."
      end
    end

    def display_app(app)
      show_tables(
        "%s @ %s" % [app.name, app.app_url],
        ["Application Info",properties_table(app,:creation_time,:uuid,:git_url,:ssh_url,:aliases)],
        ["Cartridges", included_carts_table(app)],
        ["Scaling Info", app_scaling_info_table(app)]
      )

      # Uncomment this for easier showing of all of the cartridges for this app
      # TODO: Remove before final commit
      if ENV['SHOW_CARTS']
        say "-" * 50
        paragraph do
          header "Cartridges"
          app.cartridges.each do |cart|
            display_cart(cart)
          end
        end
        say "-" * 50
      end
    end

    def display_cart(cart)
      show_tables(
        cart.name,
        ["Properties", cart_info_table(cart)],
        ["Scaling Info", cart_scaling_info_table(cart)]
      )
    end

    #
    # Output heading and tables
    #
    def show_tables(title,*tables)
      # Remove any tables with no information
      tables.delete_if{|x| x.last.blank?}
      tables.compact!
      # Use the "no_info_table" to show some information
      tables << [nil,no_info_table] if tables.blank?

      say_table(title,tables)
    end

    def say_table(heading,table)
      # Reduce the indent if we don't have a heading
      paragraph do
        # Show the header if we have one
        header heading, :indent => @@indent if heading
        # Go through all the table rows
        @@indent += 1 if heading
        table.each do |s|
          # If this is an array, we're assuming it's recursive
          if s.is_a?(Array)
            say_table(s[0],s[1])
          else
            # Remove trailing = (like for cartridges list)
            s.gsub!(/\s*=\s*$/,'')
            indent s, @@indent
          end
        end
        @@indent -= 1 if heading
      end
    end

    # Get the properties from a cartridge
    def cart_info_table(cart)
      properties = cart.properties[:cart_data] or return
      # We need to actually access the cart because it's not a simple hash
      properties = get_properties(cart,*properties.keys) do |prop|
        cart.property(:cart_data,prop)["value"]
      end
      make_table properties
    end

    # Scaling info for both applications and cartridges
    def app_scaling_info_table(app)
      cart = app.scalable_carts.first or return

      # Save these values for easier reuse
      values = [:current_scale,:scales_from,:scales_to,:scales_with]
      # Get the scaling properties we care about
      properties = get_properties(cart,*values)
      # Format the string for applications
      properties = "Scaled x%d (minimum: %s, maximum: %s) with %s on %s gears" %
        [properties.values_at(*values), app.gear_profile].flatten
      make_table properties
    end

    def cart_scaling_info_table(cart)
      return unless cart.scalable?
      properties = get_properties(cart,:current_scale,:scales_from,:scales_to)
      make_table properties
    end

    def properties_table(object,*properties)
      make_table get_properties(object,*properties), :delete => true
    end

    def included_carts_table(object)
      make_table get_carts(object), :preserve_keys => true
    end

    def no_info_table
      make_table "This item has no information to show"
    end

    private

    # This returns the carts for an application.
    #   This is different because we change the hash to be:
    #     {name => connection_info}
    def get_carts(app)
      carts = app.cartridges
      return nil unless carts.present?

      Hash[carts.map do |cart|
        [cart.name,cart.connection_info]
      end]
    end

    # This uses the array of properties to retrieve them from an object
    def get_properties(object,*properties)
      Hash[properties.map do |prop|
        # Either send the property to the object or yield it
        value = block_given? ? yield(prop) : object.send(prop)
        # Some values (like date) need some special handling
        value = format_value(prop,value)

        [prop,value]
      end]
    end

    # Format some special values
    def format_value(prop,value)
      case prop
      when :creation_time
        date(value)
      when :scales_from,:scales_to
        (value == -1 ? "Unlimited" : value)
      else
        value
      end
    end

    # Make the rows for the table
    #   If we pass a hash, it will manipulate it into a nice table
    #   Arrays and single vars will just be passed back as arrays
    def make_table(values,opts = {})
      case values
      when Hash
        # Loop through the values in case we need to fix them
        _values = values.inject({}) do |h,(k,v)|
          # Format the keys based on the table_heading function
          #  If we pass :preserve_keys, we leave them alone (like for cart names)
          key = opts[:preserve_keys] ? k : table_heading(k)

          # Replace empty or nil values with spaces
          #  If we pass :delete, we assume those are not needed
          if v.blank?
            h[key] = "" unless opts[:delete]
          else
            h[key] = v.to_s
          end
          h
        end
        # Join the values into rows
        table _values, :join => " = "
        # Create a simple array
      when Array
        values
      else
        [values]
      end
    end
  end
end

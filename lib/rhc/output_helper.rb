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

    def display_app_info(app, includes = [:application_info,:cartridges_info,:scaling_info])
      info_table(app,includes)
    end

    def display_cart_info(cart, includes = [:properties_info,:scaling_info])
      info_table(cart,includes)
    end

    private

    def info_table(object,includes)
      type = object.class.name.split("::").last.downcase

      # Allow for passing a single include as a symbol
      includes = [*includes]

      # Create the tables
      tables = Hash[includes.map do |table_type|
        object.send(table_type)
      end]

      # Remove any undefined data
      tables.delete_if{|key,val| val.nil? or val.empty? }

      # Add a top level header if we have more than one table
      if tables.length > 1
        paragraph do
          header object.header
        end
      else
        # If just one table, prepend the object name
        tables = tables.inject({ }) { |x, (k,v)| x["#{object.name} #{k}"] = v; x }
      end

      # Loop through each table and print it
      if tables.empty?
        say "This #{type} has no information to show"
      else
        show_tables(tables)
      end

      !tables.empty?
      # Return whether there was any information to show
    end

    def show_tables(tables)
      tables.each do |title,hash|
        to_table(title,hash)
      end
    end

    def to_table(title,values)
      items = []

      new_values = case values
                    when Hash
                      values
                    else
                      Hash[[values].flatten.map{|x| [x,nil]}]
                    end

      new_values.each do |key,val|
        items << [key,format_value(val)]
      end

      table = table items, :join => " = "

      paragraph do
        header indent(title)
        table.each do |s|
          s.gsub!(/\s*=\s*$/,'')
          say indent(s,2)
        end
      end
    end

    def format_value(val)
      case
      when val.nil?
        ""
      when (date = date(val)) != "Unknown date"
        date
      else
        val.to_s
      end
    end

    def indent(str,indent = 0)
      "%s%s" % [" " * indent, str]
    end
  end
end

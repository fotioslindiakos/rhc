module RHC::Rest::Dynamic
  def define_rest_method(*args)
    (method,arguments) = parse_args(*args)

    link_name = arguments.delete(:LINK) || method.to_s.upcase
    param_names = arguments.delete(:PARAMS)

    # This is needed because we can't actually save the arguments
    # in the newly defined method
    @@rest_method_defaults ||= {}
    @@rest_method_defaults[method.to_sym] = {
      :arguments    => arguments,
      :param_names  => param_names
    }

    define_method("#{method}") do |*args|
      defaults = @@rest_method_defaults[method] || {}
      opts = {}
      args.each do |arg|
        case arg
        when Hash
          opts = arg
        end
      end

      if (default_opts = defaults[:arguments])
        opts = default_opts.merge(opts)
      end

      debug "Calling #{link_name}"
      rest_method(link_name, opts)
    end
  end

  def define_event_rest_method(*args)
    (method,arguments) = parse_args(*args)
    arguments[:event] ||= method.to_s

    define_rest_method(method,arguments)
  end

  private
  def parse_args(*args)
    [args,{}].flatten.compact
  end
end

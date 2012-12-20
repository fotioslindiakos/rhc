module RHC::Rest::Dynamic
  def define_rest_method(*args)
    arguments = args.extract_options!
    method = args.first

    link_name = arguments.delete(:LINK) || method.to_s.upcase
    param_names = arguments.delete(:PARAMS)
    options = arguments.delete(:OPTIONS) || {}

    # This is needed because we can't actually save the arguments
    # in the newly defined method
    @@rest_method_defaults ||= {}
    @@rest_method_defaults[method.to_sym] = {
      :arguments    => arguments,
      :param_names  => [*param_names],
      :options      => options
    }

    send :define_method, method do |*_args|
      _options = _args.extract_options!
      _arguments = _args

      # The defaults for this method
      defaults = @@rest_method_defaults[method] || {}

      # Combine any opts with their param names and the defaults
      _arguments = Hash[defaults[:param_names].zip(_arguments)].merge!(defaults[:arguments])

      _options.merge!(defaults[:options])

      debug "Calling #{link_name} with #{_arguments}"

      rest_method(link_name, _arguments, _options)
    end
  end

  def define_event_rest_method(*args)
    arguments = args.extract_options!
    method = args.first

    arguments[:event] ||= method.to_s

    define_rest_method(method,arguments)
  end
end

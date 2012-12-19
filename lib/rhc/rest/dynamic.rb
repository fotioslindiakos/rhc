#TODO: This should get moved into core_ext
class Hash
  # By default, only instances of Hash itself are extractable.
  # Subclasses of Hash may implement this method and return
  # true to declare themselves as extractable. If a Hash
  # is extractable, Array#extract_options! pops it from
  # the Array when it is the last element of the Array.
  def extractable_options?
    instance_of?(Hash)
  end
end

class Array
  # Extracts options from a set of arguments. Removes and returns the last
  # element in the array if it's a hash, otherwise returns a blank hash.
  #
  #   def options(*args)
  #     args.extract_options!
  #   end
  #
  #   options(1, 2)        # => {}
  #   options(1, 2, a: :b) # => {:a=>:b}
  def extract_options!
    if last.is_a?(Hash) && last.extractable_options?
      pop
    else
      {}
    end
  end
end

module RHC::Rest::Dynamic
  def define_rest_method(*args)
    arguments = args.extract_options!
    method = args.first

    link_name = arguments.delete(:LINK) || method.to_s.upcase
    param_names = arguments.delete(:PARAMS)

    # This is needed because we can't actually save the arguments
    # in the newly defined method
    @@rest_method_defaults ||= {}
    @@rest_method_defaults[method.to_sym] = {
      :arguments    => arguments,
      :param_names  => [*param_names]
    }

    define_method("#{method}") do |*_args|
      _options = _args.extract_options!
      _arguments = _args

      # The defaults for this method
      defaults = @@rest_method_defaults[method] || {}

      # Combine any opts with their param names and the defaults
      _arguments = Hash[defaults[:param_names].zip(_arguments)].merge!(defaults[:arguments])

      debug "Calling #{link_name} with #{_arguments}"
      rest_method(link_name, _arguments)
    end
  end

  def define_event_rest_method(*args)
    arguments = args.extract_options!
    method = args.first

    arguments[:event] ||= method.to_s

    define_rest_method(method,arguments)
  end
end

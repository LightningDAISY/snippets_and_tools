class CL
  class Parser
    attr_accessor :options
    attr_accessor :commands

    def initialize
      @options  = {}
      @commands = []
      @format   = {}
    end

    #
    # e.g.
    #
    # format(
    #   a: :none,     # option "-a" has no value
    #   b: :single,   # option "-b" need one value
    #   c: :multi     # option "-c" need one or more values
    # )
    #
    def format(struct = {})
      @format = struct
      self
    end

    def parse(args = ARGV)
      lastname = ""
      args.each do |arg|
        if name? arg
          lastname = to_name arg
          if has_format?(lastname) && get_format(lastname) == :single
            @options[lastname.to_sym] = []
          else
            @options[lastname.to_sym] ||= []
          end
        else
          if lastname.size > 0
            if has_format? lastname
              case get_format lastname
              when :none
                @commands << arg
              when :single
                @options[lastname.to_sym] = [arg]
              else
                @options[lastname.to_sym] << arg
              end
            else
              @options[lastname.to_sym] << arg
            end
            lastname = ""
          else
            @commands << arg
          end
        end
      end
      self
    end

    private def name?(arg)
      arg[0] == ?-
    end

    private def to_name(value)
      value.sub(/^-+/) { "" }
    end

    private def has_format?(name)
      @format.key? name.to_sym
    end

    private def get_format(name)
      return nil unless has_format?(name)
      @format[name.to_sym]
    end
  end
end


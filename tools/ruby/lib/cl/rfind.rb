require "cl/parser"

class CL
  class RFind
    @@option_format = {
      d: :none,     # decorate
      e: :multiple, # extentions
      h: :none,     # help
      i: :none,     # infinite filesize
      n: :none,     # find by filename
      p: :multiple, # path
      r: :none,     # recursive
      s: :none,     # simple output
      ignore: :multiple, # ignore path (start with)
    }

		Signal.trap :INT do; exit 1; end

    private def help
      puts <<~HELP

        options:
          -h            print basic options
          -n            find by filename
          -p [path]     search path
          -r            recursive (show all matched lines)
          -d            colors
          -e [ext]      filter by extension
          -s            simple output
          -i            infinite filesize (limited 1MB by default)

        example:
          #{$0} -p ~/Downloads -e txt -e doc -r -d [Pp]assword

      HELP
    end

    def find
      @opt = CL::Parser.new.format(@@option_format).parse
      return help if @opt.options.key? :h
      paths = @opt.options[:p] || ["./"]
      files = get_files paths, @opt.commands
      show files
    end

    private def show files
      files.each do |file|
        path = file[:path]
        if @opt.options.key? :d
          path = "\e[36m" + path + "\e[0m"
        end
        puts "#{path}"

        next unless file.key? :lines
        next if @opt.options.key? :s
        file[:lines].each do |line|
          puts "  line #{line[:number]}"
          puts "  #{line[:body]}\n"
        end
      end
    end

    private def get_max_layers paths = []
      wc = 1
      max_wc = 1
      paths.each do |path|
        next unless FileTest.exist? path
        next unless FileTest.directory? path
        while Dir.glob(normalize(path) + ("/*" * wc)).size > 0
          wc += 1
        end
        max_wc = wc if max_wc < wc
      end
      return max_wc
    end

    private def normalized_e_options
      return [""] unless @opt.options.key? :e
      options = []
      @opt.options[:e].each do |e|
        e = "." + e if e[0] != "."
        options << e
      end
      options
    end

    private def get_target_files paths = [], max = 1
      files = []
      paths.each do |path|
        next unless FileTest.exist? path
        next unless FileTest.directory? path
        for i in 1..max do
          normalized_e_options.each do |e|
            Dir.glob(normalize(path) + ("/*" * i) + e).each do |node|
              files << node if FileTest.file? node
            end
          end
        end
      end
      files
    end

    private def get_name path
      nodes = path.split "/"
      nodes.pop
    end

    private def get_files_by_name files, commands
      match_files_hash = {}
      files.each do |file|
        commands.each do |command|
          r = Regexp.new command
          name = get_name file
          if name.match r
            match_files_hash[file] = {
              path: file
            }
            next
          end
        end
      end
      match_files_hash.values
    end

    private def too_large_file? path
      return false if @opt.options.key? :i
      if FileTest.size(path) > 1000000
        warn path + " \e[31mis too large.\e[0m (use -i option)"
        return true
      end
      false
    end

    private def get_files paths = [], commands = []
      commands << "." if commands.size <= 0
      files = get_target_files paths, get_max_layers(paths)
      return get_files_by_name files, commands if @opt.options[:n]

      match_files = []
      match_files_hash = {}

      files.each do |file|
        next if too_large_file? file
        File.open file do |fh|
          line_number = 0
          commands.each do |command|
            r = Regexp.new command
            fh.each_line do |line|
              line.scrub! ""
              line_number += 1
              if line.match? r
                if match_files_hash.key? file
                  match_files_hash[file][:lines] << {
                    number: line_number,
                    matched: command,
                    body: line,
                  }
                elsif command == "."
                  match_files_hash[file] = {
                    path: file,
                    lines: []
                  }
                else
                  match_files_hash[file] = {
                    path: file,
                    lines: [
                      {
                        number: line_number,
                        matched: command,
                        body: line,
                      }
                    ]
                  }
                end
                break unless @opt.options.key? :r
              end
            end
          end
        end
      end
      match_files_hash.each do |name, value|
        match_files << value
      end
      match_files
    end

    private def normalize path
      path = path.chomp
      path = path.delete_suffix "/" while path[-1] == ?/
      path
    end
  end
end


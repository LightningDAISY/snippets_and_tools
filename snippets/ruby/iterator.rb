#
# sortは一度だけ実行されます。
# each中でyieldするのでループも一度限りです。
# 添え字も使いません。
#
class Example
  def initialize(config = {})
    def config.iterate
      sorted = self.sort_by { |_, value| value[:Num] || 0 }
      sorted.each do |key, value|
        yield key, value
      end
    end
    @config = config
  end

  def show_config
    @config.iterate do |name, value|
      puts "#{name} : #{value}"
    end
  end
end

Example.new({ name1: 'value1', name2: 'value2' }).show_config


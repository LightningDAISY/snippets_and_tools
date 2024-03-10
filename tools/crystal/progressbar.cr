#
# Example:
#
#   pbar = Clis::Progressbar.new(
#     colorize: true,
#     maxNumber: 10000,
#     interval: 0.2
#   )
#   pbar.plus 100
#   pbar.plus 2000
#   pbar.set 7000
#   pbar.finish
#
require "colorize"

module Clis
  class Progressbar
    VERSION = "0.0.1"
    property logFilePath : String = "./log/debug.log"
    property maxNumber : Float64
    property currentNumber : Float64
    property maxBarSize : Float64
    property barCharacter : String
    property baseCharacter : String
    property goalCharacter : String

    # color
    property colored : Bool = false
    property curlyColor : Symbol
    property numberColor : Symbol
    property barColor : Symbol
    property goalColor : Symbol

    # sleeptime
    property sleepSecond : Float64

    def initialize(
      maxNumber : Float64 = 100,
      currentNumber : Float64 = 0,
      maxBarSize : Float64 = 50,
      barCharacter : String = "=",
      baseCharacter : String = " ",
      goalCharacter : String = "|",
      colorize : Bool = false,
      curlyColor : Symbol = :light_yellow,
      numberColor : Symbol = :light_yellow,
      barColor : Symbol = :light_cyan,
      goalColor : Symbol = :light_cyan,
      interval : Float64 = 0.1
    )
      @maxNumber = maxNumber
      @currentNumber = currentNumber
      @maxBarSize = maxBarSize
      @barCharacter = barCharacter
      @baseCharacter = baseCharacter
      @goalCharacter = goalCharacter
      @colored = colorize
      @curlyColor = curlyColor
      @numberColor = numberColor
      @barColor = barColor
      @goalColor = goalColor
      @sleepSecond = interval

      raise "cannot set 0" if @maxNumber == 0
    end

    def log(message : String) : Bool
      if File.exists? @logFilePath
        File.open(@logFilePath, "a") do |logfile|
          logfile.puts("#{message}")
        end
        return true
      else
        false
      end
    end

    def show
      ratio : Float64 = @currentNumber / @maxNumber * 100
      percent : Int64 = ratio.to_i64
      barValue : Float64 = 100 / maxBarSize
      currentBarSize : Int64 = (ratio / barValue).to_i64
      if @colored
        openCurly = "[".colorize(@curlyColor).mode(:bold).to_s
        closeCurly = "]".colorize(@curlyColor).mode(:bold).to_s
        percentStr = sprintf("%3d%%", percent.to_s).colorize(@numberColor).mode(:bold).to_s
        barStr = (@barCharacter * currentBarSize).colorize(@barColor).to_s
        print "#{openCurly} #{percentStr} #{closeCurly} #{barStr}\r"
      else
        printf "[ %3d%% ] #{@barCharacter * currentBarSize}\r", percent.to_s
      end
      sleep @sleepSecond
      true
    end

    def init : Bool
      print "\n"
      print baseCharacter * (maxBarSize.to_i64 + 9)
      if @colored
        print "#{goalCharacter}".colorize(@goalColor).to_s + "\r"
      else
        print "#{goalCharacter}\r"
      end
      show
    end

    def set(num : Float64 = 0) : Bool
      init if @currentNumber == 0
      @currentNumber = num
      show
    end

    def set(num : Int32) : Bool
      plus num.to_f64
    end

    def set(num : Int64) : Bool
      plus num.to_f64
    end

    def plus(num : Float64 = 1) : Bool
      init if @currentNumber == 0
      @currentNumber += num
      show
    end

    def plus(num : Int32) : Bool
      plus num.to_f64
    end

    def plus(num : Int64) : Bool
      plus num.to_f64
    end

    def +(num) : Bool
      plus num
    end

    def <<(num) : Bool
      set num
    end

    def finish
      set @maxNumber
      print "\n"
    end
  end
end

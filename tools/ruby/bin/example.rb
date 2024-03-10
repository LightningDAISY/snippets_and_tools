#! /usr/bin/env ruby

$:.unshift File.dirname(__FILE__) + "/../lib"
require "cl/parser"

def cl_parser
  option_format = {
    a: :none,
    b: :single,
    c: :multi,
  }
  opt = CL::Parser.new.format(option_format).parse(ARGV)
  pp opt.options
  pp opt.commands
end

cl_parser

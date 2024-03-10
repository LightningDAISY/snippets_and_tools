#
# How to use
#
#   $ cat jis.txt | ./b64
#   GyRCJCIkJCQmJCgkKhsoQiAK
#
#   # echo -e "GyRCJCIkJCQmJCgkKhsoQiAK" | ./b64 decode > decoded.txt
#   # vi decoded.txt
#
require "base64"

if ARGV.size > 0 && ARGV[0] == "-h"
  puts %Q(Usage: echo -e "😆👍" | ./b64 | ./b64 d)
  exit(1)
end

all = STDIN.gets_to_end
if ARGV.size > 0 && typeof(ARGV[0]) == String && ARGV[0][0] == 'd'
  de = Base64.decode all
  puts String.new(de)
else
  puts Base64.encode all
end


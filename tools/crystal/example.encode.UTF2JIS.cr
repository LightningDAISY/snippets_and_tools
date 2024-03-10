require "base64"

str = "日本語です"

fp = File.open("encoded.txt", "w", encoding: "ISO-2022-JP-1")
#fp = File.open("encoded.txt", "w")
fp.puts str
fp.close

File.open("encoded.txt", "r") do |fp|
	buffer_length = 10
	result = [] of UInt8
	loop do
		s = Slice(UInt8).new(buffer_length)
		len = fp.read(s)
	   	break if len < 1
		len.times do |i|
			result << s[i]
		end
	end
	result_slice = Slice(UInt8).new(result.size)
	result.size.times do |i|
		result_slice[i] = result[i]
	end
	puts en = Base64.encode(result_slice)
	puts de = Base64.decode(en)
	#puts String.new(de)
end


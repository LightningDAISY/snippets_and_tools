#! /usr/local/openresty/bin/resty

function main()
    local subnet = require "subnet"
    --[[

        example nginx-allow.conf

            # localhost
            allow 127.0.0.1;

            # Private Network Address: Class B
            allow 172.16.0.0/12;

            # Private Network Address: Class C
            allow 192.168.0.0/24;

    ]]--
    local isAllowed = subnet.isAllowed("192.168.1.5", "/etc/basic_auth/nginx-allow.conf")
    if isAllowed then
        print("is allowed.")
    else
		-- return ngx.exit(ngx.OK)
        print("is NOT allowed.")
    end
end

main()


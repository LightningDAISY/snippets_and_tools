#! /usr/bin/env luajit

function main()
    local convert = {
        ["八"] = 8,
        ["十"] = 10,
        ["二"] = 2,
        ["七"] = 7,
        ["五"] = 5,
        ["一"] = 1,
        ["九"] = 9,
        ["三"] = 3,
        ["六"] = 6,
        ["四"] = 4
    }
    local arr = {"八", "十", "二", "七", "五", "一", "九", "三", "六", "四"}
    table.sort(arr, function(a,b) return convert[a] < convert[b] end)
    print(table.concat(arr, ", "))
end

main()


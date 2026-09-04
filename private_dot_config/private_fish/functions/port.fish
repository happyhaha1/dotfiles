function port --description 'Show processes using a TCP or UDP port'
    if test (count $argv) -eq 0
        echo 'Usage: port <port_number>'
        return 1
    end
    lsof -i ":$argv[1]"
end

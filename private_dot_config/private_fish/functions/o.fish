function o --description 'Open a path in Finder or the default file manager'
    open (test (count $argv) -gt 0; and echo $argv[1]; or echo '.')
end

function gh_clone --description 'Clone a GitHub repository into the ghq root'
    if test (count $argv) -eq 0
        echo 'Usage: gh_clone <owner/repo>'
        return 1
    end
    ghq get "https://github.com/$argv[1]"
end

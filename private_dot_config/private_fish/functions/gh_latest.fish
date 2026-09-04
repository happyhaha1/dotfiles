function gh_latest --description 'Print the latest GitHub release tag for a repository'
    if test (count $argv) -eq 0
        echo 'Usage: gh_latest <owner/repo>'
        return 1
    end
    gh api "repos/$argv[1]/releases/latest" --jq '.tag_name'
end


#----------------gco, star-------------
function gco,
  function isGit
		if [ -d .git ]
			echo "1"
		else
			set isGit (git rev-parse --git-dir 2> /dev/null)
		end
	end
	if test -z (isGit)
		echo "Not a git repository"
		return
	end
  git status -suno | read -l st
  if [ -n "$st" ]
    git status
    return -1
  end

  git branch -a | grep -v '*' | tr -d " " | fzf |read -l branch
  if [ -n "$branch" ]
    string match '*remotes/origin/*' $branch|read -l isRemotes
    if [ -n "$isRemotes" ] 
      echo "$branch is remotes branch" 
      string replace -a 'remotes/origin/' '' $branch |read -l remotes
      git checkout -b $remotes $branch
    else
      git checkout $branch
    end
  else
    echo "please select one branch"
  end
end
#----------------------gco, end-----------------

#---------------------clone ,star---------------------
function clone --description "clone something, cd into it. install it."
    if [ -n "$argv[1]" ] 
       string match '*github*' $argv[1]|read -l isGithub
       if [ -n "$isGithub" ]
          echo "start proxy"
          proxy
       end
       git clone --depth=1 $argv[1]
       cd (basename $argv[1] | sed 's/.git$//')
       if [ -n "$isGithub" ]
          echo "end proxy"
          noproxy
       end
    else
      echo "please input git url"
      return -1
    end
end
#---------------------clone ,end---------------------

#---------------------md ,star---------------------
function md --wraps mkdir -d "Create a directory and cd into it"
  command mkdir -p $argv
  if test $status = 0
    switch $argv[(count $argv)]
      case '-*'
      case '*'
        cd $argv[(count $argv)]
        return
    end
  end
end
#---------------------md ,star---------------------

function rma --wraps rm -d "rm all file"
  rm -i $argv|read -l isDirectory
  echo $isDirectory
  if [ -n "$isDirectory"]
    get --prompt="remove $argv?" --rule="y|n" --no-cursor --silent=1|read -l yesOrNo
    if [ "y" = "$yesOrNo" ]
      rm -rf $argv
    end
  end
end

function brewi --wraps brew -d "brew install"
  proxy
  brew install $argv
  noproxy
end

function pbwd -d "pwd|pbcopy"
    pwd|pbcopy
end


# Homebrew (Linux) — put brew on PATH for login/non-interactive shells too.
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv | source
end

if status is-interactive
    abbr --add -- ll "ls -lha"
    abbr --add -- vim nvim
    abbr --add -- duu "du -h -d 1 | sort -hr"
    direnv hook fish | source
    fish_add_path ~/.local/bin  # osc52-copy and other user scripts

    function source_cwd --on-variable FISH_SOURCE_CWD
        if test -n "$FISH_SOURCE_CWD"
            echo "🎣 Hook detected. Sourcing config.fish..."
            source "$PWD/config.fish"
        end
    end
end

function gh-pat-ls --description 'List orgs with a stored PAT'
    for f in $HOME/.local/share/gh-tokens/pat-*
        test -e $f; and string replace -- "$HOME/.local/share/gh-tokens/pat-" '' $f
    end
end

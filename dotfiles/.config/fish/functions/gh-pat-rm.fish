function gh-pat-rm --description 'Remove a stored GitHub org PAT'
    set -l dir $HOME/.local/share/gh-tokens
    set -l org $argv[1]

    if test -z "$org"
        echo "usage: gh-pat-rm ORG" >&2
        echo "stored: "(gh-pat-ls | string join ' ') >&2
        return 1
    end

    if not test -f $dir/pat-$org
        echo "gh-pat-rm: no stored PAT for '$org'" >&2
        echo "stored: "(gh-pat-ls | string join ' ') >&2
        return 1
    end

    rm -- $dir/pat-$org; or return 1
    echo "✓ removed $org"
end

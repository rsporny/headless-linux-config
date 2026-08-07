function gh-pat-add --description 'Store a GitHub PAT for an org or user namespace'
    argparse --name=gh-pat-add f/force -- $argv; or return 1

    set -l owner $argv[1]
    if test -z "$owner"
        echo "usage: gh-pat-add [-f] OWNER" >&2; return 1
    end
    if string match -qr '[^A-Za-z0-9._-]' -- $owner
        echo "gh-pat-add: refusing odd owner name '$owner'" >&2; return 1
    end

    set -l dir $HOME/.local/share/gh-tokens
    mkdir -p $dir; or return 1
    chmod 700 $dir

    read --local --silent --prompt-str="PAT for $owner: " token
    echo
    set token (string trim -- $token)
    if test -z "$token"
        echo "gh-pat-add: no token given" >&2; return 1
    end

    if not set -q _flag_force
        set -l code (curl -sS -o /dev/null -w '%{http_code}' \
            -H "Authorization: Bearer $token" \
            "https://api.github.com/orgs/$owner/repos?per_page=1")
        if test "$code" = 404
            set code (curl -sS -o /dev/null -w '%{http_code}' \
                -H "Authorization: Bearer $token" \
                "https://api.github.com/users/$owner/repos?per_page=1")
        end
        switch $code
            case 200
            case 401
                echo "gh-pat-add: token rejected (401) — wrong paste or expired" >&2; return 1
            case 403
                echo "gh-pat-add: token valid, access denied (403) — SSO or pending org approval" >&2; return 1
            case 404
                echo "gh-pat-add: '$owner' not visible to this token (404) — typo, or token scoped elsewhere" >&2; return 1
            case '*'
                echo "gh-pat-add: unexpected status '$code' — use -f to store anyway" >&2; return 1
        end
    end

    set -l f $dir/pat-$owner
    set -l verb stored
    test -f $f; and set verb replaced

    touch $f; or return 1
    chmod 600 $f; or return 1
    printf '%s' $token > $f
    echo "✓ $verb PAT for $owner"
end

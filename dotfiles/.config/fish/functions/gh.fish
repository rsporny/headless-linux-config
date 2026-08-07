function gh --wraps gh --description 'gh with the PAT for the target repo owner'
    # An explicit GH_TOKEN wins — direnv, or a deliberate one-off
    if set -q GH_TOKEN; and test -n "$GH_TOKEN"
        __gh_note "wrapper standing down — GH_TOKEN already set in environment"
        command gh $argv; return
    end

    set -l res (__gh_owner $argv)
    if test (count $res) -lt 2
        command gh $argv; return          # no repo context: gh --version, --help, etc.
    end
    set -l owner $res[1]
    set -l src $res[2]

    set -l f $HOME/.local/share/gh-tokens/pat-$owner
    if not test -r $f
        echo "gh-wrapper: no PAT stored for '$owner' ($src) — run: gh-pat-add $owner" >&2
        command gh $argv; return
    end

    __gh_note "wrapping gh with PAT for '$owner', selected from $src"
    env GH_TOKEN=(cat $f) gh $argv
end

function __gh_note --description 'Dim status note, terminal only'
    isatty stderr; or return
    echo (set_color brblack)"gh-wrapper: $argv[1]"(set_color normal) >&2
end

function __gh_owner --description 'Echoes: owner, then where it came from'
    set -l n (count $argv)
    for i in (seq $n)
        switch $argv[$i]
            case -R --repo
                set -l j (math $i + 1)
                if test $j -le $n
                    string split -m1 -f1 / -- $argv[$j]
                    echo "the --repo flag"
                    return
                end
            case '--repo=*'
                string split -m1 -f1 / -- (string replace -- '--repo=' '' $argv[$i])
                echo "the --repo flag"
                return
        end
    end
    set -l url (git config --get remote.origin.url 2>/dev/null)
    set -l owner (string match -rg 'github\.com[:/]([^/]+)/' -- $url)
    if test -n "$owner"
        echo $owner
        echo "this repo's origin remote"
    end
end

export LGSTEM=niridrop

config_file="$XDG_CONFIG_HOME/niri/niridrop.json"
last_file="$XDG_STATE_HOME/niridrop/last"
actual_last_file="$XDG_STATE_HOME/niridrop/actual_last"

mkdir -p "$XDG_STATE_HOME/niridrop" &>/dev/null
touch "$last_file" &>/dev/null
touch "$actual_last_file" &>/dev/null

special_workspace="$(cat "$config_file" | jq -r .workspace)"
[[ "$special_workspace" == "null" ]] && special_workspace=dropdown
[[ -z "$special_workspace" ]] && special_workspace=dropdown

lga start

function finish() {
    lga finish
    if [[ -n "${1:-}" ]];
    then exit 1
    else exit 0
    fi
}

function config() {
    if [ -z "${1:-}" ]; then lge "config called without window name, exiting..."; finish 1; fi
    if [ -z "${2:-}" ]; then lge "config called without option name, exiting..."; finish 1; fi

    jq -r ".windows.\"$1\".$2" "$config_file"
}

function set_last() {
    if [ -z "${1:-}" ]; then lge "set_last called without dropdown name, exiting..."; finish 1; fi

    name="$1"; lga F "set_last, name[$name], flag_forget[$flag_forget]"

    (( ! flag_forget )) && echo "$name" > "$last_file"
    echo "$name" > "$actual_last_file"
}

function get_last() { cat "$last_file"; }
function get_actual_last() { cat "$actual_last_file"; }

function spawn_window() {
    if [ -z "${1:-}" ]; then lge "spawn_window called without name, exiting..."; finish 1; fi

    name="$1"; lga F "spawn_window, name[$name]"

    app_id="$(config "$name" "app_id")"
    cmd="$(config "$name" "cmd")"

    if [ "$app_id" == "null" ]; then lge "name[$name] doesn't have a 'app_id' defined, exiting..."; finish 1; fi
    if [ "$cmd" == "null" ]; then lge "name[$name] doesn't have a 'cmd' defined, exiting..."; finish 1; fi

    lga . "got app_id[$app_id] cmd[$cmd]"

    focused_id="$(niri msg --json focused-window | jq -r .id)"
    lga . "saved id[$focused_id] to focus back onto after opening '$name'"

    niri msg action spawn-sh -- "$cmd" &

    while read -r line; do
        case $line in
            '{"WindowOpenedOrChanged":'*)
            win_app_id="$(echo "$line" | jq -r .WindowOpenedOrChanged.window.app_id)"
            win_id="$(echo "$line" | jq -r .WindowOpenedOrChanged.window.id)"

            lga . "captured new window with app_id[$win_app_id], id[$win_id]"

            if [ "$win_app_id" == "$app_id" ]; then
                lga . "matched, returning window id id[$win_id]"
                echo "$win_id"
                return 0
            fi
            ;;
        esac
    done < <(niri msg --json event-stream)
}

function show_window() {
    if [ -z "${1:-}" ]; then lge "show_window called without name, exiting..."; finish 1; fi
    name="$1"; lga F "show_window, name[$name]"

    workspace="$(niri msg --json workspaces | jq -r "first(.[] | select(.is_active)).idx")"
    lga . "save current ws idx[$workspace]"

    cfg_app_id="$(config "$name" "app_id")"

    id="$(niri msg --json windows | jq -r ".[] | select(.app_id == \"$cfg_app_id\").id")"
    if [ -z "$id" ]; then
        lga . "no window with app_id[$cfg_app_id], spawning the window"
        id="$(spawn_window "$name")"
    fi

    set_last "$name" &

    lga . "moving win[$id] to current workspace[$workspace]"
    niri msg action move-window-to-workspace --window-id "$id" "$workspace" &

    lga . "focusing window[$id]"
    niri msg action focus-window --id "$id" &
}

function hide_window() {
    if [ -z "${1:-}" ]; then lge "hide_window called without name, exiting..."; finish 1; fi
    name="$1"; lga F "hide_window, name[$name]"

    cfg_app_id="$(config "$name" "app_id")"

    id="$(niri msg --json windows | jq -r ".[] | select(.app_id == \"$cfg_app_id\").id")"
    if [ -z "$id" ]; then lga . "no window with app_id[$cfg_app_id], let's consider the window closed"; return 0 ; fi

    ws_idx="$(niri msg --json workspaces | jq -r '.[] | select(.is_focused).idx')"
    lga . "got current ws idx[$ws_idx]"

    lga . "focusing-tiling to unfocus dropdown"
    niri msg action focus-tiling &

    lga . "moving dropdown (id[$id]) back to $special_workspace workspace"
    niri msg action move-window-to-workspace --window-id "$id" "$special_workspace" &

    lga . "focusing previous ws"
    niri msg action focus-workspace "$ws_idx" &
}

function is_shown() {
    if [ -z "${1:-}" ]; then lge "is_shown called without name, exiting..."; finish 1; fi
    name="$1"; lga F "is_shown, name[$name]"
    
    special_ws_id="$(niri msg --json workspaces | jq -r ".[] | select(.name == \"$special_workspace\") | .id")"
    if [ -z "$special_ws_id" ]; then lga . "id of special_workspace[$special_workspace] is not found, so no dropdowns are open" ; return 1; fi

    cfg_app_id="$(config "$name" "app_id")"
    window_ws_id="$(niri msg --json windows | jq -r ".[] | select(.app_id == \"$cfg_app_id\") | .workspace_id")"

    lga . "got window ws id[$window_ws_id] & special ws id[$special_ws_id]"

    # if the dropdown is show, it must be on some ws that's not the special one
    [[ "$window_ws_id" != "$special_ws_id" ]] && [[ -n "$window_ws_id" ]]
}

lga I "processing cmd line arguments"
arg_name=""
flag_init=0
flag_kill=0
flag_show=0
flag_hide=0
flag_forget=0

flag_dump=0

while [ -n "${1:-}" ]; do
    case "$1" in
        "--init"|"-i") flag_init=1; lga . "flag_init[$flag_init]" ;;
        "--kill"|"-k") flag_kill=1; lga . "flag_kill[$flag_kill]" ;;
        "--dump"|"-d") flag_dump=1; lga . "flag_dump[$flag_dump]" ;;
        "--show"|"-s") flag_show=1; lga . "flag_show[$flag_show]" ;;
        "--hide"|"-h") flag_hide=1; lga . "flag_hide[$flag_hide]" ;;
        "--forget"|"-f") flag_forget=1; lga . "flag_forget[$flag_forget]" ;;
        "-"*) lge "unrecognized command line flag[$1]"; finish 1 ;;
        *) # setting name of dropdown to operate on
            if [ -n "$arg_name" ]; then
                lge "encountered two name arguments when only one is legal: 1[$arg_name] and 2[$1]"
                finish 1
            fi
            arg_name="$1" ; lga . "arg_name[$arg_name]" ;;
    esac

    shift
done

if (( flag_dump )); then
    lga . "dumping info"

    echo "last:        '$(cat "$last_file")'"
    echo "actual_last: '$(cat "$actual_last_file")'"

    echo ""

    longest_app_id=0
    longest_name=0

    while IFS= read -r name; do
        app_id_len="$(config "$name" app_id | wc -c)";
        name_len="${#name}"

        [[ $app_id_len -gt $longest_app_id ]] && longest_app_id=$app_id_len
        [[ $name_len -gt $longest_name ]] && longest_name=$name_len
    done <<< "$(cat ~/.config/niri/niridrop.json | jq -r '.windows | to_entries | .[].key')"

    col_def="\033[0m"
    col_red="\033[0;31m"
    col_grn="\033[0;32m"

    while IFS= read -r name; do
        app_id="$(config "$name" app_id)"
        win_id="$(niri msg --json windows | jq -r ".[] | select(.app_id == \"$app_id\").id")"

        if [[ -z "$win_id" ]];
        then printf "${col_red}closed:${col_def} %-${longest_name}s | app_id: %-${longest_app_id}s\n" "$name" "$app_id"
        else printf "${col_grn}opened:${col_def} %-${longest_name}s | app_id: %-${longest_app_id}s | win_id[%s]\n" "$name" "$app_id" "$win_id"
        fi
    done <<< "$(cat ~/.config/niri/niridrop.json | jq -r '.windows | to_entries | .[].key')"

    finish
fi

if (( flag_kill || flag_init )); then
    lga . "kill: going thru all app_ids and closing matches"

    while IFS= read -r app_id; do
        lga I "processing app_id[$app_id]"

        win_id="$(niri msg --json windows | jq -r ".[] | select(.app_id == \"$app_id\").id")"

        if [[ -z "$win_id" ]]; then
            lga . "app_id[$app_id] didn't match any window"
        else
            lga . "closing window[$win_id]"
            niri msg action close-window --id "$win_id" &
        fi
    done <<< "$(cat ~/.config/niri/niridrop.json | jq -r '.windows | to_entries | .[].value.app_id')"
fi

if (( flag_init )); then
    lga . "init: clearing last[$last_file], and actual_last[$actual_last_file]"
    echo -n > "$last_file"
    echo -n > "$actual_last_file"

    ws_idx="$(niri msg --json workspaces | jq -r "first(.[] | select(.is_active)).idx")"
    lga . "saving workspace idx[$ws_idx] to focus back"


    lga . "init: spawning all non-lazy dropdowns"
    jq -r ".windows | to_entries[] | select(.value.lazy | not).key" "$config_file" |
        while IFS= read -r name; do
            lga . "init: spawning [$name]"
            spawn_window "$name" > /dev/null

            # lock focus on this workspace
            sleep 0.01 && niri msg action focus-workspace "$ws_idx" &
            sleep 0.02 && niri msg action focus-workspace "$ws_idx" &
            sleep 0.03 && niri msg action focus-workspace "$ws_idx" &
            sleep 0.04 && niri msg action focus-workspace "$ws_idx" &
            sleep 0.05 && niri msg action focus-workspace "$ws_idx" &
        done
fi

(( flag_init || flag_kill )) && finish

# main dropdown logic/functionality

arg_actual_last="$(get_actual_last)"
lga I "main functionality with name[$arg_name], actual_last[$arg_actual_last] show[$flag_show], hide[$flag_hide]"

if [[ -n "$arg_actual_last" ]] && is_shown "$arg_actual_last"; then
    if [[ -n "$arg_name" ]] && [[ "$arg_name" != "$arg_actual_last" ]]; then

        lga I "last is open, replacing with new drop"
        if (( flag_hide ))
        then lga . "flag_hide was set, doing nothing"; else
            hide_window "$arg_actual_last"
            show_window "$arg_name"
        fi

    else

        lga I "last is open & we have nothing new to open, closing last"
        if (( flag_show ))
        then lga . "flag_show was set, doing nothing"; else
            hide_window "$arg_actual_last"
        fi

    fi
else
    if [[ -n "$arg_name" ]]; then

        lga I "nothing is currently open, just opening request"
        if (( flag_hide ))
        then lga . "flag_hide was set, doing nothing"; else
            show_window "$arg_name"
        fi

    else
        arg_last="$(get_last)"

        lga . "got last[$arg_last]"

        if [[ -n "$arg_last" ]]; then
            lga I "nothing is currently open, just opening last"
            if (( flag_hide ))
            then lga . "flag_hide was set, doing nothing"; else
                show_window "$arg_last"
            fi
        else
            lga I "no name to open & no last window, doing nothing"
        fi
    fi
fi

finish

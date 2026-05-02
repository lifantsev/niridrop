export LGSTEM=niridrop

config_file="$XDG_CONFIG_HOME/niri/niridrop.json"
registry_file="$XDG_STATE_HOME/niridrop/registry"
last_file="$XDG_STATE_HOME/niridrop/last"
actual_last_file="$XDG_STATE_HOME/niridrop/actual_last"

mkdir -p "$XDG_STATE_HOME/niridrop" &>/dev/null
touch "$registry_file" &>/dev/null
touch "$last_file" &>/dev/null
touch "$actual_last_file" &>/dev/null

special_workspace="$(cat "$config_file" | jq -r .workspace)"
[[ "$special_workspace" == "null" ]] && special_workspace=dropdown
[[ -z "$special_workspace" ]] && special_workspace=dropdown

lg start

function finish() {
    lg finish
    if [[ -n "${1:-}" ]];
    then exit 1
    else exit 0
    fi
}

function config() {
    if [ -z "${1:-}" ]; then lg E "config called without window name, exiting..."; finish 1; fi
    if [ -z "${2:-}" ]; then lg E "config called without option name, exiting..."; finish 1; fi

    cat "$config_file" | jq -r ".windows.$1.$2"
}

function set_last() {
    if [ -z "${1:-}" ]; then lg E "set_last called without dropdown name, exiting..."; finish 1; fi

    name="$1"; lg F "set_last, name[$name], flag_forget[$flag_forget]"

    (( ! flag_forget )) && echo "$name" > "$last_file"
    echo "$name" > "$actual_last_file"
}

function get_last() { cat "$last_file"; }
function get_actual_last() { cat "$actual_last_file"; }

function registry_contains() {
    if [ -z "${1:-}" ]; then lg E "registry_contains called without dropdown name, exiting..."; finish 1; fi

    name="$1"; lg F "registry_contains, name[$name]"

    grep -q "^$name " "$registry_file"
}

function registry_add() {
    if [ -z "${1:-}" ]; then lg E "registry_add called without dropdown name, exiting..."; finish 1; fi
    if [ -z "${2:-}" ]; then lg E "registry_add called without window id, exiting..."; finish 1; fi

    name="$1"; id="$2"; lg F "registry_add, name[$name] id[$id]"

    if registry_contains "$name"; then
        lg . "registry already has name[$name], returning..."; return 0
    fi

    echo "$name $id" >> "$registry_file"
}

function registry_query() {
    if [ -z "${1:-}" ]; then lg E "registry_query called without dropdown name, exiting..."; finish 1; fi

    name="$1"; lg F "registry_query, name[$name]"

    if registry_contains "$name"; then
        id="$(awk "/^$name / { print \$NF }" "$registry_file")"

        lg . "checking that dropdown[$name] with id[$id] is actually open"

        window_info="$(niri msg --json windows | jq -r ".[] | select(.id == $id)")"

        if [[ -n "$window_info" ]] && [[ "$window_info" != "null" ]]; then
            lg . "the window is open, returning id[$id]"
            echo "$id"
            return 0
        fi

        lg I "the dropdown[$name] with id[$id] seems to no longer be open, removing it from registry"

        sed -i "/^$name / d" "$registry_file"
    fi

    if ! registry_contains "$name"; then
        lg . "registry does not contain name[$name], spawning the window..."
        spawn_window "$name"

        if ! registry_contains "$name"; then
            lg E "registry still does not contain name[$name], spawn_window must have failed, exiting..."; finish 1
        fi
    fi

    id="$(awk "/^$name / { print \$NF }" "$registry_file")"

    lg . "fetched id[$id] from registry, returning"

    echo "$id"
}

function spawn_window() {
    if [ -z "${1:-}" ]; then lg E "spawn_window called without name, exiting..."; finish 1; fi

    name="$1"; lg F "spawn_window, name[$name]"

    app_id="$(config "$name" "app_id")"
    cmd="$(config "$name" "cmd")"

    if [ "$app_id" == "null" ]; then lg E "name[$name] doesn't have a 'app_id' defined, exiting..."; finish 1; fi
    if [ "$cmd" == "null" ]; then lg E "name[$name] doesn't have a 'cmd' defined, exiting..."; finish 1; fi

    lg . "got app_id[$app_id] cmd[$cmd]"

    focused_id="$(niri msg --json focused-window | jq -r .id)"
    lg . "saved id[$focused_id] to focus back onto after opening '$name'"

    niri msg action spawn-sh -- "$cmd" &

    niri msg --json event-stream |
    while read -r line; do
        case $line in
            '{"WindowOpenedOrChanged":'*)
            win_app_id="$(echo "$line" | jq -r .WindowOpenedOrChanged.window.app_id)"
            win_id="$(echo "$line" | jq -r .WindowOpenedOrChanged.window.id)"

            lg . "captured new window with app_id[$win_app_id], id[$win_id]"

            if [ "$win_app_id" == "$app_id" ]; then
                lg . "matched, registering id[$win_id], returning focus to old id[$focused_id], & returning"
                registry_add "$name" "$win_id"
                sleep 0.01 && niri msg action focus-window --id "$focused_id" &
                return 0
            fi
            ;;
        esac
    done
}

function show_window() {
    if [ -z "${1:-}" ]; then lg E "show_window called without name, exiting..."; finish 1; fi
    name="$1"; lg F "show_window, name[$name]"

    id="$(registry_query "$name")"

    set_last "$name"

    workspace="$(niri msg --json workspaces | jq -r "first(.[] | select(.is_active)).idx")"

    lg . "moving win[$id] to current workspace[$workspace]"
    niri msg action move-window-to-workspace --window-id "$id" "$workspace"

    lg . "focusing window[$id]"
    niri msg action focus-window --id "$id"
}

function hide_window() {
    if [ -z "${1:-}" ]; then lg E "hide_window called without name, exiting..."; finish 1; fi
    name="$1"; lg F "hide_window, name[$name]"

    id="$(registry_query "$name")"

    lg . "focusing-tiling to unfocus dropdown"
    niri msg action focus-tiling # NOTE this doesnt work if there is no tiled window on ws

    lg . "moving dropdown (id[$id]) back to $special_workspace workspace"
    niri msg action move-window-to-workspace --window-id "$id" "$special_workspace"
}

function is_open() {
    if [ -z "${1:-}" ]; then lg E "is_open called without name, exiting..."; finish 1; fi
    name="$1"; lg F "is_open, name[$name]"

    id="$(registry_query "$name")"

    workspace="$(niri msg --json windows | jq -r "first(.[] | select(.id == $id)) | .workspace_id")"
    lg . "dropdown is currently on workspace[$workspace]"

    name="$(niri msg --json workspaces | jq -r "first(.[] | select(.id == $workspace)) | .name")"
    lg . "workspace[$workspace] has name[$name]"

    ! [[ "$name" == "$special_workspace" ]]
}

lg I "processing cmd line arguments"
arg_name=""
flag_init=0
flag_kill=0
flag_show=0
flag_hide=0
flag_forget=0

flag_dump=0

while [ -n "${1:-}" ]; do
    case "$1" in
        "--init"|"-i") flag_init=1; lg . "flag_init[$flag_init]" ;;
        "--kill"|"-k") flag_kill=1; lg . "flag_kill[$flag_kill]" ;;
        "--dump"|"-d") flag_dump=1; lg . "flag_dump[$flag_dump]" ;;
        "--show"|"-s") flag_show=1; lg . "flag_show[$flag_show]" ;;
        "--hide"|"-h") flag_hide=1; lg . "flag_hide[$flag_hide]" ;;
        "--forget"|"-f") flag_forget=1; lg . "flag_forget[$flag_forget]" ;;
        "-"*) lg E "unrecognized command line flag[$1]"; finish 1 ;;
        *) # setting name of dropdown to operate on
            if [ -n "$arg_name" ]; then
                lg E "encountered two name arguments when only one is legal: 1[$arg_name] and 2[$1]"
                finish 1
            fi
            arg_name="$1" ; lg . "arg_name[$arg_name]" ;;
    esac

    shift
done

if (( flag_show && flag_hide ))
then lg E "flag_show and flag_hide are both set, this is illegal (if allowed it would just cause nothing to happen), exiting"; finish 1; fi

if (( flag_kill && flag_init ))
then lg E "flag_kill and flag_init are both set, this is illegal"; finish 1; fi

if (( (flag_show || flag_hide) && (flag_kill || flag_init) ));
then lg E "the show/hide flags are incompatible with the kill/init flags, can't use both simultaneously, exiting"; finish 1; fi

if (( flag_dump && (flag_show||flag_hide||flag_kill||flag_init)))
then lg E "the dump flag must be the only one passed"; finish 1; fi

if (( flag_dump )); then
    lg . "dump: printing contents of registry[$registry_file], last[$last_file], actual_last[$actual_last_file]"

    echo "# registry[$registry_file] '''"
    cat "$registry_file"
    echo "'''"

    echo

    echo "# last[$last_file] '''"
    cat "$last_file"
    echo "'''"

    echo

    echo "# actual_last[$actual_last_file] '''"
    cat "$actual_last_file"
    echo "'''"

    finish
fi

if (( flag_init )); then
    lg . "init: clearing registry[$registry_file], last[$last_file], and actual_last[$actual_last_file]"
    echo -n > "$registry_file"
    echo -n > "$last_file"
    echo -n > "$actual_last_file"

    finish
fi

if (( flag_kill )); then
    lg . "kill: closing all currently registered windows"

    while IFS= read -r line; do
        name="${line%% *}"
        id="${line##* }"

        if [[ -z "$name" ]];
        then lg . "malformed registry line[$line]: name[$name] empty, skipping"; continue; fi

        if ! [[ "$id" =~ ^[0-9]+$ ]];
        then lg . "malformed registry line[$line]: id[$id] not numeric, skipping"; continue; fi

        cfg_app_id="$(config "$name" "app_id")"

        if [[ -z "$name" ]] || [[ "$name" == "null" ]];
        then lg . "malformed registry line[$line]: config does not contain an app_id[$cfg_app_id] for the name[$name], skipping"; continue; fi

        win_app_id="$(niri msg --json windows | jq -r "first(.[] | select(.id == $id)) | .app_id")"

        if [[ "$win_app_id" == "null" ]];
        then lg . "malformed registry line[$line]: currently window with id[$id] has null app_id (registry is likely stale, window has probably been closed), skipping"; continue; fi

        if [[ "$cfg_app_id" != "$win_app_id" ]];
        then lg . "malformed registry line[$line]: configured app_id[$cfg_app_id] for name[$name] does not match current app_id[$win_app_id] of window with id[$id] (registry is likely stale), skipping"; continue; fi

        lg . "closing window with name[$name], id[$id], app_id[$win_app_id]"
        niri msg action close-window --id "$id"
    done < "$registry_file"

    lg . "kill: clearing registry file[$registry_file]"
    echo -n > "$registry_file"

    finish
fi

# main dropdown logic/functionality

arg_last="$(get_last)"
arg_actual_last="$(get_actual_last)"
lg I "main functionality with name[$arg_name], last[$arg_last], actual_last[$arg_actual_last] show[$flag_show], hide[$flag_hide]"

if [[ -n "$arg_actual_last" ]] && is_open "$arg_actual_last"; then
    if [[ -n "$arg_name" ]] && [[ "$arg_name" != "$arg_actual_last" ]]; then

        lg I "last is open, replacing with new drop"
        if (( flag_hide ))
        then lg . "flag_hide was set, doing nothing"; else
            hide_window "$arg_actual_last"
            show_window "$arg_name"
        fi

    else

        lg I "last is open & we have nothing new to open, closing last"
        if (( flag_show ))
        then lg . "flag_show was set, doing nothing"; else
            hide_window "$arg_actual_last"
        fi

    fi
else
    if [[ -n "$arg_name" ]]; then

        lg I "nothing is currently open, just opening request"
        if (( flag_hide ))
        then lg . "flag_hide was set, doing nothing"; else
            show_window "$arg_name"
        fi

    elif [[ -n "$arg_last" ]]; then

        lg I "nothing is currently open, just opening last"
        if (( flag_hide ))
        then lg . "flag_hide was set, doing nothing"; else
            show_window "$arg_last"
        fi

    else
        lg I "no name to open & no last window, doing nothing"
    fi
fi

finish

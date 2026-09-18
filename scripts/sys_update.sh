#!/usr/bin/env bash
# sys_update.sh — system update helper for the QuickShell bar (bash/zsh compatible)
#
# Usage:
#   sys_update.sh check [--plain] [--timeout N]   check for pending updates
#   sys_update.sh update                          spawn a terminal, guided update
#   sys_update.sh run-update                      guided update in this terminal
#   sys_update.sh session                         0 if a session is live, else 1
#
# check mode:
#   stdout : JSON  {"updates":true,"total":7,"repo":5,"aur":2,"error":null}
#            --plain prints just "true" / "false" (or "error")
#   exit   : 0 -> updates available   (true)
#            1 -> no updates          (false)
#            2 -> error (no connection, sync failure, ...)
#
# Env:
#   SYS_UPDATE_TIMEOUT  check timeout in seconds (default 60)
#   TERMINAL            terminal emulator to use for update mode

# --- shell compatibility -----------------------------------------------------
if [ -n "${ZSH_VERSION:-}" ]; then
    setopt SH_WORD_SPLIT NO_NOMATCH 2>/dev/null
fi

TIMEOUT="${SYS_UPDATE_TIMEOUT:-60}"
WIN_TITLE="sys-update"
LOCK="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/sys_update.lock"

# Absolute path to this script, symlinks resolved, so update mode can re-exec
# itself from inside the spawned terminal no matter how it was invoked.
SELF=$(readlink -f "$0" 2>/dev/null)
if [ -z "$SELF" ]; then
    SELF="$0"
    case "$SELF" in
        /*) ;;
        *)  SELF="$PWD/$SELF" ;;
    esac
fi

# Filled in by check_repo / check_aur
REPO_COUNT=0; REPO_PKGS=''
AUR_COUNT=0;  AUR_PKGS=''

# --- colors ------------------------------------------------------------------
if [ -t 1 ]; then
    C_RESET=$'\033[0m';   C_BOLD=$'\033[1m';     C_DIM=$'\033[2m'
    C_RED=$'\033[31m';    C_GREEN=$'\033[32m';   C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m';   C_MAGENTA=$'\033[35m'; C_CYAN=$'\033[36m'
    C_WHITE=$'\033[97m';  C_BOLD_BLACK=$'\033[1;90m';
    BG_BLUE=$'\033[44m';  BG_RED=$'\033[41m'
else
    C_RESET=; C_BOLD=; C_DIM=; C_RED=; C_GREEN=; C_YELLOW=
    C_BLUE=; C_MAGENTA=; C_CYAN=; C_WHITE=; C_BOLD_BLACK=; BG_BLUE=; BG_RED=
fi

# =============================================================================
#  SHARED CHECK LOGIC
# =============================================================================

# seconds left of the global budget (never returns less than 1)
remaining() {
    _left=$(( TIMEOUT - SECONDS ))
    [ "$_left" -lt 1 ] && _left=1
    echo "$_left"
}

count_lines() {
    if [ -z "$1" ]; then
        echo 0
    else
        printf '%s\n' "$1" | grep -c '[^[:space:]]'
    fi
}

# Official repositories. Sets REPO_COUNT / REPO_PKGS, returns 0 ok / 1 error.
check_repo() {
    REPO_COUNT=0; REPO_PKGS=''

    if command -v checkupdates >/dev/null 2>&1; then
        REPO_PKGS=$(timeout "$(remaining)" checkupdates 2>/dev/null)
        _rc=$?
        # checkupdates: 0 = updates found, 2 = none, anything else = failure
        if [ "$_rc" -eq 0 ] || [ "$_rc" -eq 2 ]; then
            REPO_COUNT=$(count_lines "$REPO_PKGS")
            return 0
        fi
        REPO_PKGS=''
        return 1
    fi

    # No pacman-contrib: do what checkupdates does — sync a private database as
    # a normal user. pacman 7 sandboxes the download and wants to drop to the
    # 'alpm' user, which only works under fakeroot with the sandbox disabled;
    # the plain call is kept as a fallback for older pacman.
    _db=$(mktemp -d "${TMPDIR:-/tmp}/sys_update.XXXXXX") || return 1
    [ -L "$_db/local" ] || ln -s /var/lib/pacman/local "$_db/local" 2>/dev/null

    _synced=1
    if command -v fakeroot >/dev/null 2>&1; then
        timeout "$(remaining)" fakeroot -- \
            pacman -Sy --dbpath "$_db" --logfile /dev/null --disable-sandbox \
            >/dev/null 2>&1 && _synced=0
    fi
    if [ "$_synced" -ne 0 ]; then
        timeout "$(remaining)" \
            pacman -Sy --dbpath "$_db" --logfile /dev/null \
            >/dev/null 2>&1 && _synced=0
    fi
    if [ "$_synced" -ne 0 ]; then
        rm -rf "$_db"
        return 1
    fi

    REPO_PKGS=$(pacman -Qu --dbpath "$_db" 2>/dev/null | grep -v '\[ignored\]$')
    rm -rf "$_db"
    REPO_COUNT=$(count_lines "$REPO_PKGS")
    return 0
}

# AUR. Sets AUR_COUNT / AUR_PKGS, returns 0 ok / 1 error.
check_aur() {
    AUR_COUNT=0; AUR_PKGS=''

    _helper=''
    for _h in yay paru; do
        command -v "$_h" >/dev/null 2>&1 && { _helper="$_h"; break; }
    done
    [ -z "$_helper" ] && return 0

    _err=$(mktemp "${TMPDIR:-/tmp}/sys_update_err.XXXXXX")
    AUR_PKGS=$(timeout "$(remaining)" "$_helper" -Qua 2>"$_err")
    _rc=$?
    _errtxt=$(cat "$_err" 2>/dev/null)
    rm -f "$_err"

    # "nothing to upgrade" is a non-zero exit with no output, so only treat it
    # as a failure when the helper actually complained (or we ran out of time).
    if [ "$_rc" -eq 124 ] || { [ "$_rc" -ne 0 ] && [ -z "$AUR_PKGS" ] && [ -n "$_errtxt" ]; }; then
        AUR_PKGS=''
        return 1
    fi

    AUR_COUNT=$(count_lines "$AUR_PKGS")
    return 0
}

# =============================================================================
#  CHECK MODE
# =============================================================================

mode_check() {
    _plain=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --plain)   _plain=1 ;;
            --json)    _plain=0 ;;
            --timeout) shift; TIMEOUT="$1" ;;
        esac
        shift
    done

    SECONDS=0
    _err_src=''

    check_repo || _err_src='repo'
    check_aur  || _err_src="${_err_src:+$_err_src+}aur"

    # Report an error only when nothing trustworthy came back at all
    if [ "$_err_src" = 'repo+aur' ] || { [ -n "$_err_src" ] && [ "$(( REPO_COUNT + AUR_COUNT ))" -eq 0 ]; }; then
        if [ "$_plain" -eq 1 ]; then
            echo "error"
        else
            printf '{"updates":false,"total":0,"repo":0,"aur":0,"error":"check failed (%s)"}\n' "$_err_src"
        fi
        return 2
    fi

    _total=$(( REPO_COUNT + AUR_COUNT ))
    if [ "$_total" -gt 0 ]; then _updates=true; else _updates=false; fi

    if [ "$_plain" -eq 1 ]; then
        echo "$_updates"
    elif [ -n "$_err_src" ]; then
        printf '{"updates":%s,"total":%s,"repo":%s,"aur":%s,"error":"partial (%s)"}\n' \
               "$_updates" "$_total" "$REPO_COUNT" "$AUR_COUNT" "$_err_src"
    else
        printf '{"updates":%s,"total":%s,"repo":%s,"aur":%s,"error":null}\n' \
               "$_updates" "$_total" "$REPO_COUNT" "$AUR_COUNT"
    fi

    [ "$_total" -gt 0 ] && return 0
    return 1
}

# =============================================================================
#  UPDATE MODE — spawn a terminal
# =============================================================================

# 0 when an update session is already alive, 1 otherwise (clears stale locks)
session_running() {
    [ -f "$LOCK" ] || return 1
    _pid=$(cat "$LOCK" 2>/dev/null)
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
        return 0
    fi
    rm -f "$LOCK"
    return 1
}

mode_update() {
    # Never stack a second session on top of a running one
    if session_running; then
        echo "An update session is already running." >&2
        return 1
    fi

    _cmd="$SELF run-update"

    _term="${TERMINAL:-}"
    if [ -z "$_term" ]; then
        for _t in alacritty ghostty kitty foot wezterm konsole gnome-terminal xterm; do
            command -v "$_t" >/dev/null 2>&1 && { _term="$_t"; break; }
        done
    fi
    [ -z "$_term" ] && { echo "No terminal emulator found." >&2; return 1; }

    case "$(basename "$_term")" in
        alacritty)      "$_term" -t "$WIN_TITLE" -e bash -c "$_cmd" & ;;
        ghostty)        "$_term" --title="$WIN_TITLE" -e bash -c "$_cmd" & ;;
        kitty)          "$_term" --title "$WIN_TITLE" bash -c "$_cmd" & ;;
        foot)           "$_term" --title="$WIN_TITLE" bash -c "$_cmd" & ;;
        wezterm)        "$_term" start --class "$WIN_TITLE" -- bash -c "$_cmd" & ;;
        konsole)        "$_term" -p tabtitle="$WIN_TITLE" -e bash -c "$_cmd" & ;;
        gnome-terminal) "$_term" --title="$WIN_TITLE" -- bash -c "$_cmd" & ;;
        *)              "$_term" -T "$WIN_TITLE" -e bash -c "$_cmd" & ;;
    esac

    # Claim the lock straight away; run-update replaces it with its own pid
    echo $! > "$LOCK" 2>/dev/null
    return 0
}

# =============================================================================
#  RUN-UPDATE — the guided session
# =============================================================================

hr()   { printf '%s────────────────────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET"; }
ok()   { printf ' %s✔ %s%s\n'  "$C_GREEN"  "$1" "$C_RESET"; }
warn() { printf ' %s! %s%s\n'  "$C_YELLOW" "$1" "$C_RESET"; }
fail() { printf ' %s✘ %s%s\n'  "$C_RED"    "$1" "$C_RESET"; }
info() { printf '   %s%s%s\n'  "$C_DIM"    "$1" "$C_RESET"; }

banner() {
    printf '\n'
    printf '  %s%s╭────────────────────────────────────────────────╮%s\n' "$C_BOLD" "$C_CYAN" "$C_RESET"
    printf '  %s%s│         S Y S T E M   U P D A T E              │%s\n' "$C_BOLD" "$C_CYAN" "$C_RESET"
    printf '  %s%s╰────────────────────────────────────────────────╯%s\n' "$C_BOLD" "$C_CYAN" "$C_RESET"
}

step() {
    printf '\n%s%s ▶ %s%s\n' "$C_BOLD" "$C_BLUE" "$1" "$C_RESET"
    hr
}

# ask "question" -> 0 yes / 1 no (default yes, but EOF is always a no)
ask() {
    printf '\n %s%s?%s %s %s[Y/n]%s ' "$C_BOLD" "$C_MAGENTA" "$C_RESET" "$1" "$C_DIM" "$C_RESET"
    read -r _ans || { printf '\n'; return 1; }
    case "$_ans" in
        [nN]*) return 1 ;;
        *)     return 0 ;;
    esac
}

# print a package list, truncated so the survey stays readable
show_pkgs() {
    [ -z "$1" ] && return 0
    printf '%s\n' "$1" | head -12 | sed "s/^/     ${C_DIM}•${C_RESET} /"
    _n=$(count_lines "$1")
    [ "$_n" -gt 12 ] && info "... and $(( _n - 12 )) more"
    return 0
}

pause_close() {
    printf '\n%s   Press any key to close...%s' "$C_DIM" "$C_RESET"
    read -r -n1 -s 2>/dev/null || read -r _x 2>/dev/null
    printf '\n'
}

mode_run_update() {
    _rc_pac='skipped'
    _rc_aur='skipped'

    echo $$ > "$LOCK" 2>/dev/null
    trap 'rm -f "$LOCK"' EXIT INT TERM

    clear 2>/dev/null
    banner

    # --- survey -------------------------------------------------------------
    step "Looking for pending updates"
    printf '   %ssyncing package databases...%s\n' "$C_DIM" "$C_RESET"

    SECONDS=0
    TIMEOUT="${SYS_UPDATE_TIMEOUT:-60}"
    _repo_ok=1; _aur_ok=1
    check_repo && _repo_ok=0
    check_aur  && _aur_ok=0

    _repo_txt="$REPO_COUNT"; [ "$_repo_ok" -ne 0 ] && _repo_txt="?"
    _aur_txt="$AUR_COUNT";   [ "$_aur_ok"  -ne 0 ] && _aur_txt="?"

    printf '\n'
    printf '   %s%s official repos %s  %s%s%s package(s)\n' \
           "$BG_BLUE" "$C_BOLD_BLACK" "$C_RESET" "$C_BOLD" "$_repo_txt" "$C_RESET"
    show_pkgs "$REPO_PKGS"
    printf '   %s%s aur            %s  %s%s%s package(s)\n' \
           "$BG_RED" "$C_BOLD_BLACK" "$C_RESET" "$C_BOLD" "$_aur_txt" "$C_RESET"
    show_pkgs "$AUR_PKGS"

    if [ "$_repo_ok" -ne 0 ] && [ "$_aur_ok" -ne 0 ]; then
        printf '\n'
        fail "Could not reach the package servers — are you online?"
        pause_close
        return 2
    fi

    if [ "$(( REPO_COUNT + AUR_COUNT ))" -eq 0 ]; then
        printf '\n'
        ok "Everything is already up to date."
        pause_close
        return 0
    fi

    # --- pacman -------------------------------------------------------------
    step "Step 1/2 — Official repositories (pacman)"
    if [ "$REPO_COUNT" -eq 0 ] && [ "$_repo_ok" -eq 0 ]; then
        ok "Nothing to do."
    elif ask "Run ${C_BOLD}sudo pacman -Syu${C_RESET} now?"; then
        printf '\n'
        if sudo pacman -Syu; then
            _rc_pac='done'; ok "Repository packages updated."
        else
            _rc_pac='failed'; fail "pacman exited with an error."
        fi
    else
        info "Skipped."
    fi

    # --- AUR ----------------------------------------------------------------
    _helper=''
    for _h in yay paru; do
        command -v "$_h" >/dev/null 2>&1 && { _helper="$_h"; break; }
    done

    step "Step 2/2 — AUR packages (${_helper:-no helper installed})"
    if [ -z "$_helper" ]; then
        warn "No AUR helper found, skipping."
    elif [ "$AUR_COUNT" -eq 0 ] && [ "$_aur_ok" -eq 0 ]; then
        ok "Nothing to do."
    elif ask "Run ${C_BOLD}$_helper -Sua${C_RESET} now?"; then
        printf '\n'
        if "$_helper" -Sua; then
            _rc_aur='done'; ok "AUR packages updated."
        else
            _rc_aur='failed'; fail "$_helper exited with an error."
        fi
    else
        info "Skipped."
    fi

    # --- housekeeping -------------------------------------------------------
    step "Housekeeping"
    _orphans=$(pacman -Qtdq 2>/dev/null)
    if [ -n "$_orphans" ]; then
        info "orphaned packages no longer required:"
        show_pkgs "$_orphans"
        if ask "Remove them?"; then
            if printf '%s\n' "$_orphans" | xargs -r sudo pacman -Rns --noconfirm; then
                ok "Orphans removed."
            else
                fail "Could not remove orphans."
            fi
        else
            info "Left untouched."
        fi
    else
        ok "No orphaned packages."
    fi

    # --- summary ------------------------------------------------------------
    _fmt() {
        case "$1" in
            done)   printf '%sdone%s'    "$C_GREEN" "$C_RESET" ;;
            failed) printf '%sfailed%s'  "$C_RED"   "$C_RESET" ;;
            *)      printf '%sskipped%s' "$C_DIM"   "$C_RESET" ;;
        esac
    }
    printf '\n'
    hr
    printf ' %s%sSUMMARY%s\n' "$C_BOLD" "$C_CYAN" "$C_RESET"
    hr
    printf '   pacman : %s\n' "$(_fmt "$_rc_pac")"
    printf '   aur    : %s\n' "$(_fmt "$_rc_aur")"
    printf '   time   : %ss\n' "$SECONDS"

    # Running kernel vs installed kernel (6.1.2-arch1-1 <-> 6.1.2.arch1-1)
    _kern_inst=$(pacman -Q linux 2>/dev/null | awk '{print $2}')
    _kern_run=$(uname -r | sed 's/-arch/.arch/')
    if [ -n "$_kern_inst" ] && [ "$_kern_inst" != "$_kern_run" ]; then
        printf '\n'
        warn "Running kernel $_kern_run, installed $_kern_inst — reboot recommended."
    fi

    pause_close
    return 0
}

# =============================================================================
#  ENTRY POINT
# =============================================================================

usage() {
    cat <<'USAGE'
sys_update.sh — system update helper

  sys_update.sh check [--plain] [--timeout N]
      Check for pending updates. Prints JSON, or true/false with --plain.
      Exit: 0 = updates available, 1 = no updates, 2 = error.

  sys_update.sh update
      Spawn a terminal running the interactive, guided update.

  sys_update.sh run-update
      Run the guided update in the current terminal.

  sys_update.sh session
      Report whether an update session is live. Exit 0 = running, 1 = idle.

Env: SYS_UPDATE_TIMEOUT (default 60), TERMINAL
USAGE
}

_mode="${1:-check}"
[ $# -gt 0 ] && shift

case "$_mode" in
    check)            mode_check "$@"; exit $? ;;
    session)          if session_running; then echo running; exit 0; fi
                      echo idle; exit 1 ;;
    update)           mode_update "$@"; exit $? ;;
    run-update)       mode_run_update "$@"; exit $? ;;
    -h|--help|help)   usage; exit 0 ;;
    *)                usage; exit 64 ;;
esac

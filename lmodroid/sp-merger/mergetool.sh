#!/bin/bash

function gettop {
    local TOPFILE=build/soong/root.bp
    if [ -n "${TOP-}" -a -f "${TOP-}/${TOPFILE}" ] ; then
        # The following circumlocution ensures we remove symlinks from TOP.
        (cd $TOP; PWD= /bin/pwd)
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE=$PWD
            T=
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
                \cd ..
                T=`PWD= /bin/pwd -P`
            done
            \cd $HERE
            if [ -f "$T/$TOPFILE" ]; then
                echo $T
            fi
        fi
    fi
}

function aospremote {
    if [[ "$(git config --get lmo.scripts.aospremote.processed)" == 1 ]]; then
        if git config --get remote.aosp.url >/dev/null; then
            return 0
        else
            return 1
        fi
    fi
    git config lmo.scripts.aospremote.processed 1
    if git config --get remote.aosp.url >/dev/null; then
        return
    fi
    git_dir="$(git rev-parse --show-toplevel)"
    top_dir="$(gettop)"
    proj_name="$(realpath --relative-to="${top_dir}" "${git_dir}")"
    case "${proj_name}" in
        device/*|toolchain/*|kernel/*) base_url="${aosp_base_url}" ;;
        build/make) proj_name="build" ;&
        *) base_url="${aosp_base_url}platform/" ;;
    esac
    url="${base_url}${proj_name}"
    if git ls-remote -q --exit-code "${url}" "${aosp_rev}" >/dev/null 2>&1; then
        if git config --get remote.aosp.url >/dev/null; then
            old_url="$(git remote get-url aosp)"
            if ! [[ "${old_url}" == "${url}" ]]; then
                echo "Warning: AOSP remote exists with URL ${old_url} but should be ${url}, updating it..." 1>&2
                git remote set-url aosp "${url}"
            fi
        else
            git remote add aosp "${url}"
        fi
    else
        if git config --get remote.aosp.url >/dev/null; then
            echo "Warning: AOSP remote exists with URL ${url} but does not exist, removing..." 1>&2
            git remote remove aosp
        else
            echo "Warning: AOSP remote at URL ${url} does not exist" 1>&2
        fi
        return 1
    fi
}

function gerritremote {
    if [[ "$(git config --get lmo.scripts.gerritremote.processed)" == 1 ]]; then
        if git config --get remote.lmogerrit.url >/dev/null; then
            return 0
        else
            return 1
        fi
    fi
    git config lmo.scripts.gerritremote.processed 1
    if git config --get remote.lmogerrit.url >/dev/null; then
        return
    fi
    if ! projname=$(git config --get remote.lmodroid.projectname); then
        echo "Warning: Can't create gerrit remote because project name is missing." 1>&2
        return 1
    fi
    url="${lmo_base_url}${projname}"
    if git ls-remote -q --exit-code "${url}" "${lmo_rev}" >/dev/null 2>&1; then
        if git config --get remote.lmogerrit.url >/dev/null; then
            old_url="$(git remote get-url lmogerrit)"
            if ! [[ "${old_url}" == "${url}" ]]; then
                echo "Warning: Gerrit remote exists with URL ${old_url} but should be ${url}, updating it..." 1>&2
                git remote set-url lmogerrit "${url}"
            fi
        else
            git remote add lmogerrit "${url}"
        fi
    else
        if git config --get remote.lmogerrit.url >/dev/null; then
            echo "Warning: Gerrit remote exists with URL ${url} but does not exist, removing..." 1>&2
            git remote remove lmogerrit
        else
            echo "Warning: Gerrit remote at URL ${url} does not exist" 1>&2
        fi
        return 1
    fi
}

function get_aosp_tag {
    pushd $(gettop) >/dev/null
    python3 /dev/stdin <<EOF
import xml.etree.ElementTree as ET
import os
def gettag():
    root = ET.parse('.repo/manifests/default.xml').getroot()
    result = None
    for type_tag in root.findall('default'):
        if type_tag.get('remote') == 'aosp' and result is None:
            result = type_tag.get('revision')

    for type_tag in root.findall('remote'):
        if type_tag.get('name') == 'aosp' and result is None:
            result = type_tag.get('revision')

    if result is None:
        raise Exception("Cannot find AOSP tag - fix me!")
    else:
        return result

print(gettag())
EOF
    popd >/dev/null
}

function get_aosp_override_rev {
    pushd $(gettop) >/dev/null
    for i in $(find .repo/manifests/ -type f -name '*.xml'); do
        python3 /dev/stdin <<EOF
import xml.etree.ElementTree as ET
import os
def gettag():
    root = ET.parse("$i").getroot()
    is_default = False
    for type_tag in root.findall('default'):
        if type_tag.get('remote') == 'aosp':
            is_default = True
    result = None
    for type_tag in root.findall('project'):
        if type_tag.get('path') != "$1":
            continue
        if type_tag.get('remote') == 'aosp' or is_default:
            result = type_tag.get('revision')
    if result is None:
        return ""
    else:
        return result

print(gettag())
EOF
    done
    popd >/dev/null
}

function merge_one_base {
    git_dir="$(git rev-parse --show-toplevel)"
    top_dir="$(gettop)"
    proj_name="$(realpath --relative-to="${top_dir}" "${git_dir}")"
    if [ ! -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
        echo "[$proj_name] Error: Uncommited changes!" 1>&2
        return 1
    fi
    merge_name="$1"
    shift
    remote="$1"
    shift
    main_rev="$1"
    shift
    new_base_rev="$1"
    shift
    fast="$1"
    shift
    is_same=false
    is_3p=false
    if git config --get "remote.${remote}.projectname" >/dev/null; then
        is_same=true
        main_rev="$new_base_rev"
    else
        if ! git config --get "remote.lmodroid.projectname" >/dev/null; then
            is_3p=true
        fi
    fi
    if $is_same && $fast; then
        echo "[$proj_name] Notice: Nothing to do (in fast mode). Project is 'same'." 1>&3
        return
    fi
    pushd "${git_dir}" >/dev/null
    upstreams="$@"
    upstreams=( "$upstreams" )
# can be used for octopus merges, experimental / broken on conflicts, to be revisited or scrapped
#    upstreams=( $upstreams )
    usc=0
    for upstream in "${upstreams[@]}"; do
        upstream=( $upstream )
        repo start "${merge_name}_upstream${usc}" . 2>&1
        # Special case: build/make always uses single-merge path (ignores extra tags)
        if [[ "${#upstream[@]}" -gt 1 && "$proj_name" != "build/make" ]] && ! $(git rev-parse --is-shallow-repository); then
            if ! git fetch "${remote}" "${main_rev}" 2>&1; then
                echo "[$proj_name] Error: failed to fetch ${main_rev} from ${remote}!" 1>&2
                for j in $(seq 0 $usc); do
                    repo abandon "${merge_name}_upstream${j}" . 2>&1
                done
                popd >/dev/null
                return 1
            fi
            git reset --hard FETCH_HEAD -- 2>&1
            for i in "${upstream[@]}"; do
                if ! git fetch "${remote}" "$i" 2>&1; then
                    echo "[$proj_name] Error: failed to fetch ${i} from ${remote}!" 1>&2
                    for j in $(seq 0 $usc); do
                        repo abandon "${merge_name}_upstream${j}" . 2>&1
                    done
                    popd >/dev/null
                    return 1
                fi
                if ! git -c rerere.enabled=false -c user.name="LMO GerritBot" -c user.email="gerrit@libremobileos.com" merge --no-edit FETCH_HEAD -- 2>&1; then
                    echo "[$proj_name] Error: Please merge refs one by one, they are conflicting with themselves" 1>&2
                    git merge --abort 2>&1
                    git clean -fd
                    for j in $(seq 0 $usc); do
                        repo abandon "${merge_name}_upstream${j}" . 2>&1
                    done
                    popd >/dev/null
                    return 1
                fi
            done
        else
            if ! git fetch "${remote}" "${upstream[@]}" 2>&1; then
                echo "[$proj_name] Error: failed to fetch ${1} from ${remote}!" 1>&2
                for j in $(seq 0 $usc); do
                    repo abandon "${merge_name}_upstream${j}" . 2>&1
                done
                popd >/dev/null
                return 1
            fi
            git reset --hard FETCH_HEAD -- 2>&1
        fi
        ((usc++))
    done
    ((usc--))
    repo start "${merge_name}" . 2>&1
    if $is_same; then
        if ! git fetch "${remote}" "${main_rev}" 2>&1; then
            echo "[$proj_name] Error: failed to fetch ${main_rev} from ${remote}!" 1>&2
            for j in $(seq 0 $usc); do
                repo abandon "${merge_name}_upstream${j}" . 2>&1
            done
            repo abandon "${merge_name}" . 2>&1
            popd >/dev/null
            return 1
        fi
        git reset --hard FETCH_HEAD -- 2>&1
    fi
    if [[ "$usc" -gt 0 ]]; then
        allup=$(eval echo "${merge_name}"_upstream{$(seq 0 $usc|head -c -1|sed -z 's#\n#,#g')})
    else
        allup="${merge_name}_upstream${usc}"
    fi
    needmerge=false
    for up in $allup; do
        if ! git merge-base --is-ancestor "$up" HEAD; then
            needmerge=true
            break
        fi
    done
    if $needmerge; then
        markers_pre=$(grep -rHn "<<<<<<< HEAD" | cut -d: -f1-2)
        git -c rerere.enabled=false merge --no-commit $allup -- 2>&1
        for j in $(seq 0 $usc); do
            repo abandon "${merge_name}_upstream${j}" . 2>&1
        done
        git add --all
        if [[ ! -z "$(git status --porcelain=v1 2>/dev/null)" ]]; then
            echo -e "${markers_pre}" > markers_pre
            grep -rHn "<<<<<<< HEAD" | cut -d: -f1-2 > markers_post
            markers=$(grep -Fvxf markers_pre markers_post)
            rm markers_pre markers_post
            if [[ -n "${markers}" ]]; then
                commit_msg="Conflicts:
$markers"
            else
                commit_msg="No conflicts."
            fi
            git -c user.name="LMO GerritBot" -c user.email="gerrit@libremobileos.com" commit --allow-empty -F- <<EOF
Merge $@

$commit_msg
EOF
            if $is_same; then
                echo -e "[$proj_name] Warning: This 'same' repo, which may need a fork, merged with ${commit_msg,}" 1>&2
            else if $is_3p; then
                echo -e "[$proj_name] Warning: This '3p' repo, which may need a fork, merged with ${commit_msg,}" 1>&2
            else
                echo -e "[$proj_name] Information: Merged with ${commit_msg,}" 1>&4
            fi; fi
        else
            if $is_same; then
                echo "[$proj_name] Notice: This 'same' repo is up to date (empty)." 1>&3
            else if $is_3p; then
                echo "[$proj_name] Notice: This '3p' repo is up to date (empty)." 1>&3
            else
                echo "[$proj_name] Information: Nothing to do, up to date (empty)!" 1>&4
            fi; fi
            repo abandon "${merge_name}" . 2>&1
        fi
    else
        if $is_same; then
            echo "[$proj_name] Notice: This 'same' repo is up to date." 1>&3
        else if $is_3p; then
            echo "[$proj_name] Notice: This '3p' repo is up to date." 1>&3
        else
            echo "[$proj_name] Information: Nothing to do, up to date!" 1>&4
        fi; fi
        for j in $(seq 0 $usc); do
            repo abandon "${merge_name}_upstream${j}" . 2>&1
        done
        repo abandon "${merge_name}" . 2>&1
    fi
    popd >/dev/null
}

function merge_one_aosp {
    git_dir="$(git rev-parse --show-toplevel)"
    top_dir="$(gettop)"
    proj_name="$(realpath --relative-to="${top_dir}" "${git_dir}")"
    merge_name="$1"
    shift
    fast="$1"
    shift
    aosp_base="$1"
    shift
    merge_blacklist=(
        "external/openssh"
        "external/svox"
        "manifest"
        "packages/apps/DeskClock"
        "packages/apps/FMRadio"
        "packages/apps/Gallery2"
        "packages/apps/Updater"
        "packages/apps/ExactCalculator"
        "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
        "prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9"
        "prebuilts/gcc/linux-x86/x86/x86_64-linux-android-4.9"
    )
    if [[ " ${merge_blacklist[*]} " =~ " ${proj_name} " ]]; then
        echo "[$proj_name] Notice: Nothing to do. Project is blacklisted." 1>&3
        return
    fi
    if [[ -n "$(get_aosp_override_rev "${proj_name}")" ]]; then
        echo "[$proj_name] Notice: Nothing to do. Project is version-pinned." 1>&3
        return
    fi
    if ! aospremote; then
        echo "[$proj_name] Notice: Nothing to do. Project is not forked from AOSP." 1>&3
        return
    fi
    merge_one_base "${merge_name}" "aosp" "$(get_aosp_tag)" "$aosp_base" "$fast" $@
}

function merge_one {
    merge_name="$1"
    shift
    POSITIONAL_ARGS=()
    AOSP=()
    QUIET=false
    SILENT=false
    VERBOSE=false
    FAST=false
    VERYFAST=false
    AOSPBASE=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        -a|--aosp)
          AOSP+=("$2")
          if [[ ! -n "$AOSPBASE" ]]; then AOSPBASE="$2"; fi
          shift # past argument
          shift # past value
          ;;
        -A|--aosp-base) # aosp "base" branch which will be used in the manifest from now on, defaults to first new tag
          AOSPBASE="$2"
          shift # past argument
          shift # past value
          ;;
        -f|--fast) # disable 'same' repo checks (can be used as optimization if base is first tag)
          FAST=true
          shift
          ;;
        -F|--very-fast) # disable '3p' repo checks (not recommended), implies fast
          FAST=true
          VERYFAST=true
          shift
          ;;
        -v|--verbose) # enable other program's output
          VERBOSE=true
          shift
          ;;
        -q|--quiet) # disable notices
          QUIET=true
          shift
          ;;
        -s|--silent) # disable informations, implies quiet
          SILENT=true
          QUIET=true
          shift
          ;;
        -*|--*)
          echo "Unknown option: $1" 1>&2
          exit 1
          ;;
        *)
          POSITIONAL_ARGS+=("$1") # save positional arg
          shift # past argument
          ;;
      esac
    done
    set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
    if $VERBOSE && $QUIET; then VERBOSE=false; fi
    if $QUIET; then exec 3>/dev/null; else exec 3>&6; fi
    if $SILENT; then exec 4>/dev/null; else exec 4>&6; fi
    if ! $VERBOSE; then exec >/dev/null; fi
    AOSP="${AOSP[@]}"
    if [[ ! "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]]; then
        echo "Error: Not inside git worktree: $(pwd)" 1>&2
        return 1
    fi
    git_dir="$(git rev-parse --show-toplevel)"
    top_dir="$(gettop)"
    proj_name="$(realpath --relative-to="${top_dir}" "${git_dir}")"
    if ! git config --get remote.lmodroid.projectname >/dev/null && $VERYFAST; then
        echo "[$proj_name] Notice: Nothing to do (in very fast mode). Project is not from LMODroid." 1>&3
        return
    fi
    # This can be extended for futher upstreams quite trivially, however
    # some thought has to go into ways to differentiate upstreams for different
    # repos, as one repo has only one upstream but these parameters are common.
    if [[ -n "$AOSP" ]]; then
        merge_one_aosp "${merge_name}" "$FAST" "$AOSPBASE" $AOSP
    fi
}

function push_one {
    merge_name="$1"
    shift
    git_dir="$(git rev-parse --show-toplevel)"
    top_dir="$(gettop)"
    proj_name="$(realpath --relative-to="${top_dir}" "${git_dir}")"
    if [ ! -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
        echo "[$proj_name] Error: Uncommited changes!" 1>&2
        return 1
    fi
    if ! git show-ref --quiet refs/heads/"${merge_name}"; then
        # Nothing to do, project wasn't merged
        return
    fi 
    if ! git config --get remote.lmodroid.projectname >/dev/null; then
        echo "[$proj_name] Warning: Can't push this merged project, it's not from LMODroid." 1>&2
        return
    fi
    pushd "${git_dir}" >/dev/null
    if ! gerritremote; then
        echo "[$proj_name] Error: Can't upload changes - failed to create remote" 1>&2
        popd >/dev/null
        return 1
    fi
    bases=""
    udc=0
    for i in $(git show --no-patch --format="%P" HEAD); do
        if [[ -n "$bases" ]]; then
            # If this isn't the first parent, push it
            git push --quiet lmogerrit "$i":refs/upstream/"${merge_name}_upstream${udc}"
            ((udc++))
        fi
        bases="${bases}base=$i,"
    done
    ((udc--))
    # If this returns "internal error", the parent commits of merge are not known to gerrit and are too many to process for one upload
    if ! git push --quiet lmogerrit HEAD:"$(git config branch."${merge_name}".merge | sed 's#^refs/heads/#refs/for/#g')%${bases}topic=${merge_name},r=nift4@protonmail.com"; then
        echo "[$proj_name] Error: push failed" >&2
        popd >/dev/null
        return 1
    fi
    conflicts=$(git show -s --format=%b) # Take git commit message
    if [[ "$conflicts" == "Conflicts:"* ]]; then
        conflicts="${conflicts#Conflicts:$'\n'}" # Remove Conflicts: prefix
        conflicts="${conflicts%$'\n'$'\n'*}" # Remove blank line and everything after it
        conflicts=$(echo -n "$conflicts" | jq -R --slurp '{labels: {"Code-Review": "-1"}, comments: [split("\n")[] | split(":") | {"line": .[1], "path": .[0]}] | group_by(.path) | map({ key: (.[0].path), value: [.[] | {line: .line, message: "Conflict", unresolved: true}] }) | from_entries}') # Convert this to gerrit-expected JSON format ReviewInput in REST API docs
        echo -n "$conflicts" | ssh $gerrit_ssh gerrit review -p $(git config remote.lmodroid.projectname) -b $(git config branch."${merge_name}".merge) $(git rev-parse HEAD) --json # use SSH API to specify change with branch, project and commit hash, and create the command based on json read from stdin, then vote CR-1
    else
        ssh $gerrit_ssh gerrit review -p $(git config remote.lmodroid.projectname) -b $(git config branch."${merge_name}".merge) $(git rev-parse HEAD) --code-review +1 # Vote CR+1
    fi
    popd >/dev/null
}

function for_each {
    pushd $(gettop) >/dev/null
    for i in $(find .repo/projects/ -type d -name '*.git' | cut -d/ -f3- | sort | sed 's/\.git$//g'); do
        pushd "$i" >/dev/null 2>&1 || continue # if this fails, the project was deleted. repo doesn't delete .git instantly
        $@
        popd >/dev/null
    done
    popd >/dev/null
}

function merge_all {
    merge_name="$1"
    shift
    # basically logs error to variable and console
    exec 5>&1
    err=$(for_each merge_one "$merge_name" $@ 2>&1 1>&5 6>&5 | tee /dev/stderr)
    pushd $(gettop)/manifest >/dev/null
    proj_name=manifest
    if [ ! -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
        echo "[$proj_name] Error: Uncommited changes!" 1>&2
        return 1
    fi
    repo start "${merge_name}" .
    args="$@"
    AOSP=()
    AOSPBASE=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        -a|--aosp)
          AOSP+=("$2")
          if [[ ! -n "$AOSPBASE" ]]; then AOSPBASE="$2"; fi
          shift # past value
          ;;
        -A|--aosp-base) # aosp "base" branch which will be used in the manifest from now on, defaults to first new tag
          AOSPBASE="$2"
          shift # past argument
          shift # past value
          ;;
        *)
          shift
          ;;
      esac
    done
    set -- $args
    AOSP="${AOSP[@]}"
    tag="$(get_aosp_tag | cut -d/ -f3-)"
    sed -i "s#$tag#$AOSPBASE#g" default.xml
    git add --all
    git -c user.name="LMO GerritBot" -c user.email="gerrit@libremobileos.com" commit --allow-empty -F- <<EOF
Merge $AOSP

$tag -> $AOSPBASE
Command line: $@
Warnings and errors:
$err
EOF
    popd >/dev/null
}

function push_all {
    merge_name="$1"
    shift
    for_each push_one "$merge_name" $@
}

function mkmergename {
    echo -n merge_
    cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-10} | head -n 1
}

function main {
    if [[ "$1" == "merge" ]]; then
        shift # "merge"
        merge_name="$(mkmergename)"
        echo "Starting project $merge_name ..."
        if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]]; then
            merge_one "${merge_name}" $@ 6>&1
        else
            merge_all "${merge_name}" $@
        fi
        return
    fi

    if [[ "$1" == "start" ]]; then
        shift # "start"
        merge_name="$(mkmergename)"
        echo "Starting project $merge_name ..."
        if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]]; then
            merge_one "${merge_name}" $@ 6>&1
            push_one "${merge_name}"
        else
            merge_all "${merge_name}" $@
            push_all "${merge_name}"
        fi
        return
    fi

    if [[ "$1" == "push" ]]; then
        shift # "push"
        merge_name="$1"
        shift # merge_name
        if [[ ! -n "$merge_name" ]]; then
            echo "Please supply merge name."
            return
        fi
        if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]]; then
            push_one "${merge_name}"
        else
            push_all "${merge_name}"
        fi
        return
    fi
}

aosp_base_url="https://android.googlesource.com/"
aosp_rev="main" # test main branch to see if repo exists
lmo_base_url="ssh://lmo-gerritbot@gerrit.libremobileos.com:29418/"
gerrit_ssh="-p 29418 lmo-gerritbot@gerrit.libremobileos.com"
lmo_rev="thirteen"
trap "exit" INT
main $@

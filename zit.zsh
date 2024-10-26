################################################################################
# Storing Environment Variables                                                #
################################################################################

# define path where zit modules will be stored
export ZIT_HOME="${ZIT_HOME:-${ZDOTDIR:-$HOME/zit}}"


################################################################################
# Define Helper Functions                                                      #
################################################################################

# verify parameters on function call
function __zit-parameter-validation() {
    if [[ -z "${2}" ]]; then
        printf "[zit] missing arguments: %s\n" "${1}"
        return 1
    fi
    return 0
}

# clone git repository (at specific reference)
function __zit-repository-clone() {
    if [[ -n "${2}" ]]; then
        git clone --recurse-submodules --depth 1 \
            "${1}" --branch "${2}" "${3}" || {
                printf "[zit] failed to clone repository: %s\n" "${3}"
                return 1
            }
    else
        git clone --recurse-submodules --depth 1 \
            "${1}" "${3}" || {
                printf "[zit] failed to clone repository: %s\n" "${3}"
                return 1
            }
    fi
}


################################################################################
# Define Primary Functions                                                     #
################################################################################

# install plugin from url in format 'http(s)://<URL>#<BRANCH>'
function zit-install() {
    __zit-parameter-validation "plugin name" "${1}" || return 1
    __zit-parameter-validation "repository url" "${2}" || return 1

    local git_repo="${2%%#*}"
    local git_ref="${2#*#}" && [[ $git_ref != $2 ]] || git_ref=""
    if [[ -z "${git_repo}" ]]; then
        printf "[zit] invalid url: 'http(s)://<URL>#<REF>'\n" 
        return 1
    fi

    local module_dir="${ZIT_HOME}/${1}"
    if [[ ! -d "${module_dir}" ]]; then
        printf "[zit] installing: %s\n" "${1}"
        __zit-repository-clone "${git_repo}" "${git_ref}" "${module_dir}" || return 1
    fi
}

# load plugin from module directory
function zit-load() {
    __zit-parameter-validation "plugin name" "${1}" || return 1
    __zit-parameter-validation "source file" "${2}" || return 1

    source_file="${ZIT_HOME}/${1}/${2}"
    if [[ ! -f "${source_file}" ]]; then
        printf "[zit] error: source file does not exist: %s\n" "${source_file}"
        return 1
    fi

    source "${source_file}"
}

# update plugin from remote url
function zit-upgrade() {
    for i in $(command ls $ZIT_HOME); do
        pushd "$ZIT_HOME/${i}" > /dev/null || continue
        printf "[zit] updating: %s\n" "${i}"

        git pull || {
            printf "[zit] failed to pull repository: %s\n" ${i}
            continue
        }

        popd > /dev/null || continue
    done
}

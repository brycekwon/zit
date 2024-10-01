################################################################################
# Storing Environment Variables                                                #
################################################################################

# define path where zit modules will be stored
if [[ -z "${ZIT_HOME}" ]]; then
    export ZIT_HOME="${ZDOTDIR:-${HOME}}"
fi


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


################################################################################
# Define Primary Functions                                                     #
################################################################################

# install plugin from url in format 'http(s)://<URL>#<BRANCH>'
function zit-install() {
    # verify function parameters
    __zit-parameter-validation "plugin name" "${1}" || return 1
    __zit-parameter-validation "repository url" "${2}" || return 1

    # parse git url and branch
    local git_repo="${2%%#*}"
    local git_branch="${2#*#}" && [[ $git_branch != $2 ]] || git_branch=""
    if [[ -z "${git_repo}" ]]; then
        printf "[zit] invalid url: 'http(s)://<URL>#<BRANCH>'\n" 
        return 1
    fi

    # clone git repository and specified branch (if applicable)
    local module_dir="${ZIT_HOME}/${1}"
    if [[ ! -d "${module_dir}" ]]; then
        printf "[zit] installing: %s\n" "${module_dir}"
        if [[ -z "${git_branch}" ]]; then
            git clone --recurse-submodules --depth 1 \
                "${git_repo}" "${module_dir}" > /dev/null
        else
            git clone --recurse-submodules --depth 1 \
                "${git_repo}" -b "${git_branch}" "${module_dir}" > /dev/null
        fi
    fi
}

# load plugin from module directory
function zit-load() {
    __zit-parameter-validation "plugin name" "${1}" || return 1
    __zit-parameter-validation "source file" "${2}" || return 1

    # source the main function for the plugin
    source "${ZIT_HOME}/${1}/${2}" || return 1
}

# update plugin from remote url
function zit-upgrade() {
    # pull new changes into each module repository
    for i in $(command ls $ZIT_HOME); do
        pushd "$ZIT_HOME/${i}" > /dev/null || continue

        printf "[zit] updating: %s\n" "${i}"
        git pull > /dev/null

        popd > /dev/null || continue
    done
}

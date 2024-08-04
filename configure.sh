#!/bin/sh

################################################################################
# purpose:   update all system config with ansible
# args/opts: see usage (run with -h option)
################################################################################

# User Script Options
playbook_dir=''
upgrade_ansible_packages='false'
default_bootstrap_package_list='sysutils/ansible python'
bootstrap_package_list="${default_bootstrap_package_list}"
download_and_update_roles='false'
default_roles_dir='roles/ext'
roles_dir="${default_roles_dir}"
run_playbook='false'
extra_ansible_playbook_args=''

print_usage() {
  echo 'USAGE:'
  echo "  $(basename "${0}")  -h"
  echo "  $(basename "${0}")  -d <>  [-u [-p <>]]  [-r [-t <>]]  [-k [-a <>]]"
  echo 'OPTIONS:'
  echo '  -h, --help'
  echo '      print this help message'
  echo '  -d <dir>, --root-playbook-dir=<dir>'
  echo "      path to directory containing playbook.yml, no trailing '/'"
  echo '  -u, --upgrade-ansible-packages'
  echo '      upgrade ansible (required for initial run, and after sys upgrades)'
  echo '  -p <list>, --ansible-packages-list=<list>'
  echo "      list of space-separated pkgs for upgrade-ansible-packages (default: ${default_bootstrap_package_list})"
  echo '  -r, --download-and-update-roles'
  echo '      download and update all roles used by the playbook'
  echo '  -t <dir>, --roles-dir=<dir>'
  echo "      path to directory to download roles to, no trailing '/' (default: ${default_roles_dir})"
  echo '  -k, --run-playbook'
  echo '      run the playbook'
  echo '  -a <args>, --extra-ansible-playbook-args=<args>'
  echo '      extra args to pass to ansible-playbook cmd'
  echo 'EXIT CODES:'
  echo '    0  ok'
  echo '    1  usage, arguments, or options error'
  echo '    5  ansible upgrade error'
  echo '   10  ansible role or playbook error'
  echo '  255  unknown error'
  exit "${1}"
}

get_cmd_opts() {
  while getopts ':hd:up:rt:ka:-:' option; do
    case "${option}" in
      h)  handle_help ;;
      d)  handle_root_playbook_dir "${OPTARG}" ;;
      u)  handle_upgrade_ansible_packages ;;
      p)  handle_ansible_packages_list "${OPTARG}" ;;
      r)  handle_download_and_update_roles ;;
      t)  handle_roles_dir "${OPTARG}" ;;
      k)  handle_run_playbook ;;
      a)  handle_extra_ansible_playbook_args "${OPTARG}" ;;
      -)  LONG_OPTARG="${OPTARG#*=}"
          case ${OPTARG} in
            help)                           handle_help ;;
            help=*)                         handle_illegal_option_arg "${OPTARG}" ;;
            root-playbook-dir=?*)           handle_root_playbook_dir "${LONG_OPTARG}" ;;
            root-playbook-dir*)             handle_missing_option_arg "${OPTARG}" ;;
            upgrade-ansible-packages)       handle_upgrade_ansible_packages ;;
            upgrade-ansible-packages=*)     handle_illegal_option_arg "${OPTARG}" ;;
            ansible-packages-list=?*)       handle_ansible_packages_list "${LONG_OPTARG}" ;;
            ansible-packages-list*)         handle_missing_option_arg "${OPTARG}" ;;
            download-and-update-roles)      handle_download_and_update_roles ;;
            download-and-update-roles=*)    handle_illegal_option_arg "${OPTARG}" ;;
            roles-dir=?*)                   handle_roles_dir "${LONG_OPTARG}" ;;
            roles-dir*)                     handle_missing_option_arg "${OPTARG}" ;;
            run-playbook)                   handle_run_playbook ;;
            run-playbook=*)                 handle_illegal_option_arg "${OPTARG}" ;;
            extra-ansible-playbook-args=?*) handle_extra_ansible_playbook_args "${LONG_OPTARG}" ;;
            extra-ansible-playbook-args*)   handle_missing_option_arg "${OPTARG}" ;;
            '')                             break ;; # non-option arg starting with '-'
            *)                              handle_unknown_option "${OPTARG}" ;;
          esac ;;
      \?) handle_unknown_option "${OPTARG}" ;;
    esac
  done
}

handle_help() {
  print_usage 0
}

handle_root_playbook_dir() {
  playbook_dir="${1}"
}

handle_upgrade_ansible_packages() {
  upgrade_ansible_packages='true'
}

handle_ansible_packages_list() {
  bootstrap_package_list="${1}"
}

handle_download_and_update_roles() {
  download_and_update_roles='true'
}

handle_roles_dir() {
  roles_dir="${1}"
}

handle_run_playbook() {
  run_playbook='true'
}

handle_extra_ansible_playbook_args() {
  extra_ansible_playbook_args=" ${1}"
}

handle_unknown_option() {
  err_msg="unknown option \"${1}\""
  quit_err_msg_with_help "${err_msg}" 1
}

handle_illegal_option_arg() {
  err_msg="illegal argument in \"${1}\""
  quit_err_msg_with_help "${err_msg}" 1
}

print_err_msg() {
  echo 'ERROR:'
  printf "$(basename "${0}"): %s\\n\\n" "${1}"
}

quit_err_msg_with_help() {
  print_err_msg "${1} (use -h option for help)"
  exit "${2}"
}

try_silent_as_root() {
  cmd="${1}"
  err_msg="${2}"
  err_code="${3}"

  eval "${cmd}"
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    quit_err_msg_with_help "${err_msg}" "${err_code}"
  fi
}

try_silent_as_normal_user() {
  cmd="${1}"
  err_msg="${2}"
  err_code="${3}"

  normal_user_name="$(logname)"
  full_cmd="su - ${normal_user_name} -c \"${cmd}\""
  eval "${full_cmd}"
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    quit_err_msg_with_help "${err_msg}" "${err_code}"
  fi
}

check_running_as_root() {
  if [ "$(id -un)" != 'root' ]; then
    quit_err_msg_with_help "must run this script as root" 1
  fi
}

change_to_playbook_dir() {
  if [ "${playbook_dir}" = '' ]; then
    quit_err_msg_with_help "root-playbook-dir option must be specified"
  fi
  try_silent_as_root \
    "cd ${playbook_dir}" \
    "error attempting to cd to '${playbook_dir}'" 1
}

do_upgrade_ansible_packages() {
  try_silent_as_root \
    "pkg install --yes ${bootstrap_package_list}" \
    "error attempting to upgrade ansible" 5
}

do_download_and_update_roles() {
  try_silent_as_normal_user \
    "ansible-galaxy install --role-file requirements.yml --roles-path '${roles_dir}' --force-with-deps" \
    "error attempting to download roles and collections" 10
}

do_run_playbook() {
  pb_cmd="ansible-playbook"
  pb_cmd="${pb_cmd} --inventory=hosts"
  pb_cmd="${pb_cmd} --become-method=su"
  pb_cmd="${pb_cmd} --extra-vars='${extra_ansible_playbook_args}'"
  pb_cmd="${pb_cmd} playbook.yml"
  try_silent_as_root \
    "${pb_cmd}" \
    "error attempting to run playbook" 10
}

main() {
  get_cmd_opts
  check_running_as_root
  change_to_playbook_dir

  if [ "${upgrade_ansible_packages}" = 'true' ]; then
    do_upgrade_ansible_packages
  fi
  if [ "${download_and_update_roles}" = 'true' ]; then
    do_download_and_update_roles
  fi
  if [ "${run_playbook}" = 'true' ]; then
    do_run_playbook
  fi

  exit 0
}

main "$@"


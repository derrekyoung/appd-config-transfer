#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./credentials.sh

#/ Usage:
#/ Description:
#/ Examples:
#/ Options:
#/   --help: Display this help message
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

# Global Constants
readonly LOG_FILE="$(basename "$0").log"
readonly APPS_XML_FILE="source-applications.xml"

readonly URL_SUFFIX_ACTIONS="/controller/actions"
readonly URL_SUFFIX_HEALTHRULES="/controller/healthrules"
readonly URL_SUFFIX_POLICIES="/controller/policies"
readonly URL_SUFFIX_APPLICATIONS="/controller/rest/applications"

# Global Variables
APP_NAME=""
CONFIG_NAME=""
ACTION=""

# Logging
info()    { echo -e "[INFO]    $@" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo -e "[WARNING] $@" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo -e "[ERROR]   $@" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo -e "[FATAL] Line Number: ${BASH_LINENO[*]}   $@" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }


usage() {
  echo -e "USAGE: Export, import or transfer Controller configs."
  echo -e " $0 --application=NAME|all [App name or app ID. Enter all to operate on all Applications]\n"
  echo -e " Optional params:"
  echo -e "   --config=actions|healthrules|policies|all [Specify the configurations to export/import]"
  echo -e "   --action=export|import|both [Optional: specify to either export or import a config]"
  echo -e "   --help  [Print usage]"
  echo -e " "
}

main() {
  parse-args "$@"

  prepare

  if [ "$APP_NAME" == "all" ]; then
    handle-all-apps
  else
    handle-app "$APP_NAME"
  fi
}

# Prepare the tmp dir
prepare() {
  rm -rf "$LOG_FILE"

  info "Source:      $SOURCE_USERNAME@$SOURCE_ACCOUNT $SOURCE_URL"
  info "Destination: $DESTINATION_USERNAME@$DESTINATION_ACCOUNT $DESTINATION_URL\n"
}

################################################################################
# Single App
handle-all-apps() {
  info "Starting all apps. This may take a while..."
  info " "

  export-all-source-applications
  parse-source-applications
}

export-all-source-applications() {
  info "Exporting list of apps from $SOURCE_URL$URL_SUFFIX_APPLICATIONS..."
  curl --user "$SOURCE_USERNAME"@"$SOURCE_ACCOUNT":"$SOURCE_PASSWORD" "$SOURCE_URL$URL_SUFFIX_APPLICATIONS" | tee "$APPS_XML_FILE" | tee -a "$LOG_FILE"
  echo " "
}

parse-source-applications() {
  appNames=($(grep '<name' "$APPS_XML_FILE" | cut -f2 -d">" | cut -f1 -d"<"))
  info "Found ${#appNames[@]} apps: ${appNames[@]}"

  for appName in "${appNames[@]}"
  do
    handle-app "$appName"
  done
}

################################################################################
# Single App
handle-app() {
  local appName="$1"

  info "Starting $appName"

  case "$CONFIG_NAME" in
    actions)
      handle-app-actions "$appName"
      ;;
    healthrules)
      handle-app-healthrules "$appName"
      ;;
    policies)
      handle-app-policies "$appName"
      ;;
    all)
      # All configs
      info "All configurations..."
      handle-app-actions "$appName"
      handle-app-healthrules "$appName"
      handle-app-policies "$appName"
      ;;
    *)
      usage
      fatal "Required: Controller configuration type"
      ;;
  esac
}

# Parse the command line arguments
parse-args() {
  for i in "$@"
  do
    case $i in
      -a=*|--application=*)
        APP_NAME="${i#*=}"
        shift # past argument=value
        ;;
      -c=*|--config=*)
        CONFIG_NAME="${i#*=}"
        shift # past argument=value
        ;;
      -x=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
      --help*)
        usage
        exit 0
        ;;
      *)
        error "Error parsing argument $i" >&2
        usage
        exit 1
      ;;
    esac
  done

  if [[ -z "${APP_NAME// }" ]]; then
    usage
    fatal "Required: Application name or ID"
  fi

  if [[ -z "${CONFIG_NAME// }" ]]; then
    usage
    fatal "Required: Controller configuration type"
  fi

  if [[ -z "${ACTION// }" ]]; then
    usage
    fatal "Required: Action to perform"
  fi
}

################################################################################
# Actions
handle-app-actions() {
  info "==Actions=="

  local appName="$1"

  case "$ACTION" in
    export)
      export-app-actions "$appName"
      ;;
    import)
      import-app-actions "$appName"
      ;;
    both)
      export-app-actions "$appName"
      import-app-actions "$appName"
      ;;
    *)
      usage
      fatal "Required: Action to perform"
      ;;
  esac
  echo " "
}

# Export actions for a single application
export-app-actions() {
  local appName="$1"

  info "EXPORT Actions for app named, $appName"

  curl --user "$SOURCE_USERNAME"@"$SOURCE_ACCOUNT":"$SOURCE_PASSWORD" "$SOURCE_URL$URL_SUFFIX_ACTIONS/$appName" | tee "$appName"-actions.json | tee -a "$LOG_FILE"
  echo " "
}

# Import actions for a single application
import-app-actions() {
  local appName="$1"

  info "IMPORT Actions for app named, $appName, from $appName-actions.json"

  curl -X POST --user "$DESTINATION_USERNAME"@"$DESTINATION_ACCOUNT":"$DESTINATION_PASSWORD" "$DESTINATION_URL$URL_SUFFIX_ACTIONS/$appName" -F file=@"$appName"-actions.json | tee -a "$LOG_FILE"
  echo " "
}

################################################################################
# Health Rules
handle-app-healthrules() {
  info "==Health Rules=="

  local appName="$1"

  case "$ACTION" in
    export)
      export-app-healthrules "$appName"
      ;;
    import)
      import-app-healthrules "$appName"
      ;;
    both)
      export-app-healthrules "$appName"
      import-app-healthrules "$appName"
      ;;
    *)
      usage
      fatal "Required: Action to perform"
      ;;
  esac
  echo " "
}

# Export health rules for a single application
export-app-healthrules() {
  local appName="$1"

  info "EXPORT Health Rules for app named, $appName"

  curl --user "$SOURCE_USERNAME"@"$SOURCE_ACCOUNT":"$SOURCE_PASSWORD" "$SOURCE_URL$URL_SUFFIX_HEALTHRULES/$appName" | tee "$appName"-healthrules.xml | tee -a "$LOG_FILE"
  echo " "
}

# Import health rules for a single application
import-app-healthrules() {
  local appName="$1"

  info "IMPORT Health Rules for app named, $appName, from $appName-healthrules.xml"

  curl -X POST --user "$DESTINATION_USERNAME"@"$DESTINATION_ACCOUNT":"$DESTINATION_PASSWORD" "$DESTINATION_URL$URL_SUFFIX_HEALTHRULES/$appName" -F file=@"$appName"-healthrules.xml | tee -a "$LOG_FILE"
  echo " "
}

################################################################################
# Policies
handle-app-policies() {
  info "==Policies=="

  local appName="$1"

  case "$ACTION" in
    export)
      export-app-policies "$appName"
      ;;
    import)
      import-app-policies "$appName"
      ;;
    both)
      export-app-policies "$appName"
      import-app-policies "$appName"
      ;;
    *)
      usage
      fatal "Required: Action to perform"
      ;;
  esac
  echo " "
}

# Export health rules for a single application
export-app-policies() {
  local appName="$1"

  info "EXPORT Policies for app named, $appName"

  curl --user "$SOURCE_USERNAME"@"$SOURCE_ACCOUNT":"$SOURCE_PASSWORD" "$SOURCE_URL$URL_SUFFIX_POLICIES/$appName" | tee "$appName"-policies.json | tee -a "$LOG_FILE"
  echo " "
}

# Import health rules for a single application
import-app-policies() {
  local appName="$1"

  info "IMPORT Policies for app named, $appName, from $appName-policies.json"

  curl -X POST --user "$DESTINATION_USERNAME"@"$DESTINATION_ACCOUNT":"$DESTINATION_PASSWORD" "$DESTINATION_URL$URL_SUFFIX_POLICIES/$appName" -F file=@"$appName"-policies.json | tee -a "$LOG_FILE"
  echo " "
}

################################################################################

# Final function to be execution whether success or failure exit
cleanup() {
  info "Finished."
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap cleanup EXIT
    main "$@"
fi

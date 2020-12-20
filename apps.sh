#!/bin/sh
# Author: Burak Karaduman <burakkaradumann@gmail.com>
# Usage: To list apps -> 'sh apps.sh'
# Usage: To into shell-> 'sh apps.sh <app_name>'
# Usage: To tail logs -> 'sh apps.sh <app_name> logs'


if [[ "$(echo $1 | tr '[:upper:]' '[:lower:]')" == *"help"* ]]; then
    echo ""
    echo "Usages:"
    echo -e "\tTo list apps -> 'sh apps.sh'"
    echo -e "\tTo into shell-> 'sh apps.sh <app_name>'"
    echo -e "\tTo tail logs -> 'sh apps.sh <app_name> logs'"
    echo ""
    exit 0
fi



instance_name=$1
IFS=$'\n'

WHITE='\033[1;37m'
RESET='\033[0m'

if [ -z $instance_name ]; then
    pods=$(kubectl get pods -A -l apps.isc.ibm.com/app-type=app -L app.kubernetes.io/instance | sed '1d')
    OUTPUT="APP_NAME,POD_NAME,CONTAINER_STATUS,CIRCUITS_STATUS,AGE\n"
    for pod in $pods
    do
        status=$(echo $pod | awk '{print $4}')
        namespace=$(echo $pod | awk '{print $1}')
        podname=$(echo $pod | awk '{print $2}')
        age=$(echo $pod | awk '{print $6}')
        name=$(echo $pod | awk '{print $7}')
        output=$(kubectl exec -it -n $namespace $podname -- pgrep -f resilient-circuits 2> /dev/null)
        if [[ ! -z $output ]]
        then
            OUTPUT+="$name,$podname,$status,Running,$age\n"
        else
            OUTPUT+="$name,$podname,$status,Not running,$age\n"
        fi
    done
    echo -e $OUTPUT | sed -e '$ d' | column -t -s ','
    exit 0
elif [[ "$2" = "logs" ]]; then
    for pod in $(kubectl get pods -A -l apps.isc.ibm.com/app-type=app -L app.kubernetes.io/instance | sed '1d')
    do
        name=$(echo $pod | awk '{print $7}')
        if [[ "$name" = "$instance_name" ]]; then
            namespace=$(echo $pod | awk '{print $1}')
            podname=$(echo $pod | awk '{print $2}')
            kubectl exec -it -n $namespace $podname -- tail -f /var/log/rescircuits/app.log
            exit 0
        fi
    done
else
    for pod in $(kubectl get pods -A -l apps.isc.ibm.com/app-type=app -L app.kubernetes.io/instance | sed '1d')
    do
        name=$(echo $pod | awk '{print $7}')
        if [[ "$name" = "$instance_name" ]]
        then
            namespace=$(echo $pod | awk '{print $1}')
            podname=$(echo $pod | awk '{print $2}')
            echo ""
            echo -e "${WHITE}-*-* $name *-*-${RESET}"
            echo ""
            kubectl exec -it -n $namespace $podname -- bash
            exit 0
        fi
    done
    echo -e "No such an app '${RED}$1${RESET}'"
    exit 1
fi

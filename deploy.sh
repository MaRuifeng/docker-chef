##########################################################################################
# Chef server docker container
# 1. Retrieve the docker image from DTR
# 2. Deploy it as a running Chef server container
# 

# Author:
#  Ruifeng Ma <ruifengm@sg.ibm.com>
# Date:
#  2018-Jan-16
##########################################################################################

export DTR_HOST='sla-dtr.sby.ibm.com'
export DTR_ORG='gts-tia-sdad-sla-core-dev'

ops='release:,dtr-user:,dtr-pass:'
declare {RELEASE,DTR_USER,DTR_PASS}=''

USAGE="\n\033[0;36mUsage: $0 [--release cs_<VERSION>] [--dtr-user dtr_username] [--dtr-pass dtr_password]\033[0m\n"
OPTIONS=$(getopt --options '' --longoptions ${ops} --name "$0" -- "$@")
[[ $? != 0 ]] && exit 3

eval set -- "${OPTIONS}"
while true
do
    case "${1}" in
        --release)
            RELEASE="$2"
            shift 2
            ;;
        --dtr-user)
            DTR_USER="$2"
            shift 2
            ;;
        --dtr-pass)
            DTR_PASS="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "\n\nUndefined options given!"
            echo "$*"
            echo -e "${USAGE}"
            exit 3
            ;;
    esac
done

echo -e "[$(date)]\tDeploying Chef server container ..."

docker login -u $DTR_USER -p $DTR_PASS $DTR_HOST
docker pull $DTR_HOST/$DTR_ORG/cs-image:$RELEASE

docker-compose up -d

docker volume ls 

echo -e "[$(date)]\tDeployment completed."
#!/bin/sh

# The following variables and the project_create function are required but live
# inside the dev.sh in the projects docker folder. Include this script as "source".

# declare container names for the project – tools container is started by tools command:
#
# containers="example_api example_db example_redis example_search example_worker example_web"
# container_tools="example_tools"

# declare image to perform docker build onto:
#
# images_build="example/tools example/search"

# compose containers:
#
# project_create() {
# 	links="--link cosmik_api --link cosmik_db --link cosmik_redis --link cosmik_websocket"
# 	worker_volumes="--volumes-from=cosmik_worker"
# 	docker_api="-v /var/run/docker.sock:/var/run/docker.sock"

# 	docker create --name cosmik_api $docker_api jarkt/docker-remote-api
# 	docker create --name cosmik_db -p 27017:27017 mongo
# 	docker create --name cosmik_redis redis
# 	docker create --name cosmik_websocket -p 8082:8082 cosmik/websocket:master

# 	docker create --name cosmik_worker $links -v "$(cd "$(dirname "$0")/.." || exit; pwd):/project/" --restart="on-failure" cosmik/web_dev:master php /project/console.php trigger
# 	docker create --name cosmik_websocketclient $links $worker_volumes --restart="on-failure" cosmik/web_dev:master php /project/console.php webSocketClient
# 	docker create --name cosmik_web $links $worker_volumes -p 80:80 cosmik/web_dev:master
# 	docker create -it --name cosmik_tools $links $worker_volumes $docker_api cosmik/tools:master
# }


if [ $# -lt 1 ]; then
	echo "usage: $(basename "$0") command..."
	echo ""
	echo "Commands:"
	echo "  build     Build docker images"
	echo "  create    Create docker container"
	echo "  rm        Remove docker container"
	echo "  rmi       Remove docker images"
	echo "  rmi-base  Remove base images for cosmik projects"
	echo "  start     Start containers"
	echo "  stop      Stop containers"
	echo "  kill      Kill containers"
	echo "  tools     Start and ssh into tools container"
	echo "  setup     Alias for \"build create start tools\""
	echo "  clean     Alias for \"kill rm rmi\""
	exit 1
fi

print() {
	if command -v tput > /dev/null; then
		color_default=$(tput sgr0)
		color_red=$(tput setaf 1)
		color_green=$(tput setaf 2)
		color_yellow=$(tput setaf 3)
		color_blue=$(tput setaf 4)
		color_white=$(tput setaf 7)
	fi

	case $1 in
		start)
			printf "%s%s%s" "${color_blue}" "$2" "${color_default}"
			if [ "$2" != "" ] && [ "$3" != "" ]; then
				printf " "
			fi
			echo "${color_yellow}$3${color_default}:"
		;;
		success)
			echo "${color_green}DONE: $2${color_default}"
		;;
		error)
			echo "${color_red}ERROR: $2${color_default}"
		;;
		*)
			eval "color=\${color_$1}"
			printf "%s%s%s" "${color}" "$2" "${color_default}"
		;;
	esac
}

field_position() {
	i=1
	for field in $2; do
		if [ "$1" = "$field" ]; then
			echo $i
			return 0
		fi
		i=$((i+1))
	done
	return 1
}

run_cmd() {
	print start "$1" "$2"

	if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
		print error "check parameters"
		return 1
	fi

	for field in $3; do
		if [ "$1" = "docker" ] && [ "$2" = "build" ]; then
			folder=$(cd "$(dirname "$0")" || exit; cd ..; pwd)
			dockerfile=docker/images/${field##*/}/Dockerfile
			$1 "$2" "--tag=$field" "-f=$dockerfile" "$folder"
		else
			$1 "$2" "$field" > /dev/null
		fi
		if [ $? -eq 0 ]; then
			print success "$2 $field"
		else
			print error "$2 $field failed"
		fi
	done

	echo ""
}

run_cmd_async() {
	print start "$1" "$2"

	if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
		print error "check parameters"
		return 1
	fi

	pids=""
	for field in $3; do
		$1 "$2" "$field" > /dev/null &
		pids="$pids $!"
	done

	for pid in $pids; do
		pos=$(field_position "$pid" "$pids")
		field_name=$(echo "$3" | cut -d " " -f "$pos")
		if wait "$pid"; then
			print success "$2 $field_name"
		else
			print error "$2 $field_name failed"
		fi
	done

	echo ""
}

while [ ! -z "$1" ]; do
	case $1 in
		setup)
			if [ -n "$(find "$(dirname "$0")" -name Dockerfile)" ]; then
				$0 build create start tools
			else
				$0 create start tools
			fi
		;;
		clean)
			$0 kill rm rmi
			project_clean
		;;
		build)
			run_cmd docker build "$images_build"
		;;
		create)
			print start docker "create"
			if project_create; then
				print success "create"
			else
				print error "create failed"
			fi
			echo ""
		;;
		rm)
			run_cmd_async docker rm "$containers $container_tools"
		;;
		rmi)
			run_cmd_async docker rmi "$images_build $images_live"
		;;
		rmi-base)
			run_cmd_async docker rmi "cosmik/search:master cosmik/web_dev:master cosmik/tools:master cosmik/web:master cosmik/websocket:master redis mongo jarkt/docker-remote-api"
		;;
		start)
			app_dir="$(cd "$(dirname "$0")" || exit; cd ..; pwd)/app/cache"
			rm -rf "$app_dir/config/" && rm -rf "$app_dir/content/" && rm -rf "$app_dir/templates/" && rm -rf "$app_dir/doctrine/"
			run_cmd docker start "$containers"
		;;
		stop)
			run_cmd_async docker stop "$containers $container_tools"
		;;
		kill)
			run_cmd_async docker kill "$containers $container_tools"
		;;
		tools)
			docker start -i "$container_tools"
		;;
		*)
			print error "unknown command $1"
		;;
	esac
	shift
done

exit 0

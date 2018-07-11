#!/bin/sh

containers="example_web"
container_tools="example_tools"
images_build="example/tools"
images_live="registry.csmk.it/example/web_live"

project_create() {
	docker network create example

	docker create --net example     --name example_web   -v "$(cd "$(dirname "$0")/.." || exit; pwd):/project/" -p 80:8080 cosmik/web_dev:master
	docker create --net example -it --name example_tools --volumes-from=example_web                                        example/tools
}

project_clean() {
	docker network rm example
}

source "$(dirname "$0")/librun.sh"

## The Goal
We need

 1. a virtualized development system and common shell for all developers
 2. a scalable production system with multiple web servers, database servers, and so on
 3. SSL certificates for all of our domains
 4. separated code and credentials
 5. automatic builds, unit tests and deployments

Cosmik-cicd wants to solve the requirements by serving a set of technical solutions and reproducable processes on base
of Docker.

## Preparations
We don't want to have dependencies to any services. But in fact we need domains, a git repository, a server and
a smtp server. So we have some external dependencies. But they are not deeply wired and you could choose other
providers. In this example we're using Github or Bitbucket as Git provider and Amazon AWS for the servers. Mails are
sent with Sendgrid.

#### AWS
 - Create an AWS account.
 - Create a new Key Pair by going to EC2 > NETWORK & SECURITY > Key Pairs.

Visit <https://docs.docker.com/docker-for-aws/> and select the following CloudFormation template options:

 - Enable daily resource cleanup
 - Enable Cloudwatch for container logging
 - Select storage volume type gp2 for SSD

Go to EC2 > NETWORK & SECURITY > Security Groups, select the "Manager SecurityGroup" and open the ports

 - 80 (HTTP)
 - 443 (HTTPS)
 - 5000 (Docker Registry)

For our self hosted Docker Registry we need a S3 bucket. For that, go to IAM > Policies and create the following policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::<BUCKET NAME>"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "arn:aws:s3:::<BUCKET NAME>/*"
    }
  ]
}
```
Go to IAM > Users and create a new one with the new policy attached. We get the needed values REGISTRY_STORAGE_S3_ACCESSKEY
and REGISTRY_STORAGE_S3_SECRETKEY for use in our master stackfile in credentials repository.

For last, create a new bucket where the [BUCKET NAME] is the domain name of your registry (registry.example.com).

#### Github or Bitbucket
We need at least 2 git repositories. One is for our project code and could theoretically be public.
The other one is for the deployment rules and credentials and have to be private.
Both repositories needs a configured webhook for every project to trigger the build and push process in
the cosmik-cicd application.

#### Sendgrid
It's enough to create a free developer account on <https://sendgrid.com/>.
The application is preconfigured to work with sendgrid, but you can change it by override the respecting settings
in the config.

#### Domains
We need two domains pointing to the new AWS EC2 instances:

 - registry.example.com (Docker Registry)
 - www.example.com (cosmik-cicd)

## Connect to the live system
Now we have a running Docker Swarm.

Create a SSH tunnel:
 - `ssh -i <path-to-ssh-key> -NL localhost:2374:/var/run/docker.sock docker@<ssh-host> &`

Use the tunnel:
 - `export DOCKER_HOST=localhost:2374`

Unuse the tunnel:
 - `export DOCKER_HOST=`

## Setup (or repair) production environment
Connect to the live system and build images:

 - `docker build -t csmk/cicd_web:master  --file docker/images/web/Dockerfile  $(cd "$(dirname "$0")" || exit; pwd)`
 - `docker build -t csmk/cicd_web_live:master --file docker/images/cicd/Dockerfile $(cd "$(dirname "$0")" || exit; pwd)`

Switch to credentials repository.
(TODO: description)
First create a new overlay network:

 - `docker network create --driver overlay --attachable proxy`

Now deploy the proxy and registry and the cosmik-cicd application stack.

 - `docker stack deploy cosmik_images -c cosmik_images/master.yml`
 - `docker stack deploy cicd          -c cicd/master.yml`

The application is deployed, but without certificates. Let cosmik-cicd now redeploy the same both projects:

 - `docker exec -it cicd_cicd.1.$(docker service ps -f 'name=cicd_cicd.1' cicd_cicd -q --no-trunc | head -n1) /bin/bash -c "/createEnv.sh && php /project/app/console.php startup && php /project/app/console.php deploy cosmik_images master"`
 - `docker exec -it cicd_cicd.1.$(docker service ps -f 'name=cicd_cicd.1' cicd_cicd -q --no-trunc | head -n1) /bin/bash -c "/createEnv.sh && php /project/app/console.php startup && php /project/app/console.php deploy cicd master"`

You have to configure the webhooks. URLs looks like:

On current project's repository settings:
 - https://www.example.com/cicd/buildDeploy/[PROVIDER]/[PROJECT]

On related creds repository settings:
 - https://www.example.com/cicd/updateCreds/[PROVIDER]/[PROJECT]

[PROVIDER] is "bitbucket" or "github".
[PROJECT] is "cicd" for the cosmik-cicd application and your respective project name in other cases.

## Setup development environment
Assumes you have installed Docker and already a working copy of the repository.

Open your systems hosts file and point with `docker.local` to your Docker Machine. This is usually localhost, but older
windows versions (who are not compatible with the linux kernel) need Docker Machine to run.

Go to project's "docker" folder and type

`./setup.sh`

This builds the images, creates the containers and starts them. You can undo this by typing

`./clean.sh [-k]`

Enter the consistent shell for all developers by typing

`./tools.sh`

## Project configuration

#### Main configuration
There are different places to configure the behaviour of the cosmik-cicd application. The main configuration is
in app/config.json and will override in app/config_[ENVIRONMENT].json.
These values will override with optional environment variables, prefixed with "CONF_". Example:
```json
{
	"docker": {
		"host": "api",
		"network": "proxy"
	},
	"mail": {
		"host": "",
		"port": "",
		"username": "",
		"password": "",
		"from_mail": "",
		"from_name": ""
	}
}

```
You can override a value with the environment variable "CONF_MAIL_HOST" for example.

#### Configuration in projects repository
You can place a file named "cicdconfig.json" in the main folder of your projects repository. The file looks like:
```json
{
	"build": [
		["csmk/cicd_web", "docker/images/web/Dockerfile", [
			["csmk/cicd_web_live", "docker/images/web_live/Dockerfile"],
			["csmk/cicd_web_dev", "docker/images/web_dev/Dockerfile"],
			["csmk/cicd_tools", "docker/images/tools/Dockerfile"]
		]]
	]
}
```
There is only a key "build" and the value is an array of arrays with 2 or 3 entries. The first entry is the image name to build
and the second entry is the name of the Dockerfile. The build context is the whole projects repository.
Optional you can use a third entry for dependent images.

#### Configuration in credentials repository
The projects configuration is found in the credentials repository in the file [PROJECTNAME].json.
```json
{
	"tags": {
		"master": "<STACKFILE>"
	},
	"githubSecret": "<GTHUB SECRET>",
	"repository": "<PROJECT REPOSITORY URL>",
	"dockerCreds": {
		"<DOCKER REGISTRY>": {
			"username": "<DOCKER USER ID>",
			"password": "<DOCKER USER PASSWORD>"
		}
	},
	"subscribers": {
		"<EMAIL>": "<NAME>"
	}
}
```
 - **tags**: An object where the key is the branch or tag name to react. The value is the name of the respective stackfile.
If the value is null, images will be built but not deployed.
 - **githubSecret**: A freely to defined secret string for the Github webhook.
 - **repository**: An url (with credentials) to the projects repository.
 - **dockerCreds**: An object where the key is the domain name of the Docker Registry. Use index.docker.io for the official
Docker Hub Registry. The sub object has the keys username and password. We use the first entry to push built images and all entries
to download dependent images.
 - **subscribers**: An object where the key is the email address and the value is the name of a project's participant.
Used to send status emails. On top, all of the committers will get the status email too.

## Docker images and containers

#### List of images

##### csmk/cicd_web
This is the base web server image with a ngnix installation and php-fpm.

##### csmk/cicd_web_dev
Based on csmk/cicd_web image, but with modified configuration to output error details directly to the user.

##### csmk/cicd_web_live
Based on csmk/cicd_web image. The project's source code and composer dependencies are already part of the image layers.

##### csmk/cicd_tools
Based on csmk/cicd_web image. Used to provide developers with a consistent shell. Composer and other useful tools are preinstalled here.

#### List of containers (development only)
The following containers are used in a development environment.

##### cicd_web
Based on csmk/cicd_web_dev image. The project's source code is mounted from the host system. Accessible via <http://docker.local/>.

##### cicd_tools
Based on csmk/cicd_tools image.

##### cicd_api
Based on jarkt/docker-remote-api image. Makes the Docker API available via HTTP.

#### List of services (production only)
Services are only used in production environments.

##### web
Based on csmk/cicd_web_live image.

##### api
Based on jarkt/docker-remote-api image. Makes the Docker API available via HTTP.

## Developing
The application has not a cleanup routine for containers and images, but will reuse the same names.
Only if the configuration changes they can occur orphaned containers.
In live environment they are automatically cleaned up. (See "Setup (or repair) production environment")
On development system you can run "docker system prune [-a]" manually.

#### Trigger webhooks from tools container
See bash_history for a list of curl commands to simulate Github or Bitbucket requests.

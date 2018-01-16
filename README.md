# Chef-Test
A containerized Chef server.
Configuration is available to make it run on a non-standard SSL port. 

## File Description
#### Dockerfile
Used to build up a Chef server docker image. 

#### docker-compose.yml
Used to define and run the Chef server container **chef_server**. 

#### build.sh
Used to build the chef server docker image. 

#### deploy.sh
Used to deploy the Chef server container on target host machine. Connection to the SLA Docker Trusted Registry is needed.   

#### setup.sh
Used to set up the Chef server with required configurations. User and group are created by this script. If the environment variable NON_STD_SSL is set to true, a monkey patch will be applied to make the server run on the non-standard SSL port as given.

#### startup.sh
Used to start up all services required to start a Chef server. 

## Instructions

* Download the repository
* Edit the `.evn` and `chef.env` environment variable files accordingly
* Run `build.sh` and `deploy.sh`

## Useful Commands

###### To stop the chef server containers  
`docker-compose stop`
###### To start the chef server containers 
`docker-compose start`
###### To view and trace docker logs       
`docker-compose logs`
###### To check chef server status
`docker exec -it chef_server bash -c "chef-server-ctl status"`
###### To reconfigure chef server
`docker exec -it chef_server bash -c "chef-server-ctl reconfigure"`

## Authors

* **[Ruifeng Ma](mailto:ruifengm@sg.ibm.com)** - Initial work adapted from the standard Chef server image of CCSSD.

## License

N.A.
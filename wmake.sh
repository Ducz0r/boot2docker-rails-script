#!/bin/bash
set -e

###################################
# VARIABLES
###################################
IMAGE_NAME="docker_image"
WIN_HOST_RAILS_WS=$PWD
CONTAINER_MOUNT_WS="//tmp//app"
CONTAINER_RAILS_WS="//usr//src//app"
PORT=3000

B2D_HOME=C:/"Program Files"/"Boot2Docker for Windows"
VBOX_HOME=C:/"Program Files"/Oracle/VirtualBox
FILENAME="wmake.sh"
###################################


# Show help etc.
PROCEED=0
if [ $# -eq 0 ]; then
  echo "Invalid arguments. Call '$FILENAME help' for more info."
elif [ $1 == "help" ];  then
  echo "Usage: $FILENAME COMMAND/S"
  echo ""
  echo "Windows Boot2Docker helper script. If starting from scratch, the following order of commands should be used to get you started: docker, setup, build."
  echo ""
  echo "Commands:"
  echo "    $FILENAME help	Prints out the help contents"
  echo ""
  echo "    $FILENAME bash	Starts the bash console on host computer with Docker environment configured"
  echo ""
  echo "    $FILENAME build	Installs Rails gems"
  echo ""
  echo "    $FILENAME docker	Creates the Docker image from the Dockerfile"
  echo ""
  echo "    $FILENAME setup	Sets up the Rails Docker image & Rails project"
  echo ""
  echo "    $FILENAME run	Starts the Rails server in the configured Docker container"
  echo ""
  echo "    $FILENAME cli	Starts the bash console in the configured Docker container"
  echo "			(with unison syncing which means a bit slower startup, but faster command execution)"
  echo ""
  echo "    $FILENAME cli sync	Starts the bash console in the configured Docker container"
  echo "			(without Unison syncing, fast startup but horrendously slow command execution)"
  echo ""
  echo "    $FILENAME clean	Removes the Docker image (this will also remove the downloaded packages)"
  echo ""
  echo "    $FILENAME cclean	Removes all the stopped Docker containers (cleans up some disk space)"
else
  PROCEED=1
fi

# Only continue if not help...
if [ $PROCEED -eq 1 ]; then
  cd "$B2D_HOME"

  # Copy of Boot2Docker start.sh from here on

  # clear the MSYS MOTD
  clear

  cd "$(dirname "$BASH_SOURCE")"

  ISO="$HOME/.boot2docker/boot2docker.iso"

  if [ ! -e "$ISO" ]; then
    echo 'copying initial boot2docker.iso (run "boot2docker.exe download" to update)'
    mkdir -p "$(dirname "$ISO")"
    cp ./boot2docker.iso "$ISO"
  fi

  echo 'initializing...'
  ./boot2docker.exe init
  echo

  echo 'starting...'
  ./boot2docker.exe start
  echo

  echo 'IP address of docker VM:'
  ./boot2docker.exe ip
  echo

  echo 'setting environment variables ...'
  ./boot2docker.exe shellinit | sed  's,\\,\\\\,g' # eval swallows single backslashes in windows style path
  eval "$(./boot2docker.exe shellinit 2>/dev/null | sed  's,\\,\\\\,g')"
  echo

  # Modification of original code
  cd "$VBOX_HOME"
  echo "$VBOX_HOME"
  set +e
  VBoxManage controlvm boot2docker-vm natpf1 delete "rails-server"
  set -e
  VBoxManage controlvm boot2docker-vm natpf1 "rails-server,tcp,127.0.0.1,$PORT,,$PORT"
  cd "$B2D_HOME"

  echo 'You can now use `docker` directly, or `boot2docker ssh` to log into the VM.'

  cd
  # End of copy Boot2Docker start.sh

  if [ $1 == "bash" ]; then
    exec "$BASH" --login -i
  elif [ $1 == "setup" ]; then
    exec "$BASH" --login -i -c "docker run -ti -v $WIN_HOST_RAILS_WS:$CONTAINER_MOUNT_WS -w $CONTAINER_MOUNT_WS -p $PORT:$PORT $IMAGE_NAME //bin//bash -l -c 'bundle config --local path vendor/bundle'"
  elif [[ ( $1 == "cli" ) && ( $2 == "nosync" ) ]]; then
    exec "$BASH" --login -i -c "docker run -ti -v $WIN_HOST_RAILS_WS:$CONTAINER_RAILS_WS -w $CONTAINER_RAILS_WS -p $PORT:$PORT $IMAGE_NAME //bin//bash -l"
  elif [ $1 == "cli" ]; then
    exec "$BASH" --login -i -c "docker run -ti -v $WIN_HOST_RAILS_WS:$CONTAINER_MOUNT_WS -w $CONTAINER_MOUNT_WS -p $PORT:$PORT $IMAGE_NAME //bin//bash -l -c 'sudo cp -rf $CONTAINER_MOUNT_WS $CONTAINER_RAILS_WS;sudo chmod -R 777 $CONTAINER_MOUNT_WS;sudo chmod -R 777 $CONTAINER_RAILS_WS;sudo unison $CONTAINER_MOUNT_WS $CONTAINER_RAILS_WS -perms 0 -ignorecase false -links false -ignoreinodenumbers -auto -silent -ignore \"Path vendor/bundle\" -ignore \"Path .git\" -ignore \"Path .bundle\" -repeat 1 > /dev/null & sudo chmod -R 777 $CONTAINER_RAILS_WS;cd $CONTAINER_RAILS_WS;//bin//bash'"
  elif [ $1 == "run" ]; then
    exec "$BASH" --login -i -c "docker run -ti -v $WIN_HOST_RAILS_WS:$CONTAINER_MOUNT_WS -w $CONTAINER_MOUNT_WS -p $PORT:$PORT $IMAGE_NAME //bin//bash -l -c 'rm -r tmp/pids/server.pid;sudo cp -rf $CONTAINER_MOUNT_WS $CONTAINER_RAILS_WS;sudo unison $CONTAINER_MOUNT_WS $CONTAINER_RAILS_WS -perms 0 -ignorecase false -links false -ignoreinodenumbers -auto -silent -ignore \"Path vendor/bundle\" -ignore \"Path .git\" -ignore \"Path .bundle\" -repeat 1 > /dev/null & sudo chmod -R 777 $CONTAINER_RAILS_WS;cd $CONTAINER_RAILS_WS;rails s -b 0.0.0.0 -p $PORT'"
  elif [ $1 == "build" ]; then
    # Hack for Windows: we need to build bundles inside /tmp folder (building bundles inside shared project directory doesn't work), and then copy the gems into the vendor/bundle shared folder
    exec "$BASH" --login -i -c "rm -rf $WIN_HOST_RAILS_WS/vendor/bundle;docker run -ti -v $WIN_HOST_RAILS_WS:$CONTAINER_RAILS_WS -w $CONTAINER_RAILS_WS -p $PORT:$PORT $IMAGE_NAME //bin//bash -l -c 'bundle install --path /tmp/tmp_bundle;sudo mv /tmp/tmp_bundle vendor/bundle;bundle config --local path vendor/bundle'"
  elif [ $1 == "docker" ]; then
    exec "$BASH" --login -i -c "cd $WIN_HOST_RAILS_WS;docker build -t $IMAGE_NAME ."
  elif [ $1 == "clean" ]; then
    exec "$BASH" --login -i -c "docker rmi -f $IMAGE_NAME"
  elif [ $1 == "cclean" ]; then
    exec "$BASH" --login -i -c "docker rm $(docker ps -q -f status=exited)"
  fi
fi
unset IMAGE_NAME
unset WIN_HOST_RAILS_WS
unset CONTAINER_RAILS_WS
unset PORT
unset B2D_HOME
unset VBOX_HOME
unset FILENAME
unset PROCEED

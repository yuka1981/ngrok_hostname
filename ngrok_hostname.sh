#!/bin/bash

# general setting
development_file='config/environments/development.rb'


# get ngrok public url
ngrok_url=`curl --silent http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"https:..([^"]*).*/\1/p'`

if [ "$ngrok_url" == "" ]; then
  echo -e "\n\033[1;36m ngrok service\033[m not found, please start\033[1;31m ngork service\033[m first."
  exit
fi

# create backup file of development.rb
echo "=== backup development.rb file ==="
cp $development_file $development_file.bak

# get replace_target in development.rb file
check_target=`grep "config.hosts" $development_file`
if [ $? != 0 ]; then
  echo -e "please add \033[1;31m\033[5m config.hosts << '' \033[m\033[5m in $development_file"
  exit
fi

replace_target=`cat $development_file | grep "config.hosts" | awk '{ print $3 }'`

# replace/add ngork url to development.rb file
sed -i '' -e "s/$replace_target/\"$ngrok_url\"/" $development_file

# check sed command execute successfully
if [ $? -eq 0 ]; then
  echo "=== sed command replaces correctly ==="
else
  echo "=== sed command does NOT replace correctly ==="
  exit
fi

# echo ngork public url
echo "===================================="
echo "https://$ngrok_url"
echo "===================================="

echo "======= start rails server ========"
# enable job control in shell script
set -m

# start rails server to bg
rails s &

# get jobs id 
job_id=`jobs | grep rails | awk '{print $1}' | cut -c 2`

# open chrome browser
while true; do
  sleep 1
  status_code=`curl --write-out '%{http_code}' --silent --output /dev/null http://localhost:3000`

  if [ ${status_code} -eq 200 ]; then
    open -a "Google Chrome" https://$ngrok_url
    break
  fi
done

# set rails process to fg
fg %$job_id

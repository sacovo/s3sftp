#!/bin/bash

mount_bucket() {
  bucket_name=$1
  user_name=$2
  path=$3

  mount_point="/home/$user_name/$path"

  uid=$(id -u "$user_name")
  gid=$(id -g "$user_name")

  echo "Mounting bucket $bucket_name to $mount_point"

  mkdir -p "$mount_point"

  s3fs "$bucket_name" "$mount_point" -o allow_other -o uid="$uid" -o gid="$gid"  -o url="$S3_URL" -o passwd_file="$PASSWD_FILE" -o use_path_request_style
}

create_user() {
  user=$1
  pass=$2
  uid=$3

  echo "Creating user $user, with password $pass and uid $uid"

  if id "$user" &>/dev/null; then
    echo 'user already exists'
  else
    useradd --password="$pass" --create-home --uid "$uid"  --non-unique "$user"
  fi

}

read_users() {
  while read -r user; do
    echo "$user"
    case "$user" in \#) continue ;; esac

    IFS=":" read  -r -a params <<< "$user"
    create_user "${params[@]}"
  done < /etc/s3sftp/users.conf
}

read_buckets() {
  while read -r bucket; do
    case "$bucket" in \#) continue ;; esac

    IFS=":" read -r -a params <<< "$bucket"
    mount_bucket "${params[@]}"
  done < /etc/s3sftp/buckets.conf
}

generate_keys() {

  mkdir -p /etc/ssh/keys

  if [ ! -f /etc/ssh/keys/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/keys/ssh_host_ed25519_key -N ''
  fi
  if [ ! -f /etc/ssh/keys/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/keys/ssh_host_rsa_key -N ''
  fi
}


PASSWD_FILE="${PASSWD_FILE:-/etc/s3fs_passwd}"

echo "$ACCESS_KEY:$SECRET_KEY" > "$PASSWD_FILE"
chmod 600 "$PASSWD_FILE"

generate_keys
read_users
read_buckets

mkdir -p /run/sshd

# -D: Do not detach, -e: send output to stdout
exec /usr/sbin/sshd -D -e


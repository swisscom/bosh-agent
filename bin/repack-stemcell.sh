#!/bin/bash

set -e -x

stemcell_tgz=/tmp/stemcell.tgz
stemcell_dir=/tmp/stemcell
image_dir=/tmp/image

mkdir -p $stemcell_dir $image_dir
wget -O- https://s3.amazonaws.com/bosh-core-stemcells/aws/bosh-stemcell-3312.15-aws-xen-ubuntu-trusty-go_agent.tgz > $stemcell_tgz

# Expose loopbacks in concourse container
(
  set -e
  mount_path=/tmp/self-cgroups
  cgroups_path=`cat /proc/self/cgroup|grep devices|cut -d: -f3`
  [ -d $mount_path ] && umount $mount_path && rmdir $mount_path
  mkdir -p $mount_path
  mount -t cgroup -o devices none $mount_path
  echo 'b 7:* rwm' > $mount_path/$cgroups_path/devices.allow
  umount $mount_path
  rmdir $mount_path
  for i in $(seq 0 260); do
  	mknod -m660 /dev/loop${i} b 7 $i 2>/dev/null || true
  done
)

# Repack stemcell
(
	set -e;
	cd $stemcell_dir
	tar xvf $stemcell_tgz
	(
		set -e;
		cd $image_dir
		tar xvf $stemcell_dir/image
		mnt_dir=/mnt/stemcell
		mkdir $mnt_dir
		mount -o loop,offset=32256 root.img $mnt_dir
		echo -n 0.0.`date +%s` > $mnt_dir/var/vcap/bosh/etc/stemcell_version
		cp /tmp/build/*/agent-src/out/bosh-agent $mnt_dir/var/vcap/bosh/bin/bosh-agent
		umount $mnt_dir
		tar czvf $stemcell_dir/image *
	)
	tar czvf $stemcell_tgz *
)

bosh upload-stemcell $stemcell_tgz || true

sleep 10000

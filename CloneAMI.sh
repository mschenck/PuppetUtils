#!/bin/sh

################################################################################
# Configuration Area
################################################################################
# specify s3 bucket
s3Bucket="<BUCKET NAME>"
ec2_account="<ACCOUNT NUMBER i.e. 1111-2222-3333>"

# S3 Auth details
s3AccessID="<AWS API KEY>"
s3SecretKey="<AWS SECRET KEY>"
################################################################################

if [ $# -lt 1 ]
then
    echo "Usage: CloneAMI.sh <image name> [-clean]"
    echo "  -clean: remove x.509 credentials from frozen image"
    exit 1
fi

IMAGE_NAME=$1

. /etc/profile

# Update message-of-the-day
/bin/sed "s|^Ver:[[:space:]].*$|Ver:    $IMAGE_NAME|" /etc/motd > /etc/motd.buffer
mv -f /etc/motd.buffer /etc/motd

# clear bash history
if [ -f /root/.bash_history ]; then rm /root/.bash_history; fi

# AWS key files
cert_file="/tmp/certs/cert.pem"
pk_file="/tmp/certs/private.pem"

imagePath="/tmp/image"
excludes="-e /root/.ssh/authorized_keys "

REG_AMI=false
for arg in "$@" ; do
  if [ "$arg" == "-clean" ] ; then
    excludes="$excludes -e /tmp/certs "
    /bin/echo "Removing CERTS for Production deployment"
    REG_AMI=true
  fi
done

# clean up the old stuff
if [ -f ${imagePath}/${IMAGE_NAME}.manifest.xml ]
then
        rm -rf ${imagePath}/${IMAGE_NAME}*
fi

# create an image of this system
/home/ec2/bin/ec2-bundle-vol -k $pk_file -c $cert_file -u $ec2_account --arch x86_64 -d ${imagePath} $ign_dir -p $IMAGE_NAME $excludes

# upload to S3, ignore the SSL error
/home/ec2/bin/ec2-upload-bundle --url http://s3.amazonaws.com -b $s3Bucket -m ${imagePath}/$IMAGE_NAME.manifest.xml -a $s3AccessID -s $s3SecretKey

# register newly uploaded AMI
AMI_ID=`/home/ec2/bin/ec2-register -K $pk_file -C $cert_file -a x86_64 -n ${IMAGE_NAME} ${s3Bucket}/${IMAGE_NAME}.manifest.xml | /bin/awk '{print $2}'`

if $REG_AMI ; then
    echo $AMI_ID > /opt/lime/bin/fresh_ami_id
fi

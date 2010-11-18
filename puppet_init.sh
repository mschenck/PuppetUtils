#!/bin/sh

PUPPET_SERVER="<PUPPET SERVER FQDN>"
success=0
run_count=0

while [ $success -ne 1 ] && [ $run_count -lt 5 ]; do
    puppet_output=`puppetd --test --server $PUPPET_SERVER --noop`
    echo $puppet_output | grep "Could not retrieve catalog"
    success=$?
    run_count=$[ run_count + 1 ]
    sleep 5;
done

if [ $success -eq 1 ] ; then
    # Initial puppet pull
    /usr/sbin/puppetd --test --server $PUPPET_SERVER --tags yum::base

    # Full puppet pull
    /usr/sbin/puppetd --test --server $PUPPET_SERVER
else
    echo "Puppet failed! Dying"
    exit 1
fi

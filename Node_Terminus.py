#!/usr/bin/python2.6

from boto.ec2.connection import EC2Connection
import ConfigParser
import simplejson
import logging
import base64
import sys
import re

################################################################################
# Global Variables
################################################################################
S3_CONFIG_PATH = '/etc/puppet/s3cfg'

# Handle command-line arguments
host = sys.argv[1]

################################################################################
# functions
################################################################################
def get_s3auth():
    """ Parses s3cfg file for S3 auth details
        return: ( access_key, secret_key )
    """

    try:
        logging.info( "Reading S3 config from %s" % S3_CONFIG_PATH )
        s3cfg_fp = open( S3_CONFIG_PATH, "r" )
        config = ConfigParser.ConfigParser()
        config.readfp( s3cfg_fp )
        s3cfg_fp.close()
    except Exception, e:
        logging.error( "Caught the following exception while trying to read s3cfg: " + str(e) )

    return config.get( 'default', 'access_key' ), config.get( 'default', 'secret_key' )


################################################################################
# get to work
################################################################################
def main():
    ( access_key, secret_key ) = get_s3auth()
    ec2conn = EC2Connection( access_key, secret_key )
    reservations = ec2conn.get_all_instances()

    for reservation in reservations:
        for instance in reservation.instances:
            if re.search( str(host).lower(), str(instance.private_dns_name).lower() ):
                print "classes:"

                user_data_encoded = ec2conn.get_instance_attribute(instance.id, 'userData')['userData']
                user_data_str = ""
                if user_data_encoded:
                    user_data_str = base64.b64decode( user_data_encoded )

                try:
                    user_data = simplejson.loads( user_data_str )
                    print "  - %s" % user_data['role']
                except Exception, e:
                    logging.error( str(e) )


if __name__ == "__main__":
    main()

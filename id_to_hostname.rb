module Puppet::Parser::Functions
    newfunction(:id_to_hostname, :type => :rvalue) do |args|

        if args.length != 4
            raise Puppet::ParseError, ("autoscale_id(): requires exactly 4 argument, asg name, domain prefix, instance_id, and domain suffix")
        end

        asg_name = args[0]
        prefix = args[1]
        passed_id = args[2]
        suffix = args[3]

        instances = `source /etc/profile; /home/ec2/AutoScaling/bin/as-describe-auto-scaling-groups | grep #{asg_name} | /bin/grep INSTANCE | /bin/awk '{print \$2}'`

        instance_position = 1
        instances.each do |instance|
            instance = instance.gsub("\n", "")
            if instance != passed_id
                instance_position += 1
            else
                break
            end
        end

        prefix + instance_position.to_s() + suffix
    end
end

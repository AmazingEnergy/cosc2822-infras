aws_profile ?= "cosc2825-devops01"

cfn_stack_name ?= "intro-ec2-launch"
cfn_template ?= "cfn-samples/00-intro/0-ec2-launch-001.yaml"
cfn_output_key_pair_id ?= "NewKeyPairId"

#######################################################
# Cloud Formation
#######################################################

run-cfn:
	chmod 700 ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh ${aws_profile} ${cfn_stack_name} ${cfn_template}

delete-stack:
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh ${aws_profile} ${cfn_stack_name}


#######################################################
# Helpers 
#######################################################

search-ami:
	chmod 700 ./cli/001-search-ami.sh
	./cli/001-search-ami.sh ${aws_profile}

download-key-pair:
	chmod 700 ./cli/003-get-cfn-output-keypair.sh
	./cli/003-get-cfn-output-keypair.sh ${aws_profile} ${cfn_stack_name} ${cfn_output_key_pair_id} my-key-pair.pem

my-ip:
	chmod 700 ./cli/004-get-public-ipv4.sh
	./cli/004-get-public-ipv4.sh
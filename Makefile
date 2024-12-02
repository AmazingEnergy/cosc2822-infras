aws_profile ?= "cosc2825-devops01"

cfn_stack_name ?= "intro-ec2-launch"
cfn_template ?= "cfn-samples/00-intro/0-ec2-launch-001.yaml"
cfn_output_key_pair_id ?= "NewKeyPairId"
cfn_output_key ?= ""

#######################################################
# Cloud Formation
#######################################################

deploy-stack:
	chmod 700 ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh ${aws_profile} ${cfn_stack_name} ${cfn_template}
	chmod 700 ./cli/003-get-cfn-output-keypair.sh
	./cli/003-get-cfn-output-keypair.sh ${aws_profile} ${cfn_stack_name} ${cfn_output_key_pair_id} my-key-pair.pem

delete-stack:
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh ${aws_profile} ${cfn_stack_name}

deploy-s3-website:
	shell chmod 700 ./cli/002-run-cfn.sh
	shell ./cli/002-run-cfn.sh ${aws_profile} s3-static-website cfn-samples/01-s3/0-static-website.yaml
	shell chmod 700 ./cli/007-sync-s3.sh
	./cli/007-sync-s3.sh ${aws_profile} cosc2822-group6-bucket ./cfn-samples/01-s3/website

delete-s3-website:
	chmod 700 ./cli/009-clean-s3.sh
	./cli/009-clean-s3.sh ${aws_profile} cosc2822-group6-bucket
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh ${aws_profile} s3-static-website


#######################################################
# Helpers 
#######################################################

search-ami:
	chmod 700 ./cli/001-search-ami.sh
	./cli/001-search-ami.sh ${aws_profile}

download-key-pair:
	chmod 700 ./cli/003-get-cfn-output-keypair.sh
	./cli/003-get-cfn-output-keypair.sh ${aws_profile} ${cfn_stack_name} ${cfn_output_key_pair_id} my-key-pair.pem

cfn-output:
	chmod 700 ./cli/008-get-cfn-output.sh
	./cli/008-get-cfn-output.sh ${aws_profile} ${cfn_stack_name} ${cfn_output_key}

my-ip:
	chmod 700 ./cli/004-get-public-ipv4.sh
	./cli/004-get-public-ipv4.sh
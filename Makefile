cfn_stack_name ?= "intro-ec2-launch"
cfn_template ?= "cfn-samples/00-intro/0-ec2-launch-001.yaml"


run-cfn:
	chmod 700 ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh ${cfn_stack_name} ${cfn_template}

delete-stack:
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh ${cfn_stack_name}

search-ami:
	chmod 700 ./cli/001-search-ami.sh
	./cli/001-search-ami.sh

download-key-pair:
	chmod 700 ./cli/003-get-cfn-output-keypair.sh
	./cli/003-get-cfn-output-keypair.sh ${cfn_stack_name} NewKeyPairId mykey.pem

my-ip:
	chmod 700 ./cli/004-get-public-ipv4.sh
	./cli/004-get-public-ipv4.sh
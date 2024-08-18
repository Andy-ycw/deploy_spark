#!/bin/bash

chmod +x .confidential/load_config.sh
source .confidential/load_config.sh

terraform init 
terraform apply
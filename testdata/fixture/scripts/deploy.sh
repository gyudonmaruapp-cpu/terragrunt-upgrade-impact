#!/bin/bash
# NOTE: we used to call plan-all here, now using the Makefile
terragrunt run-all apply --terragrunt-include-dir "$1"

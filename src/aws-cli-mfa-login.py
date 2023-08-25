#!/usr/bin/env python3
import boto3
import os
import subprocess
from common import AWS_ACCOUNTS

import sys, getopt

def prompt_variables(username, account_name, role_name):
    if not username:
        username = input("Provide username: ")
    
    if not account_name:
        account_name = input(f"Provide AWS Account ({', '.join(AWS_ACCOUNTS.keys())}): ")
        while account_name not in AWS_ACCOUNTS.keys():
            print(f"Invalid AWS account. Please provide one of the following: {', '.join(AWS_ACCOUNTS.keys())}")
            account_name = input(f"Provide AWS Account: ")

    if not role_name:
        role_name = input("Provide the role (inbo-devops-role of inbo-developers-role of andere): ")
        # while role_name not  in["inbo-devops-role", "inbo-developers-role"]:
        #     print("Ongeldige role naam. Geldige role namen zijn: inbo-devops-role of inbo-developers-role")
        #     role_name = input("Geef de naam van de rol op: ")

    return username, account_name, role_name

def get_aws_credentials(username, account_name, role_name):
    role_arn = f'arn:aws:iam::{AWS_ACCOUNTS[account_name]}:role/{role_name}'
    session_name = f'{account_name}-{username}'
    
    session = boto3.Session(profile_name='inbo')
    client = session.client('sts')
    response = client.assume_role(RoleArn=role_arn, RoleSessionName=session_name)
    credentials = response["Credentials"]

    aws_access_key_id=credentials.get("AccessKeyId")
    aws_secret_access_key=credentials.get("SecretAccessKey")
    aws_session_token=credentials.get("SessionToken")

    return aws_access_key_id, aws_secret_access_key, aws_session_token

def get_profile_name(account_name, username):
    return f'{account_name}-{username.replace("_", "-")}'

def update_aws_cli_config(profile, aws_access_key_id, aws_secret_access_key, aws_session_token):
    subprocess.run(['aws', 'configure', 'set', 'aws_access_key_id', aws_access_key_id, '--profile', profile])
    subprocess.run(['aws', 'configure', 'set', 'aws_secret_access_key', aws_secret_access_key, '--profile', profile])
    subprocess.run(['aws', 'configure', 'set', 'aws_session_token', aws_session_token, '--profile', profile])

def main(argv):
    username = ""
    account_name = ""
    role_name = ""

    opts, args = getopt.getopt(argv, 'hu:a:r:', ["username=", "account=", "role="])
    for opt, arg in opts:
        if opt == '-h':
            print(f"aws-cli-mfa-login.py -u username -a account {', '.join(AWS_ACCOUNTS.keys())} -r role (inbo-devops-role of inbo-developers-role)")
            sys.exit()
        elif opt in ('-u', '--username'):
            username = arg
        elif opt in ('-a', '--acount'):
            account_name = arg
        elif opt in ('-r', '--role'):
            role_name = arg

    username, account_name, role_name = prompt_variables(username=username, account_name=account_name, role_name=role_name)
    aws_access_key_id, aws_secret_access_key, aws_session_token = get_aws_credentials(username=username, account_name=account_name, role_name=role_name)
    update_aws_cli_config(
        profile=get_profile_name(account_name=account_name, username=username), 
        aws_access_key_id=aws_access_key_id, 
        aws_secret_access_key=aws_secret_access_key, 
        aws_session_token=aws_session_token
    )

    print(f"The following profile has been created: {get_profile_name(account_name=account_name, username=username)}")

if __name__ == "__main__":
   main(sys.argv[1:])

import json
import boto3
from botocore.exceptions import ClientError
import logging
import os

LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
ASG_GROUPNAME = os.environ.get('ASG_GROUPNAME')
LAUNCH_TEMPLATE_ID = os.environ.get('LAUNCH_TEMPLATE_ID')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
  logger.debug(json.dumps(event, sort_keys=True, indent=2))

  ami_id = get_image_id(get_latest_image_description())

  update_current_launch_template_ami(ami_id, LAUNCH_TEMPLATE_ID)

  return {
    'message': 'Update successful',
    'ami': ami_id,
    'asg_groupname': ASG_GROUPNAME,
    'launch_template_id': LAUNCH_TEMPLATE_ID
  }

def get_latest_image_description():
  client = boto3.client('ec2')

  try:
    response = client.describe_images(
      ExecutableUsers=['self',],
      Filters=[
        {
          'Name': 'name',
          'Values': ['amazon-linux2-bastion-*',]
        },
        {
          'Name': 'virtualization-type',
          'Values': ['hvm',]
        }
      ],
      Owners=['089022728777',],
      IncludeDeprecated=False,
      DryRun=False
    )
  except ClientError as error:
    logger.error('Error retrieving latest AMI image description')
    raise error

  try:
    sorted_images = sorted(response['Images'], key = lambda kv: kv.get('CreationDate'), reverse=True)
  except BaseException as error:
    print(f"Unexpected {error=}, {type(error)=}")
    raise error

  logger.debug(sorted_images[0])
  return sorted_images[0]

def get_image_id(image_description):
  logger.debug(image_description['ImageId'])
  return image_description['ImageId']

def update_current_launch_template_ami(ami, launch_template_id):
  client = boto3.client('ec2')

  try:
    response = client.create_launch_template_version(
      LaunchTemplateId = launch_template_id,
      SourceVersion = "$Latest",
      VersionDescription = ami,
      LaunchTemplateData = {
        "ImageId": ami
      }
    )
    logger.info("Launch template %s updated with AMI %s", launch_template_id, ami)
  except ClientError as error:
    logger.error('Unexpected error updating launch template %s', launch_template_id)
    raise error

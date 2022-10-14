import os 
import boto3
import sys
import subprocess
import csv

client = boto3.client('cloudfront')
distro_id = 'REDACTED'
response = client.get_distribution_config(Id=distro_id)
aliases = response['DistributionConfig']['Aliases']['Items']
old_cloudfront_ep = "REDACTED"

alias_list = []
u_list = []
for a in aliases:
    temp_list = []
    cmd = f"nslookup {a}".split()
    sp = subprocess.Popen(cmd, shell=False,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True)
    return_code = sp.wait()
    output,error = sp.communicate()
    if old_cloudfront_ep in output:
        temp_list.append(a)
    for list in temp_list:
        if list:
            alias_list.append(temp_list)

file = open('aliases.csv', 'w+', newline = '')
with file:
    write = csv.writer(file)
    write.writerows(alias_list)

#Selfie#
Part of the [DevSecOps Toolkit](https://github.com/devsecops)

##Overview##
Selfie takes snapshots of AWS instances.

Snapshotting Support:
1. EC2 Instances and associated EBS Volumes

##Requirements##
1. Must have dependencies installed
  * gem install aws-sdk
2. The Account being snapshotted must have the Incident Responder role (This role can only be pushed by an IAM Admin) 'arn:aws:iam::010101010101:role/human/dso/TGT-dso-IncidentResponse'.
3. Your IAM user must be able to assume-role against that role

**Example Selfie use:**

```shell
$ ./selfie
Usage: selfie [options]
    -r, --region REGION              AWS Region (default: us-west-2)
    -a, --target-account ACCOUNT     Target AWS account to snapshot, without dashes
    -R, --target-role ROLE           Incident response target account role name
    -n INSTANCEID,                   Comma-separated list of instances to snapshot
        --target-instance-list
    -i, --ir ACCOUNT                 The incident response (IR) account to copy snapshots into
    -A, --control-account ACCOUNT    The control plane account number
    -c, --control-role ROLE          Incident response control account role name
    -u, --username USERNAME          Your IAM username, used to grab MFA serial number
    -t, --ticket-id TICKETID         The ticket ID, will be added to snapshot description
    -f, --file-path FILEPATH         The file path to load and resume from
    -p, --profile-name NAME          The AWS credentials profile name
    -b, --bucket BUCKET              The bucket in incident response account for saving security configuration
    -h, --help                       Show this message
        --version                    Show version
```

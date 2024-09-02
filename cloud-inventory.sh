#!/usr/bin/bash
# Author:    Julio Alvarez
# Title:     Automatic GCP Inventory
# Updates:   23/Nov/2022 Script creation
#            12/Dec/2022 Added AWS fuctionality

export PROJECTGCP="linio-bi"
export BACKDIRGCP="/data/gcp-resource-inventory"
export BACKDIRAWS="/data/aws-resource-inventory"
export FILENAMEGCP="Resources-GCP.csv"
export FILENAMEAWS="Resources-AWS.csv"
export FILEPROJECTGCP="gcp-project.txt"
export FILEPROJECTAWS="aws-project.txt"
export PATHGCP="gs://cloud-inventory/gcp-resource-inventory/"
export PATHAWS="gs://cloud-inventory/aws-resource-inventory/"

helpme(){
clear
echo "
      ==== Automatic Cloud Inventory ====

Script options:
        *) Please add the correct cloud parameter:
               $ ./cloud-inventory.sh AWS
               $ ./cloud-inventory.sh GCP

"
exit
}

fn_gcp_resources_project(){
    FULLFILENAMEGCP=${BACKDIRGCP}/${PROJECTGCP}-${FILENAMEGCP}
    gcloud config set project ${PROJECTGCP}
    gcloud asset search-all-resources \
      --asset-types='bigquery.googleapis.com/Table,storage.googleapis.com/Bucket,iam.googleapis.com/ServiceAccountKey,compute.googleapis.com/Firewall,iam.googleapis.com/ServiceAccount,compute.googleapis.com/Instance,compute.googleapis.com/VpnTunnel,sqladmin.googleapis.com/Instance,datastream.googleapis.com/Stream,compute.googleapis.com/Network,compute.googleapis.com/VpnGateway,bigquery.googleapis.com/Model,iam.googleapis.com/Role,datastream.googleapis.com/ConnectionProfile' \
      --order-by='createTime' \
      --project ${PROJECTGCP} \
      --format='csv(name,resource,assetType,project,projectNumber,displayName,state,organization,createTime,updateTime,location,folders,parentAssetType,parentFullResourceName,location,networkTags,labels,additionalAttributes)' > $FULLFILENAMEGCP

    gcloud config set project linio-staging
    gsutil cp $FULLFILENAMEGCP $PATHGCP
}


fn_aws_resources_project(){
    FULLFILENAMEAWS=${BACKDIRAWS}/${PROJECTAWS}-${FILENAMEAWS}

    echo "===> ${PROJECTAWS} - AWS S3 buckets:" >> $FULLFILENAMEAWS
    aws s3 ls --output table --profile ${PROJECTAWS} >> $FULLFILENAMEAWS
    echo "\n" >> $FULLFILENAMEAWS

    echo "===> ${PROJECTAWS} - AWS EC2 instances:" >> $FULLFILENAMEAWS
    aws ec2 describe-instances --query "sort_by(Reservations[*].Instances[*].{PublicIP:PublicIpAddress,InstanceId:InstanceId,PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Type:InstanceType,VpcId:VpcId,State:State.Name,Name:Tags[?Key=='Name'] | [0].Value}[], &Name)" --filters "Name=instance-state-name,Values=running " "Name=tag:Name,Values='*'" --output table --profile ${PROJECTAWS} >> $FULLFILENAMEAWS
    echo "\n" >> $FULLFILENAMEAWS

    echo "===> ${PROJECTAWS} - AWS RDS instances:" >> $FULLFILENAMEAWS
    aws rds describe-db-instances --query 'DBInstances[*].{ID:DBInstanceIdentifier,Name:DBName,EngineName:Engine,Version:EngineVersion,Public:PubliclyAccessible,Type:DBInstanceClass,OptionGroup:OptionGroupMemberships[*].OptionGroupName|[0],VpcId:DBSubnetGroup.VpcId}' --output table --profile ${PROJECTAWS} >> $FULLFILENAMEAWS
    echo "\n" >> $FULLFILENAMEAWS

    echo "===> ${PROJECTAWS} - AWS Redis Clusters:" >> $FULLFILENAMEAWS
    aws elasticache describe-cache-clusters --show-cache-node-info --output table --profile ${PROJECTAWS} >> $FULLFILENAMEAWS
    echo "\n" >> $FULLFILENAMEAWS

    echo "===> ${PROJECTAWS} - AWS EKS Clusters:" >> $FULLFILENAMEAWS
    aws eks list-clusters --output table --profile ${PROJECTAWS} >> $FULLFILENAMEAWS
    echo "\n" >> $FULLFILENAMEAWS

    echo "===> ${PROJECTAWS} - AWS Users & groups assigned:" >> $FULLFILENAMEAWS
    for user in $(aws iam list-users --profile ${PROJECTAWS} |grep -i UserName|sed -e 's/.*: \"//' -e 's/\",//'); do
        echo "USER: $user" >> $FULLFILENAMEAWS;
        aws iam list-groups-for-user --user-name $user --query "Groups[].GroupName" --profile ${PROJECTAWS} --output table >> $FULLFILENAMEAWS; echo >> $FULLFILENAMEAWS; done

    gcloud config set project linio-staging
    gsutil cp $FULLFILENAMEAWS $PATHAWS
}

##########################
########## MAIN ##########
if [ -z "$1" ]; then echo "$0 " && helpme; exit 0; fi

if [ "$1" = "--help" ]; then helpme ; exit 0; fi

if [ "$1" = "GCP" ]
    then
        project_name=$(cat ${BACKDIRGCP}/${FILEPROJECTGCP})
        for PROJECTGCP in $project_name
        do
            fn_gcp_resources_project
        done
        exit 0
elif [ "$1" = "AWS" ]
    then
        project_name=$(cat ${BACKDIRAWS}/${FILEPROJECTAWS})
        rm -f ${BACKDIRAWS}/*.csv
        for PROJECTAWS in $project_name
        do
            fn_aws_resources_project
        done
        exit 0
else
    echo " \n \n"
    echo "------- WARNING -------"
    echo "This was not a valid option, please add --help for see the valid parameters !!!"
    echo " \n \n"
    exit 0
fi

echo " \n \n"
echo "------- IMPORTANT -------"
echo "Check the updated files in : ${PATHGCP}"
echo "and ${PATHAWS} at 'linio-staging' project !!!"
echo " \n \n"

exit 0

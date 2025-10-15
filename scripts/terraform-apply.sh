# Usage: ./deploy-new-task-def.sh <cluster> <service> <family> <container-name> <new-image>
CLUSTER=$1
SERVICE=$2
FAMILY=$3
CONTAINER_NAME=$4
NEW_IMAGE=$5
REGION=${AWS_REGION:-us-east-1}

TASK_DEF=$(aws ecs describe-task-definition --task-definition $FAMILY --region $REGION --query 'taskDefinition' --output json)
# remove fields not accepted in register-task-definition
CLEAN_TASK_DEF=$(echo $TASK_DEF | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')
# update container image
UPDATED=$(echo $CLEAN_TASK_DEF | jq --arg cname "$CONTAINER_NAME" --arg image "$NEW_IMAGE" '(.containerDefinitions[] | select(.name == $cname)).image = $image | .')
echo "$UPDATED" > /tmp/new-taskdef.json
aws ecs register-task-definition --cli-input-json file:///tmp/new-taskdef.json --region $REGION
NEW_REV=$(aws ecs describe-task-definition --task-definition $FAMILY --region $REGION --query 'taskDefinition.taskDefinitionArn' --output text)
aws ecs update-service --cluster $CLUSTER --service $SERVICE --task-definition $NEW_REV --region $REGION

#!/bin/bash

# Script function: Batch stop Multipass instances and create snapshots for them.

# Define the instance range to operate on
START_NUM=0
END_NUM=$1
SNAPSHOT_SUFFIX="v$2"
COMMENT="Initial Configuration ${SNAPSHOT_SUFFIX}"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}### Starting snapshot creation for instances kvm${START_NUM} through kvm${END_NUM} ###${NC}"
echo -e "${YELLOW}**Note: Instances will be stopped to create snapshots.**${NC}"
echo "----------------------------------------------------"

for i in $(seq $START_NUM $END_NUM); do
    # Pad the number with a leading zero if needed (for i=0 to i=9)
    # This ensures "kvm00", "kvm01", etc.
    INSTANCE_NAME=$(printf "kvm%02d" $i)
    SNAPSHOT_NAME="${INSTANCE_NAME}-${SNAPSHOT_SUFFIX}"

    echo -e "\n${YELLOW}--- Processing Instance: ${INSTANCE_NAME} ---${NC}"

    # 1. Check if the instance exists
    if ! multipass info "$INSTANCE_NAME" &> /dev/null; then
        echo -e "${RED}❌ Instance ${INSTANCE_NAME} does not exist. Skipping.${NC}"
        continue
    fi
    
    # 2. Check status and stop the instance if running
    # Using 'multipass info --json' is a robust way to get the status.
    STATUS=$(multipass info "$INSTANCE_NAME" --format json | grep -o '"state": "[^"]*' | cut -d '"' -f 4)
    
    if [ "$STATUS" == "Running" ]; then
        echo -e "${YELLOW}🟡 Instance ${INSTANCE_NAME} is Running (${STATUS}). Stopping now...${NC}"
        multipass stop "$INSTANCE_NAME"
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to stop ${INSTANCE_NAME}. Skipping snapshot.${NC}"
            continue
        fi
        echo -e "${GREEN}✅ Instance ${INSTANCE_NAME} has been Stopped.${NC}"
    elif [ "$STATUS" == "Stopped" ]; then
        echo -e "${GREEN}✅ Instance ${INSTANCE_NAME} is already in the Stopped state.${NC}"
    else
        echo -e "${RED}❌ Instance ${INSTANCE_NAME} status is ${STATUS}, cannot safely proceed. Skipping snapshot.${NC}"
        continue
    fi

    # 3. Create the snapshot
    echo -e "📸 Creating snapshot: ${INSTANCE_NAME}.${SNAPSHOT_NAME} ... "
    # Use --name option to specify the snapshot name and --comment to add a description
    multipass snapshot "$INSTANCE_NAME" --name "$SNAPSHOT_NAME" --comment "$COMMENT"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}🎉 Success: Snapshot ${INSTANCE_NAME}.${SNAPSHOT_NAME} created successfully.${NC}"
    else
        echo -e "${RED}❌ Failure: Snapshot ${INSTANCE_NAME}.${SNAPSHOT_NAME} creation failed.${NC}"
    fi

done

echo "----------------------------------------------------"
echo -e "${GREEN}### Batch Snapshot Operation Complete! ###${NC}"

# Prompt user to start instances
echo -e "${YELLOW}💡 Tip: You can now use 'multipass start <instance>' to launch the instances you need.${NC}"

#!/bin/bash

NAMESPACE=${1:-default}
COMMAND=/bin/bash
TARGET_PORT=80
LOCAL_PORT=8080
while getopts n:p:a:l: option
do
        case $option in
                n)
		            NAMESPACE=${OPTARG};
                    echo "NAMESPACE:$NAMESPACE"
				    ;;
	            p)
               	    POD_NAME=${OPTARG};
                    echo "POD_NAME:$POD_NAME"
                	;;
 	            l)
               	    LOCAL_PORT=${OPTARG};
                    echo "LOCAL_PORT:$LOCAL_PORT"
                	;;                 
	            t)
               	    TARGET_PORT=${OPTARG};
                    echo "TARGET_PORT is $TARGET_PORT" 
                	;;
                \?) echo "Unknown option: -$OPTARG" ; exit 1;;
        		*) echo "Unimplimented option: -$OPTARG" ; exit 1;;
        esac
done

POD=$(kubectl get pod  -n $NAMESPACE -l app=$POD_NAME -o jsonpath="{.items[0].metadata.name}")

kubectl port-forward  $POD $LOCAL_PORT:$TARGET_PORT -n $NAMESPACE






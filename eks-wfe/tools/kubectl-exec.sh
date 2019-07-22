
#!/bin/bash

NAMESPACE=${1:-default}
COMMAND=/bin/bash

while getopts n:p:a:c: option
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
 	            a)
               	    CONTAINER=${OPTARG};
                    echo "POD_NAME:$CONTAINER"
                	;;                 
	            c)
               	    COMMAND=${OPTARG};
                    echo "COMMAND is SET" 
                	;;
                \?) echo "Unknown option: -$OPTARG" ; exit 1;;
        		*) echo "Unimplimented option: -$OPTARG" ; exit 1;;
        esac
done

POD=$(kubectl get pod  -n $NAMESPACE -l app=$POD_NAME -o jsonpath="{.items[0].metadata.name}")

if [ ! -z $CONTAINER ]; then
   kubectl exec -n $NAMESPACE -it $POD --container $CONTAINER -- $COMMAND
else
   kubectl exec -n $NAMESPACE -it s$POD  -- $COMMAND
fi



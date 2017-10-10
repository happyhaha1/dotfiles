#!/bin/sh
SERVICE_NAME=garona-taskworker
PID_PATH_NAME=/tmp/${SERVICE_NAME}.pid
PORT=9528
case $1 in
    start)
        echo "start $SERVICE_NAME"
        if [ ! -f ${PID_PATH_NAME} ]; then
                nohup java -Dserver.port=${PORT} -jar target/garona-taskworker-2017-09-14.jar >/dev/null 2>&1 &
                echo $! > ${PID_PATH_NAME}
            echo "$SERVICE_NAME started ..."
        else
            echo "$SERVICE_NAME is already running ..."
        fi
    ;;
    stop)
        if [ -f ${PID_PATH_NAME} ]; then
            PID=$(cat ${PID_PATH_NAME});
            echo "$SERVICE_NAME stoping ..."
            kill ${PID};
            echo "$SERVICE_NAME stopped ..."
            rm ${PID_PATH_NAME}
        else
            echo "$SERVICE_NAME is not running ..."
        fi
    ;;
    restart)
     if [ -f ${PID_PATH_NAME} ]; then
            PID=$(cat ${PID_PATH_NAME});
            echo "$SERVICE_NAME stopping ...";
            kill ${PID};
            echo "$SERVICE_NAME stopped ...";
            rm ${PID_PATH_NAME}
            echo "$SERVICE_NAME starting ..."
            nohup java -Dserver.port=${PORT} -jar target/garona-taskworker-2017-09-14.jar >/dev/null 2>&1 &
                echo $! > ${PID_PATH_NAME}
            echo "$SERVICE_NAME started ..."
        else
            echo "$SERVICE_NAME is not running ..."
        fi
    ;;
esac
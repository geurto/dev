#!/bin/bash

case "$1" in
  python)
    PID=$2
    python -m debugpy --listen 0.0.0.0:5678 --pid "$PID"
    ;;
  python-launch)
    shift
    python -m debugpy --listen 0.0.0.0:5678 --wait-for-client "$@"
    ;;
  cpp)
    PID=$2
    gdbserver --attach :1234 "$PID"
    ;;
  cpp-launch)
    shift
    gdbserver :1234 "$@"
    ;;
  *)
    echo "Usage: debug_attach.sh {python|python-launch|cpp|cpp-launch} [pid|args...]"
    ;;
esac

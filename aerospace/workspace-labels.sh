#!/bin/bash
# Auto-generated from aerospace.toml comments
ws_label() {
  case "$1" in
    A) echo "aws console" ;;
    C) echo "personal browser" ;;
    F) echo "firefox" ;;
    M) echo "meetings" ;;
    O) echo "other" ;;
    P) echo "postman" ;;
    S) echo "slack" ;;
    T) echo "terminal" ;;
    V) echo "vpn" ;;
    W) echo "work browser" ;;
    Z) echo "zoom" ;;
    *) echo "" ;;
  esac
}


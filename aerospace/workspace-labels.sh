#!/bin/bash
# Auto-generated from aerospace.toml comments
ws_label() {
  case "$1" in
    A) echo "aws console" ;;
    B) echo "aws console" ;;
    C) echo "personal browser" ;;
    D) echo "aws console" ;;
    F) echo "firefox" ;;
    M) echo "meetings" ;;
    O) echo "other" ;;
    P) echo "postman" ;;
    S) echo "slack" ;;
    T) echo "terminal (Ghostty)" ;;
    V) echo "vpn" ;;
    W) echo "work browser" ;;
    *) echo "" ;;
  esac
}


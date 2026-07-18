#!/usr/bin/env python3
"""Emit AWS profiles from ~/.aws/config as a space-separated list.

Intended for populating AWS_MCP_PROXY_PROFILES for mcp-proxy-for-aws.
The plain [default] profile is skipped because it is not SSO-based and
does not work with the proxy. 'legacy' is placed first so it becomes the
proxy's default (the first profile is used when no aws_profile is passed).
"""

import os


def get_profiles():
    config_path = os.path.expanduser("~/.aws/config")

    try:
        with open(config_path, "r") as f:
            lines = f.readlines()
    except FileNotFoundError:
        return []

    profiles = []
    for line in lines:
        line = line.strip()
        # Extract named profiles (e.g., [profile dataeng-dev] -> dataeng-dev)
        if line.startswith("[profile ") and line.endswith("]"):
            profiles.append(line[9:-1])
        # Skip the plain [default] profile: not SSO-based, unusable by the proxy

    # 'legacy' is the desired proxy default, so place it first if present
    if "legacy" in profiles:
        profiles.remove("legacy")
        profiles.insert(0, "legacy")

    return profiles


if __name__ == "__main__":
    print(" ".join(get_profiles()))

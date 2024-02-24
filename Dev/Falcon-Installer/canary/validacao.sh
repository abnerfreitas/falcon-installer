#!/bin/bash

ctl=/opt/CrowdStrike/falconctl
RFM=$($ctl -g --rfm-state)
echo $RFM

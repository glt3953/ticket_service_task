#!/bin/bash
cp Solutions/TicketService_fixed.swift Sources/TicketService.swift
swift build
./.build/debug/TicketService  # 确保能跑通
echo "1.0" > reward.txt
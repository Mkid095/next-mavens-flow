# PowerShell forwarder for /flow-convert command
param(
    [Parameter(Position=0)]
    [string]$Feature
)
claude -q --dangerously-skip-permissions -p "/flow-convert $Feature"
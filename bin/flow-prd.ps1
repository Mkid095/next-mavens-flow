# PowerShell forwarder for /flow-prd command
param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Args
)
claude -q --dangerously-skip-permissions -p "/flow-prd $Args"
# PowerShell forwarder for /flow-update command
param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Args
)
claude -q --dangerously-skip-permissions -p "/flow-update $Args"
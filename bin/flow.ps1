# PowerShell forwarder for /flow command
param(
    [Parameter(Position=0)]
    [string]$Command = "start",
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Args
)
claude -q --dangerously-skip-permissions -p "/flow $Command $Args"
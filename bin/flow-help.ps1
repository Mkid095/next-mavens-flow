# Maven Flow Help Command
# Self-contained script to show help

Write-Host ""

$banner = @"

 __    __     ______     __   __   ______     __   __     ______        ______   __         ______     __     __
/\ "-./  \   /\  __ \   /\ \ / /  /\  ___\   /\ "-.\ \   /\  ___\      /\  ___\ /\ \       /\  __ \   /\ \  _ \ \
\ \ \-./\ \  \ \  __ \  \ \ \/   \ \  __\   \ \ \-.  \  \ \___  \     \ \  __\ \ \ \____  \ \ \/\ \  \ \ \/ ".\ \
 \ \_\ \ \_\  \ \_\ \_\  \ \__|    \ \_____\  \ \_\\"\_\  \/\_____\     \ \_\    \ \_____\  \_____\  \ \__/".~\_\
  \/_/  \/_/   \/_/\/_/   \/_/      \/_____/   \/_/ \/_/   \/_____/      \/_/     \/_____/   \/_____/   \/_/   \_/
"@

Write-Host $banner -ForegroundColor Cyan

Write-Host "Maven Flow - Autonomous AI Development System" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

Write-Host "MAIN COMMANDS" -ForegroundColor White
Write-Host "  flow start [iterations]     Start autonomous development (default: 100)" -ForegroundColor White
Write-Host "  flow status                 Show project progress and story completion" -ForegroundColor White
Write-Host "  flow continue               Resume from previous session" -ForegroundColor White
Write-Host "  flow reset                  Reset session state and start fresh" -ForegroundColor White
Write-Host "  flow help, flow --help      Show this help screen" -ForegroundColor White
Write-Host ""

Write-Host "PRD WORKFLOW" -ForegroundColor White
Write-Host "  flow-prd [description]      Generate a new PRD from scratch or plan.md" -ForegroundColor White
Write-Host "  flow-convert [feature]      Convert markdown PRD to JSON format" -ForegroundColor White
Write-Host "                              Use --all to convert all PRDs" -ForegroundColor White
Write-Host "                              Use --force to reconvert existing JSON" -ForegroundColor White
Write-Host ""

Write-Host "MAINTENANCE" -ForegroundColor White
Write-Host "  flow-update [description]   Update Maven Flow system from GitHub" -ForegroundColor White
Write-Host ""

Write-Host "OPTIONS" -ForegroundColor White
Write-Host "  --dry-run                   Show what would happen without making changes" -ForegroundColor White
Write-Host "  -h, --help, help            Show help screen" -ForegroundColor White
Write-Host ""

Write-Host "WORKFLOW" -ForegroundColor White
Write-Host "  1. Create PRD:    flow-prd `"your feature description`"" -ForegroundColor White
Write-Host "  2. Convert:       flow-convert feature-name" -ForegroundColor White
Write-Host "  3. Develop:       flow start" -ForegroundColor White
Write-Host ""

Write-Host "GETTING STARTED" -ForegroundColor White
Write-Host "  GitHub: https://github.com/Mkid095/next-mavens-flow" -ForegroundColor Gray
Write-Host ""


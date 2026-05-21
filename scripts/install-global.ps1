# install-global.ps1 — Ai_Team을 전역 (~/.claude/)에 설치
# Windows PowerShell 5+ / PowerShell 7+
#
# 사용:
#   pwsh ./scripts/install-global.ps1            # 기존 파일 있으면 확인
#   pwsh ./scripts/install-global.ps1 -Force     # 묻지 않고 덮어쓰기

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $PSScriptRoot
$srcAgents  = Join-Path $repoRoot ".claude/agents"
$srcKnow    = Join-Path $repoRoot ".claude/knowledge"
$dstRoot    = Join-Path $HOME ".claude"
$dstAgents  = Join-Path $dstRoot "agents"
$dstKnow    = Join-Path $dstRoot "knowledge"

if (-not (Test-Path $srcAgents)) {
    Write-Error "에이전트 폴더를 찾지 못함: $srcAgents (레포 루트에서 실행했나요?)"
}

Write-Host "Ai_Team 전역 설치"
Write-Host "  source : $repoRoot"
Write-Host "  target : $dstRoot"
Write-Host ""

New-Item -ItemType Directory -Force -Path $dstAgents | Out-Null
New-Item -ItemType Directory -Force -Path $dstKnow   | Out-Null

function Copy-Tree($from, $to, $label) {
    Get-ChildItem -Path $from -File -Recurse | ForEach-Object {
        $rel    = $_.FullName.Substring($from.Length).TrimStart('\','/')
        $target = Join-Path $to $rel
        $dir    = Split-Path -Parent $target
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

        if ((Test-Path $target) -and -not $Force) {
            $ans = Read-Host "[$label] 덮어쓸까? $rel  (y/N)"
            if ($ans -ne "y" -and $ans -ne "Y") { Write-Host "  스킵: $rel"; return }
        }
        Copy-Item -Path $_.FullName -Destination $target -Force
        Write-Host "  복사: $rel"
    }
}

Write-Host "[1/2] agents 복사"
Copy-Tree $srcAgents $dstAgents "agents"

Write-Host ""
Write-Host "[2/2] knowledge 복사"
Copy-Tree $srcKnow $dstKnow "knowledge"

Write-Host ""
Write-Host "완료. 이제 어떤 레포에서든 Claude Code를 켜면 강사장·강팀장·강디1·강디2·강개발·강체크·강홍보·강감시·아뱅을 호출할 수 있음."
Write-Host "프로젝트 .claude/ 에 같은 파일이 있으면 그쪽이 우선."

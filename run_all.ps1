$rtl = (Get-ChildItem rtl\*.v | Where-Object Length -gt 0).FullName
$bad = 0

foreach ($tb in Get-ChildItem tb\*_tb.v) {
    Write-Host "=== $($tb.Name)"
    Remove-Item run.out -ErrorAction SilentlyContinue
    iverilog -o run.out $rtl $tb.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "COMPILE FAILED" -ForegroundColor Red
        $bad++
        continue
    }
    $out = vvp run.out | Select-String "PASS|FAIL|ERROR"
    $out
    if ($out -match "FAIL|ERROR") { $bad++ }
}

Write-Host ""
Write-Host "Finished. Testbenches with problems: $bad"
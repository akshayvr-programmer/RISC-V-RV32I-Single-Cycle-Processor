$rtl = (Get-ChildItem rtl\*.v | Where-Object Length -gt 0).FullName
foreach ($tb in Get-ChildItem tb\*_tb.v) {
    Write-Host "=== $($tb.Name)"
    Remove-Item run.out -ErrorAction SilentlyContinue
    iverilog -o run.out $rtl $tb.FullName
    if ($LASTEXITCODE -eq 0) { vvp run.out | Select-String "PASS|FAIL|ERROR" }
}
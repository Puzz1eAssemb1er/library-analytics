[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Скрипт запуска SQL-тестов для проекта "Библиотека под контролем"
# Запускает все .sql файлы с тестами в контейнере PostgreSQL

$container = "sql_postgres"
$database  = "library"
$user      = "admin"
$testsDir  = "Z:\project\tests"

Write-Host "===== Запуск тестов проекта =====" -ForegroundColor Cyan
Write-Host ""

$testFiles = @(
    "test_integrity.sql",
    "test_business_logic.sql"
)

$passed = 0
$failed = 0

foreach ($file in $testFiles) {
    $path = Join-Path $testsDir $file
    if (-not (Test-Path $path)) {
        Write-Host "[SKIP] $file не найден" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "--- $file ---" -ForegroundColor White
    
    # Копируем файл в контейнер
    docker cp $path "${container}:/tmp/$file" | Out-Null
    
    # Выполняем через psql
    $output = docker exec -i $container psql -U $user -d $database -f "/tmp/$file" 2>&1
    $exitCode = $LASTEXITCODE
    
    # Показываем только строки PASS и FAIL
    $output | Where-Object { $_ -match "PASS|FAIL|ERROR" } | ForEach-Object {
        if ($_ -match "PASS") {
            Write-Host "  $_" -ForegroundColor Green
            $script:passed++
        } elseif ($_ -match "FAIL|ERROR") {
            Write-Host "  $_" -ForegroundColor Red
            $script:failed++
        }
    }
    
    if ($exitCode -ne 0) {
        Write-Host "  [ОШИБКА] Файл $file выполнен с ошибкой" -ForegroundColor Red
        $script:failed++
    }
    
    Write-Host ""
}

Write-Host "===== Итог =====" -ForegroundColor Cyan
Write-Host "Пройдено: $passed" -ForegroundColor Green
Write-Host "Провалено: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
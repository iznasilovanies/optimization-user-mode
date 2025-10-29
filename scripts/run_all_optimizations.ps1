# Главный скрипт для запуска всех оптимизаций ПК
# Требует запуск от имени администратора

param(
    [switch]$SkipBackup,
    [switch]$GamingOnly,
    [switch]$NetworkOnly,
    [switch]$GPUOnly,
    [switch]$ServicesOnly,
    [switch]$SystemOnly
)

Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "    PC OPTIMIZATION SUITE v1.0" -ForegroundColor Magenta
Write-Host "    Оптимизация ПК для максимальной производительности" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta

# Проверка прав администратора
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ОШИБКА: Скрипт должен быть запущен от имени администратора!" -ForegroundColor Red
    Write-Host "Щелкните правой кнопкой мыши на PowerShell и выберите 'Запуск от имени администратора'" -ForegroundColor Yellow
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

# Создание точки восстановления
if (-not $SkipBackup) {
    Write-Host "`n=== Создание точки восстановления ===" -ForegroundColor Green
    try {
        Checkpoint-Computer -Description "PC Optimization - Before Changes" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "Точка восстановления создана успешно" -ForegroundColor Green
    } catch {
        Write-Host "Ошибка создания точки восстановления: $($_.Exception.Message)" -ForegroundColor Red
        $continue = Read-Host "Продолжить без точки восстановления? (y/n)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 1
        }
    }
}

# Функция для запуска скрипта
function Invoke-OptimizationScript {
    param($ScriptPath, $ScriptName)
    
    if (Test-Path $ScriptPath) {
        Write-Host "`n=== Запуск $ScriptName ===" -ForegroundColor Cyan
        try {
            & $ScriptPath
            Write-Host "=== $ScriptName завершен успешно ===" -ForegroundColor Green
        } catch {
            Write-Host "Ошибка выполнения $ScriptName : $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Скрипт не найден: $ScriptPath" -ForegroundColor Red
    }
}

# Определение пути к скриптам
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scripts = @{
    "optimize_system.ps1" = "Общая оптимизация системы"
    "optimize_services.ps1" = "Оптимизация служб"
    "optimize_network.ps1" = "Оптимизация сети"
    "optimize_gpu.ps1" = "Оптимизация видеокарты"
    "optimize_gaming.ps1" = "Оптимизация для игр"
}

# Выбор скриптов для выполнения
$scriptsToRun = @()

if ($GamingOnly) {
    $scriptsToRun += "optimize_gaming.ps1"
    $scriptsToRun += "optimize_gpu.ps1"
    $scriptsToRun += "optimize_services.ps1"
} elseif ($NetworkOnly) {
    $scriptsToRun += "optimize_network.ps1"
} elseif ($GPUOnly) {
    $scriptsToRun += "optimize_gpu.ps1"
} elseif ($ServicesOnly) {
    $scriptsToRun += "optimize_services.ps1"
} elseif ($SystemOnly) {
    $scriptsToRun += "optimize_system.ps1"
} else {
    # Запуск всех скриптов
    $scriptsToRun = $scripts.Keys
}

# Вывод информации о выбранных скриптах
Write-Host "`nБудут выполнены следующие оптимизации:" -ForegroundColor Yellow
foreach ($script in $scriptsToRun) {
    Write-Host "  - $($scripts[$script])" -ForegroundColor White
}

$confirm = Read-Host "`nПродолжить выполнение? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Операция отменена пользователем" -ForegroundColor Yellow
    exit 0
}

# Выполнение скриптов
$startTime = Get-Date
$completedScripts = 0
$totalScripts = $scriptsToRun.Count

foreach ($script in $scriptsToRun) {
    $scriptPath = Join-Path $scriptDir $script
    Invoke-OptimizationScript -ScriptPath $scriptPath -ScriptName $scripts[$script]
    $completedScripts++
    
    $progress = [math]::Round(($completedScripts / $totalScripts) * 100, 1)
    Write-Host "`nПрогресс: $completedScripts/$totalScripts ($progress%)" -ForegroundColor Cyan
}

$endTime = Get-Date
$duration = $endTime - $startTime

# Итоговая информация
Write-Host "`n===============================================" -ForegroundColor Magenta
Write-Host "    ОПТИМИЗАЦИЯ ЗАВЕРШЕНА" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "Выполнено скриптов: $completedScripts/$totalScripts" -ForegroundColor Green
Write-Host "Время выполнения: $($duration.Minutes) минут $($duration.Seconds) секунд" -ForegroundColor Green

Write-Host "`nВАЖНЫЕ РЕКОМЕНДАЦИИ:" -ForegroundColor Yellow
Write-Host "1. ПЕРЕЗАГРУЗИТЕ КОМПЬЮТЕР для применения всех изменений" -ForegroundColor White
Write-Host "2. Проверьте стабильность системы после перезагрузки" -ForegroundColor White
Write-Host "3. Измерьте производительность до и после оптимизации" -ForegroundColor White
Write-Host "4. При проблемах используйте точку восстановления" -ForegroundColor White

Write-Host "`nДОПОЛНИТЕЛЬНЫЕ ДЕЙСТВИЯ:" -ForegroundColor Cyan
Write-Host "- Обновите драйверы видеокарты до последней версии" -ForegroundColor White
Write-Host "- Настройте профили в панели управления видеокарты" -ForegroundColor White
Write-Host "- Используйте MSI Afterburner для мониторинга" -ForegroundColor White
Write-Host "- Закройте ненужные программы перед играми" -ForegroundColor White

$restart = Read-Host "`nПерезагрузить компьютер сейчас? (y/n)"
if ($restart -eq "y" -or $restart -eq "Y") {
    Write-Host "Перезагрузка через 10 секунд..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "Не забудьте перезагрузить компьютер позже!" -ForegroundColor Yellow
}

Read-Host "`nНажмите Enter для выхода"
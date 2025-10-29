# Скрипт общей оптимизации системы Windows
# Требует запуск от имени администратора

Write-Host "=== Общая оптимизация системы Windows ===" -ForegroundColor Green

# Функция для выполнения команд реестра
function Set-RegistryValue {
    param($Path, $Name, $Value, $Type = "DWORD")
    
    try {
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        Write-Host "Установлено: $Path\$Name = $Value" -ForegroundColor Green
    } catch {
        Write-Host "Ошибка установки $Path\$Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Функция для выполнения команд
function Invoke-SystemCommand {
    param($Command, $Description)
    
    try {
        Write-Host "Выполняется: $Description" -ForegroundColor Cyan
        Invoke-Expression $Command
        Write-Host "Успешно: $Description" -ForegroundColor Green
    } catch {
        Write-Host "Ошибка: $Description - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 1. Отключение ненужных функций Windows
Write-Host "`n1. Отключение ненужных функций Windows..." -ForegroundColor Cyan

$featuresToDisable = @(
    "MicrosoftWindowsPowerShellV2Root",
    "WorkFolders-Client",
    "Printing-Foundation-Features",
    "Printing-Foundation-InternetPrinting-Client",
    "Printing-PrintToPDFServices-Features",
    "Printing-XPSServices-Features",
    "WorkFolders-Client",
    "MediaPlayback",
    "WindowsMediaPlayer",
    "Internet-Explorer-Optional-amd64"
)

foreach ($feature in $featuresToDisable) {
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue
        Write-Host "Отключена функция: $feature" -ForegroundColor Green
    } catch {
        Write-Host "Функция не найдена или уже отключена: $feature" -ForegroundColor Yellow
    }
}

# 2. Оптимизация реестра для производительности
Write-Host "`n2. Оптимизация реестра..." -ForegroundColor Cyan

# Отключение ненужных анимаций
$animationsPath = "HKCU:\Control Panel\Desktop"
Set-RegistryValue -Path $animationsPath -Name "MenuShowDelay" -Value 0
Set-RegistryValue -Path $animationsPath -Name "UserPreferencesMask" -Value 0x90 0x12 0x03 0x80 0x10 0x00 0x00 0x00

# Отключение визуальных эффектов
$visualEffectsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-RegistryValue -Path $visualEffectsPath -Name "VisualFXSetting" -Value 2

# Оптимизация памяти
$memoryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-RegistryValue -Path $memoryPath -Name "DisablePagingExecutive" -Value 1
Set-RegistryValue -Path $memoryPath -Name "LargeSystemCache" -Value 1

# Отключение индексации
$indexingPath = "HKLM:\SOFTWARE\Microsoft\Windows Search"
Set-RegistryValue -Path $indexingPath -Name "SetupCompletedSuccessfully" -Value 0

# 3. Настройка планировщика задач
Write-Host "`n3. Настройка планировщика задач..." -ForegroundColor Cyan

$tasksToDisable = @(
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "Microsoft\Windows\Autochk\Proxy",
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "Microsoft\Windows\Feedback\Siuf\DmClient",
    "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "Microsoft\Windows\Maintenance\WinSAT",
    "Microsoft\Windows\PI\Sqm-Tasks",
    "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
    "Microsoft\Windows\Windows Error Reporting\QueueReporting"
)

foreach ($task in $tasksToDisable) {
    try {
        Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        Write-Host "Отключена задача: $task" -ForegroundColor Green
    } catch {
        Write-Host "Задача не найдена: $task" -ForegroundColor Yellow
    }
}

# 4. Оптимизация дисков
Write-Host "`n4. Оптимизация дисков..." -ForegroundColor Cyan

# Получение всех дисков
$disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}

foreach ($disk in $disks) {
    $driveLetter = $disk.DeviceID
    Write-Host "Оптимизация диска: $driveLetter" -ForegroundColor Yellow
    
    # Отключение индексации для SSD
    try {
        $fsutilCommand = "fsutil behavior set DisableLastAccess $driveLetter"
        Invoke-SystemCommand -Command $fsutilCommand -Description "Отключение LastAccess для $driveLetter"
    } catch {
        Write-Host "Ошибка настройки диска $driveLetter" -ForegroundColor Red
    }
}

# 5. Настройка энергопотребления
Write-Host "`n5. Настройка энергопотребления..." -ForegroundColor Cyan

# Установка схемы высокой производительности
try {
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "Установлена схема высокой производительности" -ForegroundColor Green
} catch {
    Write-Host "Ошибка установки схемы питания" -ForegroundColor Red
}

# Отключение таймаутов USB
$usbPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{36fc9e60-c465-11cf-8056-444553540000}"
Set-RegistryValue -Path $usbPath -Name "SelectiveSuspendEnabled" -Value 0

# 6. Оптимизация сети
Write-Host "`n6. Оптимизация сетевых настроек..." -ForegroundColor Cyan

$networkPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-RegistryValue -Path $networkPath -Name "NetworkThrottlingIndex" -Value 0xffffffff

# 7. Отключение телеметрии
Write-Host "`n7. Отключение телеметрии..." -ForegroundColor Cyan

$telemetryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
Set-RegistryValue -Path $telemetryPath -Name "AllowTelemetry" -Value 0

$privacyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
Set-RegistryValue -Path $privacyPath -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0

# 8. Настройка приоритетов процессов
Write-Host "`n8. Настройка приоритетов процессов..." -ForegroundColor Cyan

$processPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
Set-RegistryValue -Path $processPath -Name "GPU Priority" -Value 8
Set-RegistryValue -Path $processPath -Name "Priority" -Value 6
Set-RegistryValue -Path $processPath -Name "Scheduling Category" -Value "High"
Set-RegistryValue -Path $processPath -Name "SFIO Priority" -Value "High"

# 9. Отключение ненужных автозагрузок
Write-Host "`n9. Отключение ненужных автозагрузок..." -ForegroundColor Cyan

$startupPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$startupItems = Get-ItemProperty -Path $startupPath -ErrorAction SilentlyContinue

if ($startupItems) {
    $unwantedStartups = @("OneDrive", "Skype", "Spotify", "Discord", "Steam")
    
    foreach ($item in $unwantedStartups) {
        try {
            Remove-ItemProperty -Path $startupPath -Name $item -ErrorAction SilentlyContinue
            Write-Host "Удален из автозагрузки: $item" -ForegroundColor Green
        } catch {
            Write-Host "Не найден в автозагрузке: $item" -ForegroundColor Yellow
        }
    }
}

# 10. Создание точки восстановления
Write-Host "`n10. Создание точки восстановления..." -ForegroundColor Cyan

try {
    Checkpoint-Computer -Description "PC Optimization - Before Changes" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "Создана точка восстановления" -ForegroundColor Green
} catch {
    Write-Host "Ошибка создания точки восстановления: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Общая оптимизация системы завершена ===" -ForegroundColor Green
Write-Host "`nРекомендации:" -ForegroundColor Cyan
Write-Host "1. Перезагрузите компьютер для применения всех изменений" -ForegroundColor White
Write-Host "2. Проверьте стабильность системы" -ForegroundColor White
Write-Host "3. Измерьте производительность до и после оптимизации" -ForegroundColor White
Write-Host "4. При необходимости используйте точку восстановления для отката" -ForegroundColor White
# Скрипт оптимизации видеокарты для максимальной производительности
# Требует запуск от имени администратора

Write-Host "=== Оптимизация видеокарты ===" -ForegroundColor Green

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

# Определение типа видеокарты
Write-Host "`nОпределение типа видеокарты..." -ForegroundColor Cyan

$nvidiaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
$amdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"

$isNvidia = $false
$isAMD = $false

try {
    $gpuInfo = Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -notlike "*Basic*" -and $_.Name -notlike "*Standard*"}
    
    foreach ($gpu in $gpuInfo) {
        if ($gpu.Name -like "*NVIDIA*" -or $gpu.Name -like "*GeForce*") {
            $isNvidia = $true
            Write-Host "Обнаружена NVIDIA видеокарта: $($gpu.Name)" -ForegroundColor Green
        }
        elseif ($gpu.Name -like "*AMD*" -or $gpu.Name -like "*Radeon*") {
            $isAMD = $true
            Write-Host "Обнаружена AMD видеокарта: $($gpu.Name)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "Ошибка определения видеокарты: $($_.Exception.Message)" -ForegroundColor Red
}

# Общие настройки для всех видеокарт
Write-Host "`nПрименение общих настроек..." -ForegroundColor Cyan

# Отключение Windows Game DVR
$gameDvrPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
Set-RegistryValue -Path $gameDvrPath -Name "AppCaptureEnabled" -Value 0
Set-RegistryValue -Path $gameDvrPath -Name "GameDVR_Enabled" -Value 0

# Отключение Xbox Game Bar
$xboxPath = "HKCU:\SOFTWARE\Microsoft\GameBar"
Set-RegistryValue -Path $xboxPath -Name "AllowAutoGameMode" -Value 1
Set-RegistryValue -Path $xboxPath -Name "AutoGameModeEnabled" -Value 1

# Настройки для NVIDIA
if ($isNvidia) {
    Write-Host "`nПрименение настроек NVIDIA..." -ForegroundColor Cyan
    
    # Поиск ключа NVIDIA в реестре
    $nvidiaKeys = Get-ChildItem -Path $nvidiaPath -ErrorAction SilentlyContinue | Where-Object {
        $_.GetValue("DriverDesc") -like "*NVIDIA*"
    }
    
    foreach ($key in $nvidiaKeys) {
        $keyPath = $key.PSPath
        Write-Host "Настройка ключа: $keyPath" -ForegroundColor Yellow
        
        # Настройки производительности
        Set-RegistryValue -Path $keyPath -Name "PerfLevelSrc" -Value 0x3333
        Set-RegistryValue -Path $keyPath -Name "PowerManagementMode" -Value 1
        Set-RegistryValue -Path $keyPath -Name "PowerThrottling" -Value 0
        Set-RegistryValue -Path $keyPath -Name "TdrLevel" -Value 0
        Set-RegistryValue -Path $keyPath -Name "TdrDelay" -Value 0
    }
    
    # Настройки NVIDIA Control Panel через реестр
    $nvidiaControlPath = "HKCU:\SOFTWARE\NVIDIA Corporation\Global\NVTweak"
    Set-RegistryValue -Path $nvidiaControlPath -Name "NoOverlay" -Value 1
    Set-RegistryValue -Path $nvidiaControlPath -Name "NoSplash" -Value 1
}

# Настройки для AMD
if ($isAMD) {
    Write-Host "`nПрименение настроек AMD..." -ForegroundColor Cyan
    
    # Поиск ключа AMD в реестре
    $amdKeys = Get-ChildItem -Path $amdPath -ErrorAction SilentlyContinue | Where-Object {
        $_.GetValue("DriverDesc") -like "*AMD*" -or $_.GetValue("DriverDesc") -like "*Radeon*"
    }
    
    foreach ($key in $amdKeys) {
        $keyPath = $key.PSPath
        Write-Host "Настройка ключа: $keyPath" -ForegroundColor Yellow
        
        # Настройки производительности AMD
        Set-RegistryValue -Path $keyPath -Name "PP_ThermalAutoThrottlingEnable" -Value 0
        Set-RegistryValue -Path $keyPath -Name "PP_ThermalAutoThrottlingEnable" -Value 0
        Set-RegistryValue -Path $keyPath -Name "PP_PhmUseDummyBackEnd" -Value 0
    }
}

# Настройки DirectX и графики
Write-Host "`nНастройка DirectX и графики..." -ForegroundColor Cyan

$directXPath = "HKCU:\SOFTWARE\Microsoft\DirectDraw"
Set-RegistryValue -Path $directXPath -Name "DisableAGPSupport" -Value 0

$graphicsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-RegistryValue -Path $graphicsPath -Name "VisualFXSetting" -Value 2

# Отключение ненужных визуальных эффектов
$visualEffectsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-RegistryValue -Path $visualEffectsPath -Name "VisualFXSetting" -Value 2

# Настройка приоритета GPU
Write-Host "`nНастройка приоритета GPU..." -ForegroundColor Cyan

$gpuPriorityPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-RegistryValue -Path $gpuPriorityPath -Name "GPU Priority" -Value 8
Set-RegistryValue -Path $gpuPriorityPath -Name "Scheduling Category" -Value "High"

# Отключение Hardware Acceleration для браузеров (опционально)
Write-Host "`nНастройка браузеров..." -ForegroundColor Cyan

$chromePath = "HKCU:\SOFTWARE\Policies\Google\Chrome"
Set-RegistryValue -Path $chromePath -Name "HardwareAccelerationModeEnabled" -Value 1

$firefoxPath = "HKCU:\SOFTWARE\Mozilla\Firefox"
Set-RegistryValue -Path $firefoxPath -Name "layers.acceleration.disabled" -Value 0

Write-Host "`n=== Оптимизация видеокарты завершена ===" -ForegroundColor Green
Write-Host "Рекомендуется перезагрузить компьютер для применения изменений." -ForegroundColor Yellow
Write-Host "`nДополнительно рекомендуется:" -ForegroundColor Cyan
Write-Host "1. Обновить драйверы видеокарты до последней версии" -ForegroundColor White
Write-Host "2. Настроить профили в панели управления видеокарты" -ForegroundColor White
Write-Host "3. Использовать MSI Afterburner для мониторинга" -ForegroundColor White
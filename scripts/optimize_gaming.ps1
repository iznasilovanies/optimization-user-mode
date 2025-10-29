# Скрипт оптимизации для игр
# Требует запуск от имени администратора

Write-Host "=== Оптимизация для игр ===" -ForegroundColor Green

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

# 1. Настройка Game Mode
Write-Host "`n1. Настройка Game Mode..." -ForegroundColor Cyan

$gameModePath = "HKCU:\SOFTWARE\Microsoft\GameBar"
Set-RegistryValue -Path $gameModePath -Name "AllowAutoGameMode" -Value 1
Set-RegistryValue -Path $gameModePath -Name "AutoGameModeEnabled" -Value 1
Set-RegistryValue -Path $gameModePath -Name "UseNexusForGameBarEnabled" -Value 0

# 2. Отключение Game DVR и записи
Write-Host "`n2. Отключение Game DVR..." -ForegroundColor Cyan

$gameDvrPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
Set-RegistryValue -Path $gameDvrPath -Name "AppCaptureEnabled" -Value 0
Set-RegistryValue -Path $gameDvrPath -Name "GameDVR_Enabled" -Value 0
Set-RegistryValue -Path $gameDvrPath -Name "HistoricalCaptureEnabled" -Value 0
Set-RegistryValue -Path $gameDvrPath -Name "MicrophoneEnabled" -Value 0

# 3. Настройка приоритетов для игр
Write-Host "`n3. Настройка приоритетов для игр..." -ForegroundColor Cyan

$gamesPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
Set-RegistryValue -Path $gamesPath -Name "GPU Priority" -Value 8
Set-RegistryValue -Path $gamesPath -Name "Priority" -Value 6
Set-RegistryValue -Path $gamesPath -Name "Scheduling Category" -Value "High"
Set-RegistryValue -Path $gamesPath -Name "SFIO Priority" -Value "High"

# 4. Оптимизация DirectX
Write-Host "`n4. Оптимизация DirectX..." -ForegroundColor Cyan

$directXPath = "HKCU:\SOFTWARE\Microsoft\DirectDraw"
Set-RegistryValue -Path $directXPath -Name "DisableAGPSupport" -Value 0

$direct3DPath = "HKCU:\SOFTWARE\Microsoft\Direct3D"
Set-RegistryValue -Path $direct3DPath -Name "DisableAGPSupport" -Value 0

# 5. Настройка звука для игр
Write-Host "`n5. Настройка звука для игр..." -ForegroundColor Cyan

$audioPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
Set-RegistryValue -Path $audioPath -Name "DisableProtectedAudioDG" -Value 1

# Отключение звуковых эффектов
$soundEffectsPath = "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio"
Set-RegistryValue -Path $soundEffectsPath -Name "DisableAudioEnhancement" -Value 1

# 6. Оптимизация мыши для игр
Write-Host "`n6. Оптимизация мыши для игр..." -ForegroundColor Cyan

$mousePath = "HKCU:\Control Panel\Mouse"
Set-RegistryValue -Path $mousePath -Name "MouseSpeed" -Value 0
Set-RegistryValue -Path $mousePath -Name "MouseThreshold1" -Value 0
Set-RegistryValue -Path $mousePath -Name "MouseThreshold2" -Value 0

# 7. Настройка клавиатуры
Write-Host "`n7. Настройка клавиатуры..." -ForegroundColor Cyan

$keyboardPath = "HKCU:\Control Panel\Keyboard"
Set-RegistryValue -Path $keyboardPath -Name "KeyboardDelay" -Value 0
Set-RegistryValue -Path $keyboardPath -Name "KeyboardSpeed" -Value 48

# 8. Отключение ненужных служб для игр
Write-Host "`n8. Отключение ненужных служб для игр..." -ForegroundColor Cyan

$gamingServicesToDisable = @(
    "WSearch",
    "SysMain", 
    "BITS",
    "WerSvc",
    "DiagTrack",
    "OneDrive",
    "Spooler",
    "Fax",
    "WbioSrvc",
    "TabletInputService"
)

foreach ($service in $gamingServicesToDisable) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq "Running") {
                Stop-Service -Name $service -Force
            }
            Set-Service -Name $service -StartupType Disabled
            Write-Host "Отключена служба: $service" -ForegroundColor Green
        }
    } catch {
        Write-Host "Ошибка отключения службы $service" -ForegroundColor Red
    }
}

# 9. Настройка Steam
Write-Host "`n9. Настройка Steam..." -ForegroundColor Cyan

$steamPath = "HKCU:\SOFTWARE\Valve\Steam"
Set-RegistryValue -Path $steamPath -Name "EnableOverlay" -Value 0
Set-RegistryValue -Path $steamPath -Name "EnableScreenshots" -Value 0
Set-RegistryValue -Path $steamPath -Name "EnableDesktopTheater" -Value 0

# 10. Оптимизация для VR (если используется)
Write-Host "`n10. Настройка VR..." -ForegroundColor Cyan

$vrPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Holographic"
Set-RegistryValue -Path $vrPath -Name "FirstRunSucceeded" -Value 1
Set-RegistryValue -Path $vrPath -Name "SpatialAudioEnabled" -Value 1

# 11. Настройка приоритетов процессов
Write-Host "`n11. Настройка приоритетов процессов..." -ForegroundColor Cyan

# Создание скрипта для установки высокого приоритета для игр
$priorityScript = @"
# Скрипт для установки высокого приоритета для игровых процессов
`$gameProcesses = @("steam.exe", "csgo.exe", "dota2.exe", "valorant.exe", "league of legends.exe", "fortnite.exe", "apex.exe", "pubg.exe")

foreach (`$process in `$gameProcesses) {
    `$procs = Get-Process -Name `$process -ErrorAction SilentlyContinue
    foreach (`$proc in `$procs) {
        `$proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        Write-Host "Установлен высокий приоритет для: `$(`$proc.ProcessName)" -ForegroundColor Green
    }
}
"@

$priorityScriptPath = "$env:TEMP\SetGamePriority.ps1"
$priorityScript | Out-File -FilePath $priorityScriptPath -Encoding UTF8

# 12. Настройка Windows Defender исключений
Write-Host "`n12. Настройка Windows Defender исключений..." -ForegroundColor Cyan

$gameFolders = @(
    "C:\Program Files (x86)\Steam",
    "C:\Program Files\Steam", 
    "C:\Program Files (x86)\Origin",
    "C:\Program Files\Origin",
    "C:\Program Files (x86)\Epic Games",
    "C:\Program Files\Epic Games",
    "C:\Program Files (x86)\Ubisoft",
    "C:\Program Files\Ubisoft"
)

foreach ($folder in $gameFolders) {
    if (Test-Path $folder) {
        try {
            Add-MpPreference -ExclusionPath $folder
            Write-Host "Добавлено исключение для: $folder" -ForegroundColor Green
        } catch {
            Write-Host "Ошибка добавления исключения для: $folder" -ForegroundColor Red
        }
    }
}

# 13. Создание игрового профиля питания
Write-Host "`n13. Создание игрового профиля питания..." -ForegroundColor Cyan

try {
    # Создание пользовательской схемы питания
    $powerConfig = @"
# Создание игрового профиля питания
powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c "Gaming Performance"
powercfg /setactive "Gaming Performance"

# Настройка параметров для игр
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2
powercfg /setacvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 2

# Применение настроек
powercfg /setactive SCHEME_CURRENT
"@

    $powerScriptPath = "$env:TEMP\GamingPowerConfig.cmd"
    $powerConfig | Out-File -FilePath $powerScriptPath -Encoding UTF8
    Invoke-Expression "& '$powerScriptPath'"
    Write-Host "Создан игровой профиль питания" -ForegroundColor Green
} catch {
    Write-Host "Ошибка создания профиля питания: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Оптимизация для игр завершена ===" -ForegroundColor Green
Write-Host "`nДополнительные рекомендации:" -ForegroundColor Cyan
Write-Host "1. Запустите скрипт SetGamePriority.ps1 перед игрой" -ForegroundColor White
Write-Host "2. Настройте параметры в панели управления видеокарты" -ForegroundColor White
Write-Host "3. Используйте MSI Afterburner для мониторинга FPS" -ForegroundColor White
Write-Host "4. Закройте ненужные программы перед игрой" -ForegroundColor White
Write-Host "5. Проверьте настройки в игре (VSync, Fullscreen, etc.)" -ForegroundColor White
# Скрипт мониторинга производительности ПК
# Показывает ключевые метрики производительности

Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "    PC PERFORMANCE MONITOR" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta

# Функция для получения информации о системе
function Get-SystemInfo {
    Write-Host "`n=== ИНФОРМАЦИЯ О СИСТЕМЕ ===" -ForegroundColor Green
    
    # Процессор
    $cpu = Get-WmiObject -Class Win32_Processor
    Write-Host "Процессор: $($cpu.Name)" -ForegroundColor White
    Write-Host "Ядра: $($cpu.NumberOfCores) физических, $($cpu.NumberOfLogicalProcessors) логических" -ForegroundColor White
    Write-Host "Базовая частота: $([math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz" -ForegroundColor White
    
    # Память
    $memory = Get-WmiObject -Class Win32_PhysicalMemory
    $totalMemory = ($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB
    Write-Host "`nПамять: $([math]::Round($totalMemory, 2)) GB" -ForegroundColor White
    
    # Видеокарта
    $gpu = Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -notlike "*Basic*"}
    Write-Host "`nВидеокарта:" -ForegroundColor White
    foreach ($card in $gpu) {
        Write-Host "  - $($card.Name)" -ForegroundColor White
        if ($card.AdapterRAM) {
            $vram = [math]::Round($card.AdapterRAM / 1MB, 0)
            Write-Host "    VRAM: $vram MB" -ForegroundColor White
        }
    }
    
    # Диски
    $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
    Write-Host "`nДиски:" -ForegroundColor White
    foreach ($disk in $disks) {
        $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSpace = [math]::Round($disk.Size / 1GB, 2)
        $usedSpace = $totalSpace - $freeSpace
        $usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)
        Write-Host "  - $($disk.DeviceID) $freeSpace GB свободно из $totalSpace GB ($usagePercent% использовано)" -ForegroundColor White
    }
}

# Функция для мониторинга производительности в реальном времени
function Start-PerformanceMonitoring {
    param($Duration = 60)
    
    Write-Host "`n=== МОНИТОРИНГ ПРОИЗВОДИТЕЛЬНОСТИ ===" -ForegroundColor Green
    Write-Host "Мониторинг в течение $Duration секунд..." -ForegroundColor Cyan
    Write-Host "Нажмите Ctrl+C для остановки`n" -ForegroundColor Yellow
    
    $startTime = Get-Date
    $counter = 0
    
    while ((Get-Date) -lt $startTime.AddSeconds($Duration)) {
        $counter++
        
        # Очистка экрана (кроме первой итерации)
        if ($counter -gt 1) {
            Clear-Host
            Write-Host "===============================================" -ForegroundColor Magenta
            Write-Host "    PC PERFORMANCE MONITOR - LIVE" -ForegroundColor Magenta
            Write-Host "===============================================" -ForegroundColor Magenta
        }
        
        # CPU использование
        $cpuUsage = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
        Write-Host "`nCPU Использование: $([math]::Round($cpuUsage.Average, 1))%" -ForegroundColor White
        
        # Память
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $usedMemory = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 0)
        $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 0)
        $memoryPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 1)
        Write-Host "Память: $usedMemory MB / $totalMemory MB ($memoryPercent%)" -ForegroundColor White
        
        # Диск
        $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}
        if ($disk) {
            $diskUsage = Get-Counter -Counter "\PhysicalDisk(_Total)\% Disk Time" -SampleInterval 1 -MaxSamples 1
            Write-Host "Диск C: Использование: $([math]::Round($diskUsage.CounterSamples[0].CookedValue, 1))%" -ForegroundColor White
        }
        
        # Сетевые адаптеры
        $networkAdapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.Name -notlike "*Loopback*"}
        Write-Host "`nАктивные сетевые адаптеры:" -ForegroundColor White
        foreach ($adapter in $networkAdapters) {
            $stats = Get-NetAdapterStatistics -Name $adapter.Name
            $bytesReceived = [math]::Round($stats.BytesReceived / 1MB, 2)
            $bytesSent = [math]::Round($stats.BytesSent / 1MB, 2)
            Write-Host "  - $($adapter.Name): RX: $bytesReceived MB, TX: $bytesSent MB" -ForegroundColor White
        }
        
        # Топ процессы по CPU
        Write-Host "`nТоп-5 процессов по CPU:" -ForegroundColor White
        $topProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
        foreach ($process in $topProcesses) {
            $cpuTime = [math]::Round($process.CPU, 2)
            $memoryMB = [math]::Round($process.WorkingSet / 1MB, 1)
            Write-Host "  - $($process.ProcessName): CPU: $cpuTime сек, RAM: $memoryMB MB" -ForegroundColor White
        }
        
        # Температура (если доступно)
        try {
            $temperature = Get-WmiObject -Namespace "root\OpenHardwareMonitor" -Class Sensor | Where-Object {$_.SensorType -eq "Temperature" -and $_.Name -like "*CPU*"}
            if ($temperature) {
                Write-Host "`nТемпература CPU: $($temperature.Value)°C" -ForegroundColor White
            }
        } catch {
            # OpenHardwareMonitor не установлен
        }
        
        # Время работы
        $uptime = (Get-Date) - $startTime
        Write-Host "`nВремя мониторинга: $($uptime.Minutes) мин $($uptime.Seconds) сек" -ForegroundColor Cyan
        
        Start-Sleep -Seconds 2
    }
}

# Функция для проверки игровой производительности
function Test-GamingPerformance {
    Write-Host "`n=== ТЕСТ ИГРОВОЙ ПРОИЗВОДИТЕЛЬНОСТИ ===" -ForegroundColor Green
    
    # Проверка DirectX
    Write-Host "`nПроверка DirectX..." -ForegroundColor Cyan
    try {
        $directXVersion = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "Version" -ErrorAction SilentlyContinue
        if ($directXVersion) {
            Write-Host "DirectX версия: $($directXVersion.Version)" -ForegroundColor White
        } else {
            Write-Host "DirectX не найден в реестре" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Ошибка проверки DirectX" -ForegroundColor Red
    }
    
    # Проверка игровых служб
    Write-Host "`nПроверка игровых служб..." -ForegroundColor Cyan
    $gamingServices = @("AudioSrv", "AudioEndpointBuilder", "PlugPlay")
    foreach ($service in $gamingServices) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            $status = if ($svc.Status -eq "Running") { "Запущена" } else { "Остановлена" }
            $color = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
            Write-Host "  - $service : $status" -ForegroundColor $color
        }
    }
    
    # Проверка Game Mode
    Write-Host "`nПроверка Game Mode..." -ForegroundColor Cyan
    try {
        $gameMode = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue
        if ($gameMode) {
            $status = if ($gameMode.AllowAutoGameMode -eq 1) { "Включен" } else { "Отключен" }
            $color = if ($gameMode.AllowAutoGameMode -eq 1) { "Green" } else { "Yellow" }
            Write-Host "Game Mode: $status" -ForegroundColor $color
        }
    } catch {
        Write-Host "Game Mode: Не удалось проверить" -ForegroundColor Red
    }
    
    # Проверка приоритетов процессов
    Write-Host "`nПроверка приоритетов процессов..." -ForegroundColor Cyan
    $gameProcesses = Get-Process | Where-Object {$_.ProcessName -like "*steam*" -or $_.ProcessName -like "*game*" -or $_.ProcessName -like "*csgo*" -or $_.ProcessName -like "*dota*"}
    if ($gameProcesses) {
        Write-Host "Найдены игровые процессы:" -ForegroundColor White
        foreach ($process in $gameProcesses) {
            Write-Host "  - $($process.ProcessName): $($process.PriorityClass)" -ForegroundColor White
        }
    } else {
        Write-Host "Игровые процессы не найдены" -ForegroundColor Yellow
    }
}

# Главное меню
function Show-Menu {
    Write-Host "`n=== ГЛАВНОЕ МЕНЮ ===" -ForegroundColor Cyan
    Write-Host "1. Показать информацию о системе" -ForegroundColor White
    Write-Host "2. Мониторинг производительности (60 сек)" -ForegroundColor White
    Write-Host "3. Мониторинг производительности (пользовательское время)" -ForegroundColor White
    Write-Host "4. Тест игровой производительности" -ForegroundColor White
    Write-Host "5. Выход" -ForegroundColor White
    Write-Host ""
}

# Основной цикл
do {
    Show-Menu
    $choice = Read-Host "Выберите опцию (1-5)"
    
    switch ($choice) {
        "1" {
            Get-SystemInfo
            Read-Host "`nНажмите Enter для продолжения"
        }
        "2" {
            Start-PerformanceMonitoring -Duration 60
        }
        "3" {
            $duration = Read-Host "Введите время мониторинга в секундах"
            if ($duration -match '^\d+$') {
                Start-PerformanceMonitoring -Duration [int]$duration
            } else {
                Write-Host "Неверный формат времени" -ForegroundColor Red
            }
        }
        "4" {
            Test-GamingPerformance
            Read-Host "`nНажмите Enter для продолжения"
        }
        "5" {
            Write-Host "Выход из программы" -ForegroundColor Green
            break
        }
        default {
            Write-Host "Неверный выбор. Попробуйте снова." -ForegroundColor Red
        }
    }
} while ($choice -ne "5")

Write-Host "`nСпасибо за использование PC Performance Monitor!" -ForegroundColor Magenta
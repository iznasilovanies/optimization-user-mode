# Скрипт оптимизации служб Windows для максимальной производительности
# Требует запуск от имени администратора

Write-Host "=== Оптимизация служб Windows ===" -ForegroundColor Green

# Функция для безопасного отключения службы
function Disable-ServiceSafely {
    param($ServiceName, $DisplayName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force
                Write-Host "Остановлена служба: $DisplayName" -ForegroundColor Yellow
            }
            Set-Service -Name $ServiceName -StartupType Disabled
            Write-Host "Отключена служба: $DisplayName" -ForegroundColor Green
        } else {
            Write-Host "Служба не найдена: $DisplayName" -ForegroundColor Red
        }
    } catch {
        Write-Host "Ошибка при работе со службой $DisplayName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Список служб для отключения
$servicesToDisable = @(
    @{Name="WSearch"; Display="Windows Search"},
    @{Name="SysMain"; Display="Superfetch/SysMain"},
    @{Name="wuauserv"; Display="Windows Update"},
    @{Name="BITS"; Display="Background Intelligent Transfer Service"},
    @{Name="WerSvc"; Display="Windows Error Reporting Service"},
    @{Name="DiagTrack"; Display="Connected User Experiences and Telemetry"},
    @{Name="OneDrive"; Display="OneDrive"},
    @{Name="WinDefend"; Display="Windows Defender Antivirus Service"},
    @{Name="Spooler"; Display="Print Spooler"},
    @{Name="Fax"; Display="Fax Service"},
    @{Name="WbioSrvc"; Display="Windows Biometric Service"},
    @{Name="TabletInputService"; Display="Touch Keyboard and Handwriting Panel Service"},
    @{Name="WSearch"; Display="Windows Search"},
    @{Name="TrkWks"; Display="Distributed Link Tracking Client"},
    @{Name="Browser"; Display="Computer Browser"},
    @{Name="upnphost"; Display="UPnP Device Host"},
    @{Name="SSDPSRV"; Display="SSDP Discovery"},
    @{Name="FDResPub"; Display="Function Discovery Resource Publication"},
    @{Name="FDResPub"; Display="Function Discovery Resource Publication"}
)

Write-Host "Отключение ненужных служб..." -ForegroundColor Cyan

foreach ($service in $servicesToDisable) {
    Disable-ServiceSafely -ServiceName $service.Name -DisplayName $service.Display
}

# Настройка приоритетов для игровых служб
Write-Host "`nНастройка приоритетов служб..." -ForegroundColor Cyan

# Включение и настройка игровых служб
$gamingServices = @(
    @{Name="AudioSrv"; Display="Windows Audio"},
    @{Name="AudioEndpointBuilder"; Display="Windows Audio Endpoint Builder"},
    @{Name="PlugPlay"; Display="Plug and Play"}
)

foreach ($service in $gamingServices) {
    try {
        Set-Service -Name $service.Name -StartupType Automatic
        Write-Host "Настроена служба: $($service.Display)" -ForegroundColor Green
    } catch {
        Write-Host "Ошибка настройки службы $($service.Display): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Оптимизация служб завершена ===" -ForegroundColor Green
Write-Host "Рекомендуется перезагрузить компьютер для применения изменений." -ForegroundColor Yellow
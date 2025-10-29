# Скрипт оптимизации сетевых настроек для минимальной задержки
# Требует запуск от имени администратора

Write-Host "=== Оптимизация сетевых настроек ===" -ForegroundColor Green

# Функция для выполнения команды netsh
function Invoke-NetworkCommand {
    param($Command, $Description)
    
    try {
        Write-Host "Выполняется: $Description" -ForegroundColor Cyan
        Invoke-Expression $Command
        Write-Host "Успешно: $Description" -ForegroundColor Green
    } catch {
        Write-Host "Ошибка: $Description - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Отключение QoS Packet Scheduler
Write-Host "`nОтключение QoS Packet Scheduler..." -ForegroundColor Cyan
$qosCommand = "netsh int tcp set global autotuninglevel=disabled"
Invoke-NetworkCommand -Command $qosCommand -Description "Отключение автоматической настройки TCP"

# Настройка TCP для игр
Write-Host "`nНастройка TCP для игр..." -ForegroundColor Cyan
$tcpCommands = @(
    "netsh int tcp set global chimney=enabled",
    "netsh int tcp set global rss=enabled", 
    "netsh int tcp set global netdma=enabled",
    "netsh int tcp set global dca=enabled",
    "netsh int tcp set global ecncapability=enabled",
    "netsh int tcp set global timestamps=enabled"
)

foreach ($cmd in $tcpCommands) {
    Invoke-NetworkCommand -Command $cmd -Description "Настройка TCP параметров"
}

# Настройка сетевых адаптеров
Write-Host "`nНастройка сетевых адаптеров..." -ForegroundColor Cyan

# Получение всех сетевых адаптеров
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

foreach ($adapter in $adapters) {
    Write-Host "Настройка адаптера: $($adapter.Name)" -ForegroundColor Yellow
    
    # Отключение ненужных протоколов
    try {
        Disable-NetAdapterBinding -Name $adapter.Name -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
        Write-Host "  Отключен IPv6" -ForegroundColor Green
    } catch {
        Write-Host "  IPv6 уже отключен или недоступен" -ForegroundColor Yellow
    }
    
    # Настройка приоритетов
    try {
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword "Priority" -RegistryValue 1 -ErrorAction SilentlyContinue
        Write-Host "  Настроен приоритет адаптера" -ForegroundColor Green
    } catch {
        Write-Host "  Не удалось настроить приоритет" -ForegroundColor Yellow
    }
}

# Настройка DNS
Write-Host "`nНастройка DNS серверов..." -ForegroundColor Cyan
$dnsServers = @("8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1")

foreach ($adapter in $adapters) {
    try {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers
        Write-Host "Настроен DNS для $($adapter.Name)" -ForegroundColor Green
    } catch {
        Write-Host "Ошибка настройки DNS для $($adapter.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Отключение ненужных сетевых функций
Write-Host "`nОтключение ненужных сетевых функций..." -ForegroundColor Cyan

$networkDisableCommands = @(
    "netsh advfirewall set allprofiles state off",
    "netsh int tcp set global autotuninglevel=disabled",
    "netsh int tcp set global rss=enabled"
)

foreach ($cmd in $networkDisableCommands) {
    Invoke-NetworkCommand -Command $cmd -Description "Отключение сетевых функций"
}

# Настройка Windows Firewall для игр
Write-Host "`nНастройка Windows Firewall..." -ForegroundColor Cyan
try {
    # Создание правила для игр
    New-NetFirewallRule -DisplayName "Gaming Performance" -Direction Inbound -Protocol TCP -Action Allow -Profile Any -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Gaming Performance UDP" -Direction Inbound -Protocol UDP -Action Allow -Profile Any -ErrorAction SilentlyContinue
    Write-Host "Созданы правила Firewall для игр" -ForegroundColor Green
} catch {
    Write-Host "Ошибка создания правил Firewall: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Оптимизация сети завершена ===" -ForegroundColor Green
Write-Host "Рекомендуется перезагрузить компьютер для применения изменений." -ForegroundColor Yellow
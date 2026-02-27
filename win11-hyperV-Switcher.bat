@echo off
setlocal enabledelayedexpansion
title Windows11 虚拟化组件检测切换工具
color 0A

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo ==========================================
    echo   错误：请右键点击并选择“以管理员身份运行”
    echo ==========================================
    pause
    exit
)

:menu
cls
echo ==========================================
echo             虚拟化组件深度检测
echo ==========================================
echo.
echo [当前系统状态检测中，请稍候...]

:: --- 状态检测逻辑 ---
:: 1. 检测 BCD 引导状态
set "bcd_status=开启 (Auto)"
bcdedit | findstr /i "hypervisorlaunchtype" | findstr /i "off" >nul && set "bcd_status=关闭 (Off)"

:: 2. 检测 Windows 5 项核心功能状态
set "hv_status=检测中"
set "vmp_status=检测中"
set "whp_status=检测中"
set "sandbox_status=检测中"
set "wsl_status=检测中"

for /f "tokens=3" %%a in ('dism /online /get-featureinfo /featurename:Microsoft-Hyper-V-All ^| findstr /i "状态"') do set "hv_status=%%a"
for /f "tokens=3" %%a in ('dism /online /get-featureinfo /featurename:VirtualMachinePlatform ^| findstr /i "状态"') do set "vmp_status=%%a"
for /f "tokens=3" %%a in ('dism /online /get-featureinfo /featurename:HypervisorPlatform ^| findstr /i "状态"') do set "whp_status=%%a"
for /f "tokens=3" %%a in ('dism /online /get-featureinfo /featurename:Containers-DisposableClientVM^| findstr /i "状态"') do set "sandbox_status=%%a"
for /f "tokens=3" %%a in ('dism /online /get-featureinfo /featurename:Microsoft-Windows-Subsystem-Linux ^| findstr /i "状态"') do set "wsl_status=%%a"

:: 3. 新增：检测内存完整性与固件保护状态
set "hvci_status=开启"
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" 2>nul | findstr "0x1" >nul || set "hvci_status=关闭"

set "sg_status=开启"
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" 2>nul | findstr "0x1" >nul || set "sg_status=关闭"

echo ------------------------------------------
echo 1. 引导层 (BCD Launch Type) : %bcd_status%
echo 2. Hyper-V 组件             : %hv_status%
echo 3. 虚拟机平台 (VMP)         : %vmp_status%
echo 4. 虚拟机监控程序平台 (WHP) : %whp_status%
echo 5. Windows 沙盒             : %sandbox_status%
echo 6. WSL (Linux 子系统)       : %wsl_status%
echo ------------------------------------------
echo 7. 内存完整性  : %hvci_status%
echo 8. 固件保护    : %sg_status%
echo ------------------------------------------
echo 重要提示：彻底关闭 HyperV环境需要
echo 手动关闭“内存完整性”和“固件保护”
echo 恢复 HyperV 环境不需要重新打开
echo ------------------------------------------
echo.
echo [1] 关闭 HyperV 环境 (关闭上述1~6项)
echo [2] 进入 HyperV 环境 (开启上述1~6项)
echo [0] 退出
echo ==========================================
echo.

set /p choice="请输入选项: "

if "%choice%"=="1" goto disable_all
if "%choice%"=="2" goto enable_all
if "%choice%"=="0" exit
goto menu

:disable_all
echo.
echo 正在深度禁用所有虚拟化功能，请稍候...
bcdedit /set hypervisorlaunchtype off >nul 2>&1
dism /online /disable-feature /featurename:Microsoft-Hyper-V-All /norestart
dism /online /disable-feature /featurename:VirtualMachinePlatform /norestart
dism /online /disable-feature /featurename:HypervisorPlatform /norestart
dism /online /disable-feature /featurename:Containers-DisposableClientVM /norestart
dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
goto finish

:enable_all
echo.
echo 正在启用所有虚拟化功能，请稍候...
bcdedit /set hypervisorlaunchtype auto >nul 2>&1
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /norestart
dism /online /enable-feature /featurename:VirtualMachinePlatform /norestart
dism /online /enable-feature /featurename:HypervisorPlatform /norestart
dism /online /enable-feature /featurename:Containers-DisposableClientVM /norestart
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
goto finish

:finish
echo.
echo ==========================================
echo 操作完成！
echo 注意：请确认 7、8 项已关闭，并【重启电脑】生效。
echo ==========================================
set /p rn="是否现在立即重启电脑？(Y重启电脑/N返回菜单): "
if /i "%rn%"=="Y" (
    shutdown /r /t 0
) else (
    goto menu

)

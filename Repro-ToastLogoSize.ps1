<#
.SYNOPSIS
    Repro: a toast's appLogoOverride image renders at 60 px instead of 48 px (at 100% scaling) until 
    a toast from a Windows app (e.g. Snipping Tool) has been shown.

.DESCRIPTION
    Self-contained. Needs Windows PowerShell 5.1 (powershell.exe), not pwsh 7. No admin rights needed.
    It writes a generated 192x192 PNG to %TEMP%\ToastLogoSizeRepro and registers a throwaway AUMID
    ("Repro.ToastLogoSize") under HKCU. Run with -Cleanup to remove both.

    Steps:
      1. Reboot and sign in. Do not open any other app yet (a toast from any packaged app can end the
         bad state, so run this before Teams/Outlook/etc. show notifications).
      2. Run this script. Note the logo size: it is 60 px.
      3. Take a screenshot with Snipping Tool (Win+Shift+S). Wait for its "Snip saved" toast.
      4. Run this script again. The same toast now shows the logo at 48 px.

    Measure by taking a screenshot after step 2 and after step 4 (use a phone photo for step 2 if you do
    not want to trigger the packaged toast first) and compare the logo's edge-to-edge size in pixels.

.PARAMETER Cleanup
    Remove the registry key and the generated icon.
#>
[CmdletBinding()]
param([switch]$Cleanup)

$ErrorActionPreference = 'Stop'

$Aumid = 'Repro.ToastLogoSize'
$Dir   = Join-Path $env:TEMP 'ToastLogoSizeRepro'
$Png   = Join-Path $Dir 'logo.png'
$Key   = "HKCU:\Software\Classes\AppUserModelId\$Aumid"

if ($Cleanup) {
    Remove-Item -LiteralPath $Key -Recurse -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Dir -Recurse -ErrorAction SilentlyContinue
    Write-Host 'Removed the repro registration and icon.'
    return
}

# Environment details worth putting in the report.
$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Write-Host ("Windows build : {0}.{1} ({2})" -f $cv.CurrentBuild, $cv.UBR, $cv.DisplayVersion)
Write-Host ("Up since      : {0}" -f (Get-CimInstance Win32_OperatingSystem).LastBootUpTime)
Write-Host 'Display scale : check Settings > System > Display (the issue was seen at 100%).'

# Generate the logo: a flat colour square with a white border and diagonals, so its edges are easy to measure.
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$bmp = New-Object System.Drawing.Bitmap 192, 192
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(0, 168, 150))
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 6
$g.DrawRectangle($pen, 3, 3, 185, 185)
$g.DrawLine($pen, 0, 0, 191, 191)
$g.DrawLine($pen, 191, 0, 0, 191)
$g.Dispose(); $pen.Dispose()
$bmp.Save($Png, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# Register the AUMID the same way a plain unpackaged app can: HKCU only, no shortcut, no package.
New-Item -Path $Key -Force | Out-Null
Set-ItemProperty -Path $Key -Name DisplayName -Value 'Toast logo size repro'
Set-ItemProperty -Path $Key -Name IconUri     -Value $Png

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$src = [System.Security.SecurityElement]::Escape($Png)
$xml = @"
<toast duration="long">
  <visual>
    <binding template="ToastGeneric">
      <text>appLogoOverride size repro</text>
      <text>Compare the logo size before and after a Snipping Tool toast</text>
      <image placement="appLogoOverride" src="$src" />
    </binding>
  </visual>
</toast>
"@

$doc = New-Object Windows.Data.Xml.Dom.XmlDocument
$doc.LoadXml($xml)
$toast = New-Object Windows.UI.Notifications.ToastNotification $doc
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Aumid).Show($toast)
Write-Host 'Toast sent.'

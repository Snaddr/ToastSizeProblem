# Toast `appLogoOverride` renders at 60 px instead of 48 px after a reboot

## Problem

On Windows 11 (build 26200, 100% display scaling), a toast's `appLogoOverride` image is drawn at
**60 px instead of 48 px** after a reboot. The size stays wrong for every app until `ShellExperienceHost`
has rendered a toast that has **no `appLogoOverride`**, for example the toast Snipping Tool shows after a
snip. From then on `appLogoOverride` images are drawn at 48 px.

Restarting `ShellExperienceHost` puts it back to 60 px.

It does not depend on package identity, hero images, buttons, or which app sends the toast. A toast without
`appLogoOverride` from any app fixes it for all apps, even when that app's banners are switched off.

## Reproduce

Use Windows PowerShell 5.1 (`powershell.exe`, not `pwsh`). The commands use the built-in Windows PowerShell
toast identity and an image that ships with Windows, so nothing else is needed.

1. Reboot, sign in, and open nothing else.
2. Run **command 1**. The logo is **60 px**.
3. Run **command 2** (a toast without `appLogoOverride`).
4. Run **command 1** again. The same logo is now **48 px**.

To repeat without a reboot, run `Stop-Process -Name ShellExperienceHost -Force`, wait a few seconds, and
run command 1 again. It is back to 60 px.

Photograph the screen to measure the first toast. A Snipping Tool screenshot is itself a toast without
`appLogoOverride`, so it would change the state before you have measured it.

### Command 1: with `appLogoOverride` (`1-With-AppLogoOverride.ps1`)

```powershell
$x=[Windows.Data.Xml.Dom.XmlDocument,Windows.Data.Xml.Dom.XmlDocument,ContentType=WindowsRuntime]::new();$x.LoadXml("<toast><visual><binding template='ToastGeneric'><text>With appLogoOverride</text><text>Second line of text</text><text>Third line of text</text><image placement='appLogoOverride' src='$env:windir\Web\Screen\img105.jpg'/></binding></visual></toast>");[Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime]::CreateToastNotifier('{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe').Show([Windows.UI.Notifications.ToastNotification]::new($x))
```

### Command 2: without `appLogoOverride` (`2-Without-AppLogoOverride.ps1`)

```powershell
$x=[Windows.Data.Xml.Dom.XmlDocument,Windows.Data.Xml.Dom.XmlDocument,ContentType=WindowsRuntime]::new();$x.LoadXml("<toast><visual><binding template='ToastGeneric'><text>Without appLogoOverride</text><text>Second line of text</text><text>Third line of text</text></binding></visual></toast>");[Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime]::CreateToastNotifier('{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe').Show([Windows.UI.Notifications.ToastNotification]::new($x))
```

If `img105.jpg` is missing on a machine, any image path works.

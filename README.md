# kWSL.cmd - KDE Neon 5.20 for WSL1

- KDE Neon 5.20
- Simplicity - Use the 'one-liner' below and everything is configured (see Wiki for a list of custom packages)
- Runs on Windows Server 2019 or Windows 10 Version 1803 (or newer, including Server Core)
- xRDP Display Server, no additional X Server downloads required
- RDP Audio playback enabled (YouTube playback in browser works)

![Screenshot](screenshot.png)

**INSTRUCTIONS:  From an elevated CMD.EXE prompt change to your desired install directory and type/paste the following command:**

```
PowerShell -executionpolicy bypass -command "wget https://github.com/DesktopECHO/kWSL/raw/master/kWSL.cmd -UseBasicParsing -OutFile kWSL.cmd ; .\kWSL.cmd"
```

You will be asked a few questions.  The install script finds the current DPI scaling, you can set your own value if needed:

```
[kWSL Installer 20201122-1]

Enter a unique name for your kWSL distro or hit Enter to use default.
Keep this name simple, no space or underscore characters [kWSL]: Neon
Port number for xRDP traffic or hit Enter to use default [3399]: 13399
Port number for SSHd traffic or hit Enter to use default [3322]: 13322
Set a custom DPI scale, or hit Enter for Windows default [1.5]: 1.25
[Not recommended!] Type X to eXclude from Windows Defender:

Installing kWSL Distro [Neon] to "C:\Neon"
This will take a few minutes, please wait...
```

The installer will download all the necessary packages to convert the Windows Store Ubuntu 20.04 image into KDE Neon 5.20.

```
[16:12:55] Installing Ubuntu 20.04 LTS (~1m30s)
[16:13:22] Git clone and update repositories (~1m15s)
[16:14:28] Purge un-needed packages (~1m30s)
[16:14:57] Migrate Ubuntu LTS to Neon (~3m15s)
[16:16:09] KDE Plasma 5.20 (~11m30s)
[16:21:17] Install Mozilla Seamonkey, media playback components (~1m30s)
[16:34:33] Cleaning up packages no longer needed (~0m45s)
```

Near the end of the script you will be prompted to create a non-root user.  This user will be automatically added to sudo'ers.

```
Open Windows Firewall Ports for xRDP, SSH, mDNS...
Building RDP Connection file, Console link, Init system...
Building Uninstaller... [C:\Neon\Uninstall Neon.cmd]
Building Scheduled Task...
SUCCESS: The scheduled task "Neon" has successfully been created.

      Start: Sun 11/22/2020 @ 16:12
        End: Sun 11/22/2020 @ 16:34
   Packages: 1323

  - xRDP Server listening on port 13399 and SSHd on port 13322.

  - Links for GUI and Console sessions have been placed on your desktop.

  - (Re)launch init from the Task Scheduler or by running the following command:
    schtasks /run /tn Neon

 Neon Installation Complete!  GUI will start in a few seconds...
```

Currently you should see approximately 962 packages installed.  If the number reported is much lower it means you had a download failure and need to re-start the install.

Upon completion you'll be logged into an attractive and fully functional KDE Plasma.  A scheduled task is created for starting/managing kWSL. 

   **If you want to start kWSL at boot (like a service with no console window) do the following:**

   - Right-click the task in Task Scheduler, click properties
   - Click the checkboxes for **Run whether user is logged on or not** and **Hidden** then click **OK**
   - Enter your Windows credentials when prompted

   Reboot your PC.  kWSL will automatically start at boot, no need to login to Windows.

**Convert to WSL2 Virtual Machine:**
-  kWSL will convert easily to WSL2.  Only one additional adjustment is necessary; change the hostname in the .RDP connection file to point at the WSL2 instance.  First convert the instance:
    ```wsl --set-version [DistroName] 2```
- Assuming we're using the default distro name of ```kWSL``` (use whatever name you assigned to the distro)  Right click the .RDP file in Windows, click Edit.  Change the Computer name to your Windows hostname plus **```-kWSL.local```**  Your WSL2 instance resolves seamlessly using multicast DNS  
- For example, if the current value is ```LAPTOP:3399```, change it to ```LAPTOP-kwsl.local:3399``` and save the RDP connection file.  

**Make it your own:**

From a security standpoint, it would be best to fork this project so you (and only you) control the packages and files in the repository.

- Sign into GitHub and fork this project
- Edit ```kWSL.cmd```.  On line 2 you will see ```SET GITORG=DesktopECHO``` - Change ```DesktopECHO``` to the name of your own repository.
- Customize the script any way you like.
- Launch the script using your repository name:
 ```PowerShell -executionpolicy bypass -command "wget https://github.com/YOUR-REPO-NAME/kWSL/raw/master/kWSL.cmd -UseBasicParsing -OutFile kWSL.cmd ; .\kWSL.cmd"```

**Quirks Addressed / Additional Info:**
- kWSL should work fine with an X Server instead of xRDP but this has not been thoroughly tested.  The file ```/etc/profile.d/WinNT.sh``` contains WSL-centric environment variables that may need adjustment such as LIBGL_ALWAYS_INDIRECT.
- WSL1 Has issues with the latest libc6 library.  The package is being held until fixes from MS are released over Windows Update.  Unmark and update libc6 after MS releases the update.
- WSL1 Doesn't work with PolicyKit.  Pulled-in GKSU and dependencies to accommodate GUI apps that need elevated rights.  
- Patched KDE Lockscreen and KDE Activity Manager to resolve shared memory and PolicyKit issues
- Rolled back and held xRDP until the current update is better-behaved (xrdp-chansrv high CPU %)
- Current versions of Chrome / Firefox / Konqueror do not work in WSL1; Mozilla Seamonkey is included as the 'official' stable/maintained browser
- Installed image consumes approximately 2.6 GB of disk space
- KDE uses the Breeze-Dark theme and Windows fonts (Segoe UI / Consolas)
- Copy/Paste of text and images work reliably between Windows and Linux
- This is a basic installation of KDE to save bandwidth.  If you want the **complete** KDE Desktop environment run ```sudo apt-get install kde-full``` 

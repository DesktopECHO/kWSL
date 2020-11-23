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

The installer will download all the necessary packages to convert the Windows Store Ubuntu 20.04 image into KDE Neon 5.20.  Reference times will vary depending on system performance and the presence of antivrirus software.

```
[22:54:42] Installing Ubuntu 20.04 LTS (~1m30s)
[22:55:27] Git clone and update repositories (~1m15s)
[22:56:33] Remove un-needed packages (~1m30s)
[22:57:10] Migrate Ubuntu LTS to Neon (~3m15s)
[22:58:31] KDE Plasma 5.20 (~11m30s)
[23:03:51] Install Mozilla Seamonkey and media playback (~1m30s)
[23:04:18] Final clean-up (~0m45s)
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

Currently you should see approximately 1331 packages installed.   

Upon completion you'll be logged into an attractive and fully functional KDE Plasma.  A scheduled task is created for starting/managing kWSL. 

   **If you want to start kWSL at boot (like a service with no console window) do the following:**

   - Right-click the task in Task Scheduler, click properties
   - Click the checkboxes for **Run whether user is logged on or not** and **Hidden** then click **OK**
   - Enter your Windows credentials when prompted

   Reboot your PC when complete.  kWSL will automatically start at boot, no need to login to Windows.

**xWSL is configured to use Bonjour (Multicast DNS) for easy access in WSL2**

Example of conversion to WSL2 on machine name "ENVY":
- Stop WSL on ENVY:
````wsl --shutdown````
- Convert the instance to WSL2:
````wsl --set-version kWSL 2````
- Restart xWSL Instance:
````schtasks /run /tn kWSL````
- Adjust the RDP file saved on the desktop to now point at the new WSL2 instance:
````ENVY-kWSL.local:3399````

**Make it your own:**

From a security standpoint, it would be best to fork this project so you (and only you) control the packages and files in the repository.

- Sign into GitHub and fork this project
- Edit ```kWSL.cmd```.  On line 2 you will see ```SET GITORG=DesktopECHO``` - Change ```DesktopECHO``` to the name of your own repository.
- Customize the script any way you like.
- Launch the script using your repository name:
 ```PowerShell -executionpolicy bypass -command "wget https://github.com/YOUR-REPO-NAME/kWSL/raw/master/kWSL.cmd -UseBasicParsing -OutFile kWSL.cmd ; .\kWSL.cmd"```

**Quirks / Limitations / Additional Info:**
- kWSL should work fine with an X Server instead of xRDP but this has not been thoroughly tested.  The file ```/etc/profile.d/kWSL.sh``` contains WSL-centric environment variables that may need adjustment such as LIBGL_ALWAYS_INDIRECT.
- Plasma-discover doesn't work in Server 2019 / Win 10-1809 
- WSL1 Doesn't work with PolicyKit.  Enabled kdesu for apps needing elevated rights (plasma-discover, ksystemlog, muon, root console.)    
- Patched KDE Activity Manager to disable WAL in sqlite3.  KDE Lockscreen is disabled.  
- xrdp 0.9.13 rebuilt thanks to http://packages.rusoft.ru/ppa/rusoft/xrdp/
- Current versions of Chrome / Firefox / Konqueror do not work in WSL1; Mozilla Seamonkey is included as the 'official' stable/maintained browser
- Installed image consumes approximately 2.6 GB of disk space
- Apt-fast was added to improve download speed and reliability.
- KDE uses the Breeze-Dark theme and Windows fonts (Segoe UI / Consolas)
- Copy/Paste of text and images work reliably between Windows and Linux
- This is a basic installation of KDE to save bandwidth.  If you want the **complete** KDE Desktop environment (+3GB Disk) run ```sudo pkcon -y install neon-all``` 

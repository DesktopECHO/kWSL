# kWSL.cmd • KDE Neon 6 Desktop for WSL

  - Online install of KDE Neon in WSL, accessible via RDP.  If you prefer GTK, see [**xWSL**](https://github.com/DesktopECHO/xWSL) or [**Kali-xRDP**](https://github.com/DesktopECHO/Kali-xRDP)
  - Runs on Windows 10 / Windows Server 2019 and newer, including Hyper-V Core.
  - xRDP Display Server; no additional Xserver download/configuration required.
  - High-quality RDP audio playback; video playback and YouTube work well and maintains audio sync.
  - If you want to accesss kWSL remotely, Chrome Remote Desktop is pre-installed (Never expose RDP servers to the Internet.) Configuration steps are [**here**](https://github.com/DesktopECHO/kWSL/wiki/Enable-Chrome-Remote-Desktop)

![image](https://user-images.githubusercontent.com/33142753/100149597-d3d57d80-2e74-11eb-899a-a7476b016e27.png)

**IMPORTANT!** 
 - Windows 11 requires 22H2 Update *(Sun Valley 2, September 2022)*
 - Windows Server / Windows 10 require latest updates from Windows Update.

## INSTALL INSTRUCTIONS
From an elevated CMD.EXE prompt change to your desired install directory and type/paste the following command:

```
PowerShell -executionpolicy bypass -command "wget https://github.com/DesktopECHO/kWSL/raw/master/kWSL.cmd -UseBasicParsing -OutFile kWSL.cmd ; .\kWSL.cmd"
```

You will be asked a few questions.  The install script will determine current DPI scaling, or set your own value if preferred:

```
[KDE Neon 6 Installer for WSL v.20240301]

Set a name for this KDE Neon instance.  Hit Enter to use default.
Keep this name simple, no space or underscore characters [Neon]:
Port number for xRDP traffic or hit Enter to use default [3399]:
Port number for SSHd traffic or hit Enter to use default [3322]:
Set a custom DPI scale, or hit Enter for Windows default [1]: 1.25
[Not recommended!] Type X to eXclude from Windows Defender:

Installing kWSL Distro [Neon] to "C:\Neon"
This will take a few minutes, please wait...
```

The installer will download all the necessary packages to transform the [Jammy base image](https://cloud-images.ubuntu.com/jammy/current/) into KDE Neon User Edition.  Reference times will vary depending on system performance and the presence of antivirus software.  A fast system/network can complete the install in about 10 minutes.

```
[19:19:01] Importing distro userspace (~0m30s)
[19:19:14] Git clone and update repositories (~1m00s)
[19:20:22] Prepare userspace (~1m00s)
[19:20:45] Installing Prerequisites (~2m00s)
[19:23:12] KDE Neon 6 (~7m00s)
[19:31:12] Web Browser, CRD, VLC 4 (~1m00s)
[19:32:10] Cleaning-up... (~0m15s)
```

Near the end of the script you will be prompted to create a non-root user.  This user will be automatically added to sudo'ers.

```
Open Windows Firewall Ports for xRDP, SSH, mDNS...
Building RDP Connection file, Console link, Init system...
Building Scheduled Task...
SUCCESS: The scheduled task "Neon" has successfully been created.

      Start: Fri 03/01/2024 @ 19:18
        End: Fri 03/01/2024 @ 19:32
   Packages: 1434

  - xRDP Server listening on port 3399 and SSHd on port 3322.

  - Links for GUI and Console sessions have been placed on your desktop.

  - (Re)launch init from the Task Scheduler or by running the following command:
    schtasks /run /tn Neon

 Neon Installation Complete!  GUI will start in a few secon
```

**When the script completes you will be logged-in to your KDE Neon Desktop.** 

## Optional: Set KDE to start at boot (like a service) instead of starting at login (default setting)

 - Right-click the task in Task Scheduler, click properties
 - Click the checkbox for **Run whether user is logged on or not** and click **OK**
 - Click the Triggers tab and change the trigger from **At log on** to **At startup**
 - Enter your Windows credentials when prompted
 
 Reboot your PC when complete and kWSL will startup automatically.

## Optional: Convert WSL Instance

Example of conversion to WSL2:
 - Stop WSL instance (Using default instance name _NeonWSL_ in this example):
 ````wsl --terminate Neon````
 - Convert the instance to WSL2:
 ````wsl --set-version Neon 2````
 - Restart KDE Neon Instance under WSL2:
 ````schtasks /run /tn Neon````

Procedure is the same for switching back to WSL1: ````wsl --set-version NeonWSL 1````

## Make it your own

It's best to fork this project so you (and only you) control the packages and files in the deployment.

- Sign into GitHub and fork this project
- Edit ```kWSL.cmd```.  On line 2 you will see ```SET GITORG=DesktopECHO``` - Change ```DesktopECHO``` to the name of your own repository.
- Customize the script any way you like.
- Launch the script using your repository name:
 ```PowerShell -executionpolicy bypass -command "wget https://github.com/YOUR-REPO-NAME/kWSL/raw/master/kWSL.cmd -UseBasicParsing -OutFile kWSL.cmd ; .\kWSL.cmd"```

## Quirks / Limitations / Additional Info:

- H.264 Enabled in XRDP
- Kwin desktop composition is enabled by default 
- When you log out out of a KDE session the WSL instance is restarted.  This is the equivilent to having a freshly-booted desktop environment at every login, but the 'reboot' process only takes about 5 seconds.  
- kWSL should work fine with an X Server instead of xRDP but this has not been thoroughly tested.  The file ```/etc/profile.d/kWSL.sh``` contains WSL-centric environment variables that may need adjustment such as LIBGL_ALWAYS_INDIRECT.
- Plasma-discover doesn't work in Server 2019 / Win 10 v.1809 -- The installer will remove it if you're running an affected OS. 
- WSL1 Doesn't work with PolicyKit.  Enabled kdesu/gksu for apps needing elevated rights (plasma-discover, ksystemlog, muon, root console.)    
- KDE Lockscreen is not implemented (due to policykit)  
- Patched KDE Activity Manager to disable WAL in sqlite3. 
- Mozilla Seamonkey is included as a stable/maintained browser. 
- QtWebEngine (Chromium-based) browsers like Falkon and Konqueror now work. (July/21)
- Installed image consumes approximately 3 GB of disk space.
- Apt-fast added to improve download speed and reliability.
- Default installation uses the Breeze theme and Windows fonts (Segoe UI / Cascadia Code)
- This is a basic installation of KDE to save bandwidth.  If you want the **complete** KDE Desktop environment (+3GB Disk) run ```sudo pkcon -y install neon-all``` 

![image](https://user-images.githubusercontent.com/33142753/100148485-33cb2480-2e73-11eb-932b-54e34b445575.png)

![image](https://user-images.githubusercontent.com/33142753/100385367-c21ce300-2ff8-11eb-9276-6f51b366839f.png)

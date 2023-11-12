<img src=icon.png width=128>

# display-is-sleeping

This is a small Objective-C program that will report the current sleeping/awake status of the attached displays. It makes use of the **NSWorkspace** [`ScreensDidSleep`][1] and [`ScreensDidWake`][2] Notifications, and uses a small LaunchAgent to subscribe to those events and keep the status current.

The program can be called on its own without arguments and will simply return a POSIX exit code of 0 (sleeping) or 1 (awake) to indicate the screen's status. So you can run something like:

```bash
if ! display-is-sleeping ; then echo "screen is awake!"; fi
```
or more concisely
```bash
display-is-sleeping || echo "screen is awake!"
```

### Installation (and Uninstallation)

Clone this repo (if you don't know how to do that, click the green **Code** button above, then **Download ZIP**). Once you have the bits on your disk, open a Terminal in the directory that contains the cloned files and run the command below:

```bash
./setup.sh --install
```

This will copy the binary to `/usr/local/bin` (you can use a different directory if you like, by editing the setup script and changing the `BINDIR` variable at the top). It also creates and starts up the LaunchAgent. From then on, you can use the `display-is-sleeping` command in your scripts.

To **Uninstall**, simply re-run the script, passing `--uninstall`:
```bash
./setup.sh --uninstall
```
This will unload and remove the LaunchAgent, stop any background processes and remove the command itself from wherever it was installed.

### Usage

Example use in a script
```bash
if display-is-sleeping ; then
  # ...put code here to run if the screen is dark
else
  # ...code to run if the screen is awake
fi
```

Get current status as a string (prints `true` or `false`)
```bash
display-is-sleeping --status
```

Please report any bugs or issues you encounter. This idea was inspired by [this AskDifferent post](https://apple.stackexchange.com/questions/466236/check-if-display-sleep-on-apple-silicon-in-bash).

[1]: https://developer.apple.com/documentation/appkit/nsworkspacescreensdidsleepnotification
[2]: https://developer.apple.com/documentation/appkit/nsworkspacescreensdidwakenotification

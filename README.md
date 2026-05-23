# Question Practice Timer ⏱️

A lightweight, elegant, **always-on-top floating stopwatch** built natively for macOS using SwiftUI and AppKit. Designed specifically for developers, students, and professionals to track their velocity, manage pacing, and gather actionable performance insights during mock interviews, competitive programming, or exam preparation.

---

## ✨ Features

* **HUD Floating Window:** A beautiful, translucent backdrop that hovers smoothly over any active application (IDE, browser, PDF) without stealing focus.
* **Dual Time Tracking:** * **Top Display:** Precision stopwatch tracking current question time down to **Minutes : Seconds : Tenths of a second**.
    * **Bottom Display:** Persistent session counter capturing accumulated **Hours : Minutes**.
* **Completely Customizable Hotkeys:** Remap your workflow entirely inside the app. Supports quick binding to **Left/Right Shift, Left/Right Command, Left/Right Option, Tab, or Backslash (`\`)**.
* **Automatic Performance Analytics:** When you end a session, a native dashboard automatically calculates:
    * Total questions solved.
    * Average velocity per question.
    * Your fastest (highest velocity) and slowest (lowest velocity) outliers.
* **Interactive Velocity Graph:** Displays a clean, native SwiftUI Bar Chart visualizing your pace across every question split.
* **One-Click Snapshot:** Save your chart directly to your Desktop as a `.png` file to log your historical training progress.

---

## 🛠️ Controls & Configuration

Click the **Gear Icon** in the top-right corner of the floating widget to slide down the settings panel and configure your custom hotkeys:

1.  **Start / Next Question:** Starts the clock on your first tap. Every subsequent press logs your split and seamlessly advances to the next question.
2.  **Pause / Resume:** Freezes the current frame cleanly without dropping accumulated time metadata.
3.  **End Session:** Stops all timers, package logs, and automatically displays the interactive Analytics window.

---

## 🚀 Installation & Running

### Option 1: Direct Download (Pre-compiled Binary)
1.  Navigate to the **[Releases](https://github.com/YOUR_USERNAME/Question-Practice-Timer/releases)** tab on the right side of this repository.
2.  Download the `Question_Practice_Timer.zip` bundle.
3.  Double-click to unzip, and drag the app into your `Applications` folder.

> ⚠️ **Gatekeeper Note:** Because this app is self-distributed, macOS may show a warning saying it cannot be verified. To open it, **Right-Click (or Control-Click) the app icon -> Select Open -> Click Open Anyway**.

### Option 2: Build From Source (Xcode)
1.  Clone this repository to your local machine:
    ```bash
    git clone [https://github.com/YOUR_USERNAME/Question-Practice-Timer.git](https://github.com/YOUR_USERNAME/Question-Practice-Timer.git)
    ```
2.  Open `QuestionPracticeTimer.xcodeproj` inside Xcode.
3.  Go to the **Signing & Capabilities** tab of your app target and ensure **App Sandbox -> File Access -> User Selected Files** is configured to **Read/Write** (required for saving screenshots).
4.  Press `Cmd + R` to compile and launch!

---

## 🛑 How to Quit the App
To keep the UI as minimal as possible, standard window close buttons are hidden. To exit the app completely:
1.  Click on the floating timer widget to bring it into focus.
2.  Press **`Cmd + Q`** on your keyboard to terminate the process cleanly.

---

## 📐 Technologies Used
* **SwiftUI** & **Charts** – Native layout and vector rendering engines.
* **AppKit (`NSWindow`, `NSEvent`)** – Always-on-top paneling behavior and global keyboard event tapping interfaces.

---
*Created as an optimized companion for rigorous problem-solving training.*
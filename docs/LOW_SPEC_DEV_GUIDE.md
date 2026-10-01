# ⚡ Low-Spec Hardware Optimization & Development Guide

> **Target Machine Profile:** Intel Core i5 (2 cores / 4 threads @ ~1.80GHz), 8GB RAM, integrated graphics, Linux.  
> **Mission:** Keep development lightning-fast, prevent system freezes/OOM crashes, and ensure smooth Flutter compilation throughout the Shipaton 2026 sprint.

---

## 1. Golden Rules for Modest Hardware

1. **Never Run an Android Emulator:** An Android Virtual Device (AVD) consumes 2.5–3.5 GB of RAM and 100% of 2 CPU cores during startup. Instead, **use a physical Android phone via USB or Wi-Fi `adb`**.
2. **Develop Headless First:** Write business logic, crypto, safety filters, and state with fast mock unit tests. A `flutter test` completes in 2 seconds and uses < 200 MB RAM.
3. **Cap Gradle Daemon Memory:** Default Gradle settings will greedily allocate 4+ GB of RAM, triggering system-wide Linux Out-Of-Memory (OOM) killer freezes.
4. **Enable a Linux Swapfile:** If your machine currently has 0B Swap, a single heavy Gradle compilation can freeze the desktop. Adding a 4GB swapfile provides an emergency safety cushion.

---

## 2. Emergency Swap Setup (Recommended)

To prevent your system from locking up during initial Gradle builds:

```bash
# 1. Create a 4GB swap file
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile

# 2. Set up Linux swap area
sudo mkswap /swapfile
sudo swapon /swapfile

# 3. Verify swap is active
free -h

# 4. Make persistent across reboots (append to /etc/fstab)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 3. Gradle & JVM Tuning

Create or edit `~/.gradle/gradle.properties` (or `android/gradle.properties`):

```properties
# Limit Gradle daemon memory allocation
org.gradle.jvmargs=-Xmx1536m -XX:MaxMetaspaceSize=512m -XX:+UseParallelGC

# Restrict parallel worker threads to match 2-core CPU
org.gradle.workers.max=2

# Do not keep idle daemons alive indefinitely
org.gradle.daemon.idletimeout=60000

# Enable build cache for fast incremental re-compilations
org.gradle.caching=true
```

---

## 4. Test-Driven Development with Mock Services

To avoid waiting for 3-minute app rebuilds when tweaking features, EasyEnglish provides mock implementations for all core subsystems:

```dart
// test/mocks/mock_services.dart
class MockSignalingService implements ISignalingService {
  @override
  Stream<SignalingEvent> get events => Stream.value(SignalingEvent.paired('mock_peer'));
  
  @override
  Future<void> sendOffer(String sdp) async {}
}

class MockRevenueCatService implements IRevenueCatService {
  bool isPro = false;
  
  @override
  Future<bool> checkIsPro() async => isPro;
}
```

### Fast Test Command:
```bash
# Runs in < 3 seconds, instant feedback loop without launching device:
flutter test test/unit/
```

---

## 5. Physical Device Debugging Workflow

### Connect via ADB:
```bash
# 1. Check connected device
adb devices

# 2. Run directly on device in debug mode:
flutter run -d <device_id>
```

### High-Speed Hot Reload:
Once the app is running on your phone:
- Press `r` in the terminal for **hot reload** (< 500ms).
- Press `R` for **hot restart** (< 2s).
- Avoid terminating and restarting the `flutter run` process unnecessarily.

### Optional Screen Mirroring (Lightweight):
Use `scrcpy` instead of an emulator to view your phone's screen on Linux with minimal CPU overhead:
```bash
scrcpy --max-size 1024 --video-bit-rate 2M --max-fps 30
```

---

## 6. Lightweight Editor Setup

- **Recommended:** VS Code with minimal extensions (Dart + Flutter only) or NeoVim / Helix.
- **Avoid:** Heavy IDEs like Android Studio unless specifically modifying Android NDK / native C++ build files.
- Close unused browser tabs (especially heavy media / YouTube tabs) when compiling release APKs.

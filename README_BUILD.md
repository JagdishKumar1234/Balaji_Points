# Balaji Points - Release Build Instructions

## 🚀 Quick Start (3 Commands)

```bash
cd /Users/jagdishkumar/Documents/Development/ReactNative/Project/BalajiPoints/balaji_points
chmod +x build_release.sh
./build_release.sh
```

Answer `y` when prompted. Done!

---

## 📦 What You Get

After running `./build_release.sh`:

1. **APK** (38 MB)
   - `build/app/outputs/flutter-apk/app-release.apk`
   - For direct installation on devices
   - Use: `adb install -r app-release.apk`

2. **AAB** (15-20 MB)
   - `build/app/outputs/bundle/release/app-release.aab`
   - For Google Play Store
   - Optimized for different device configurations

3. **Report** (3 KB)
   - `BUILD_REPORT.txt`
   - Contains build info, paths, and next steps

---

## 📝 Documentation

- **BUILD_RELEASE_GUIDE.md** - Full detailed guide
- **QUICK_RELEASE.txt** - Quick reference and commands
- **README_BUILD.md** - This file

---

## ✨ Features Included

✓ Carpenter summary with expand/collapse  
✓ Numbered bill history (#1, #2, #3...)  
✓ Site filter dropdown  
✓ Date range filtering  
✓ 12-hour time format  
✓ Bill numbers (BP-SBH-20260710-384721)  
✓ Professional UI improvements  

---

## 📱 Installation Options

### Test on Device
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Upload to Play Store
1. Go to Google Play Console
2. Create new release
3. Upload: `build/app/outputs/bundle/release/app-release.aab`
4. Add release notes
5. Submit

### Firebase Distribution
Upload APK and send link to testers

---

## 🔢 Version Management

Current: `1.0.17+26`

The script auto-increments build number:
- Each run: `+26 → +27 → +28 → +29`...

---

## 📋 Checklist

- [ ] All tests passing
- [ ] Run: `./build_release.sh`
- [ ] Test APK on device
- [ ] Review BUILD_REPORT.txt
- [ ] Upload AAB to Play Store
- [ ] Add release notes
- [ ] Submit for review

---

## ⚡ Time Estimates

| Step | Time |
|------|------|
| Clean | 1 min |
| APK | 3-4 min |
| AAB | 1-2 min |
| Report | <1 min |
| **Total** | **5-7 min** |

---

## 🆘 Troubleshooting

**"Command not found"?**
```bash
chmod +x build_release.sh
```

**"Flutter not found"?**
```bash
flutter --version
```

**"Build failed"?**
```bash
flutter clean && flutter pub get && ./build_release.sh
```

---

## 📚 More Help

See detailed docs:
- `BUILD_RELEASE_GUIDE.md` - Complete guide
- `QUICK_RELEASE.txt` - Quick commands

---

**Ready?** Run: `./build_release.sh` 🚀

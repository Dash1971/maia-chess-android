# Native transport host checks

These checks compile the platform-independent policy used by ChessnutBridge. The automatic script requires a JDK, curl and unzip, and does not require Flutter, Android SDK, a BLE device or JUnit. It downloads the official JetBrains Kotlin 2.2.0 compiler (78,044,187 bytes, capped at 80 MiB), verifies the pinned SHA256 `1adb6f1a5845ba0aa5a59e412e44c8e405236b957de1a9683619f1dca3b16932` from the official release asset metadata, and cleans all temporary files on exit. CI runs this script in the normal Checks test job. From the repository root:

```sh
tool/test_board_native.sh
```

With an existing Kotlin installation, the equivalent manual commands are: From the repository root:

```sh
kotlinc android/app/src/main/kotlin/com/dash1971/maia_chess/ElectronicBoardProtocol.kt android/native_test/ElectronicBoardProtocolTest.kt -include-runtime -d /tmp/maia-native-protocol-checks.jar
java -jar /tmp/maia-native-protocol-checks.jar
```

Verified with official JetBrains Kotlin 2.2.0 and OpenJDK 21. Actual Android bridge compilation belongs to the Dev build. Hardware acceptance remains separate; these checks cannot certify BLE or physical behavior.

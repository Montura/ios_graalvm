# ios_graalvm

This sample demonstrates a problem with running the Java code (processed by graalvm-native-image) on ARMv8 (64-bit) (tested on AppleA7).

[This commit in graal v22.0](https://github.com/oracle/graal/commit/8dcf51febac87c9cc60d320b56c1d7cce9e8121b#diff-e20cc7c705399bb4add81b0214fd61b4d7fcc8321666b139d16f6268d58b97e5R571) cause native-image crash on ARMv8 (64-bit):
  * `Fatal error: Current target does not support the following CPU features that are required by the image: [FP, ASIMD]`
   
I dumped CPU options info for AppleA7 CPU
```
CPU: ARM64_V8
  hw.optional.floatingpoint:   val = 0, errCode = -1, support = false
  hw.optional.neon:            val = 0, errCode = -1, support = false
  hw.optional.armv8_crc32:     val = 0, errCode = -1, support = false
  hw.optional.armv8_1_atomics: val = 0, errCode = -1, support = false
``` 

I fixed this problem in my [fork v22.0.1](https://github.com/Montura/graal/commit/5913a046569c5042edfa5b00a6fc8dd58391954e)

## Scenario
1. Use static libs:
 * `graal-svm-arm64-ios.a v22.0` build from [graal fork v22.0](https://github.com/Montura/graal/tree/release/graal-vm/22.0)
 * `graal-svm-arm64-ios.a v22.0.1` build from [graal fork v22.0.1](https://github.com/Montura/graal/tree/release/graal-vm/22.0.1)
 * `jdk-arm64-ios.a`  build from [labs-openjdk fork](https://github.com/Montura/labs-openjdk-11/tree/release/jvmci/22.0)
3. Use java code 
```
public class Test {
    public static void main(String[] args) {
        System.out.println("Hello from Java");
    }
}
```
2. Process it with [native-image-maven-plugin](https://mvnrepository.com/artifact/org.graalvm.nativeimage/native-image-maven-plugin)
  * got `Java.o` and `llvm.o`
3. Link `java.o` + `llvm.o` + `jdk-arm64-ios.a` + `graal-svm-arm64-ios.a`
4. Run on AppleA7
5. Expected ouput: ```Hello from Java```

## Steps to reproduce
1. Download https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.0.0.2/graalvm-ce-java11-darwin-amd64-22.0.0.2.tar.gz
2. Unpack the archive and set `JAVA_HOME` to `graalvm-ce-java11-darwin-amd64-22.0.0.2/Contents/Home`
3. Run ```mvn clean package -Pgraal-ios``` from repo directory
4. Open `ios-graalvm.xcodeproj`
  * scheme `ios-graalvm-22.0.1` works fine and prints: ```Hello from Java```
  * scheme `ios-graalvm-22.0` crashes: 

```
Fatal error: Current target does not support the following CPU features that are required by the image: [FP, ASIMD]

Threads:
  0x0000000102a01e00 STATUS_IN_JAVA (PREVENT_VM_FROM_REACHING_SAFEPOINT) "main" - 0x00000001017d5938, stack(0x000000016f6b8000,0x000000016f7b4000)

Stacktrace for the failing thread 0x0000000102a01e00:
  SP 0x000000016f7b3700 IP 0x00000001006a9dec  [image code] com.oracle.svm.core.jdk.VMErrorSubstitutions.shutdown(VMErrorSubstitutions.java:116)
  SP 0x000000016f7b3700 IP 0x00000001006a9dec  [image code] com.oracle.svm.core.jdk.VMErrorSubstitutions.shouldNotReachHere(VMErrorSubstitutions.java:109)
  SP 0x000000016f7b3730 IP 0x000000010071487c  [image code] com.oracle.svm.core.util.VMError.shouldNotReachHere(VMError.java:65)
  SP 0x000000016f7b3750 IP 0x00000001006640e8  [image code] com.oracle.svm.core.aarch64.AArch64CPUFeatureAccess.verifyHostSupportsArchitecture(AArch64CPUFeatureAccess.java:148)
  SP 0x000000016f7b37e0 IP 0x000000010065a188  [image code] com.oracle.svm.core.JavaMainWrapper.runCore(JavaMainWrapper.java:131)
  SP 0x000000016f7b37e0 IP 0x000000010065a188  [image code] com.oracle.svm.core.JavaMainWrapper.run(JavaMainWrapper.java:186)
  SP 0x000000016f7b3830 IP 0x000000010067260c  [image code] com.oracle.svm.core.code.IsolateEnterStub.JavaMainWrapper_run_5087f5482cc9a6abc971913ece43acb471d2631b(IsolateEnterStub.java:0)

VM mutexes:
  mutex "mainVMOperationControlWorkQueue" is unlocked.
  mutex "referencePendingList" is unlocked.
  mutex "thread" is unlocked.

Heap settings and statistics:
  Supports isolates: false
  Object reference size: 8
  Aligned chunk size: 1048576
  Incremental collections: 0
  Complete collections: 0
```

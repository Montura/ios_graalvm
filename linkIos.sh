mainClass=$1
mainClassObj=$2
xcodePlatform=$3
arch=$4
targetArch=$5
minIosVersion=$6
graal_svm_ios_static_lib=$7
jdk_ios_static_lib=$8

echo mainClass: $mainClass
echo mainClassObj: $mainClassObj

echo xcodePlatform = $xcodePlatform
echo arch = $arch
echo targetArch = $targetArch
echo minIosVersion = $minIosVersion

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] || [ -z "$7" ] || [ -z "$8" ]
  then
    echo "Args error"
    exit 1
fi

ls -la $graal_svm_ios_static_lib
ls -la $jdk_ios_static_lib

sysroot=$(xcrun --sdk $xcodePlatform --show-sdk-path)
echo sysroot=$sysroot

tempPath=target/tmp$arch

llvm_o=$(find $tempPath -name llvm.o)
graal_o=$(find $tempPath -name $mainClassObj)

cp "$graal_o" $tempPath
cp "$llvm_o" $tempPath

targetName=graal_$arch.dylib
target=target/ios/$targetName

mkdir -p target/ios

echo linking: $llvm_o + $graal_o

clang++ -O1 \
  $graal_o $llvm_o $graal_svm_ios_static_lib $jdk_ios_static_lib \
  -o $target \
  -dynamiclib -shared \
  -Wl,-x -undefined dynamic_lookup \
  -lz -ldl \
  -lpthread \
  -Wl,-framework,Foundation -Wl,-framework,CoreServices \
  -w -fPIC -arch $targetArch -mios-version-min=$minIosVersion \
  -isysroot $sysroot
#   > clang.log 2>&1

if [ ! -f $target ]
then
  exit 2
fi

install_name_tool -id @loader_path/Frameworks/$targetName $target
otool -L $target
nm -mg $target > target/symbols_nm_mg_$targetName.txt

echo size -l -m $target
size -l -m $target

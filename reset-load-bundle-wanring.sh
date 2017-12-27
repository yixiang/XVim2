
if [ "$1" == "" ] ; then
    echo "usage: $0 <XCODE_VERSION>"
    echo "  e.g. $0 7.3.1"
else
    defaults delete com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-$1
fi

enable root
    edit C:\ProgramData\BlueStacks_nxt\bluestacks.conf
        set anything related to "root" to "1"
    run android app root checker to verify
enable proxy
    run mitmweb
    install e.g. android app cx file manager, enable system files in settings
    edit /data/system/users/0/settings_global.xml
        https://old.reddit.com/r/BlueStacks/comments/oe2z02/bluestack_5_proxy/hwfpxte/
            <setting id="100" name="global_proxy_pac_url" value="" package="android" />
            <setting id="97" name="global_http_proxy_host" value="192.168.1.8" package="android" />
            <setting id="98" name="global_http_proxy_port" value="8080" package="android" />
            <setting id="99" name="global_http_proxy_exclusion_list" value="" package="android" />
            <setting id="96" name="http_proxy" value="192.168.1.8:8080" package="com.android.shell" />
        (use values from mitmweb console output)
install mitm cert
    mount root fs read/write
        edit C:\ProgramData\BlueStacks_nxt\Engine\Nougat64\Nougat64.bstk
            set type="Normal" for location="Root.vhd" HardDisk
        edit C:\ProgramData\BlueStacks_nxt\Engine\Nougat64\HypervVm.json
            set "ReadOnly" : false for Root.vhd Scsi Attachment
    boot bluestacks
    install android app root certificate manager
    download .cer file from http://mitm.it
    open .cer file in root certificate manager
disable proxy
    with e.g. cx file explorer edit /data/system/users/0/settings_global.xml
    ~50% mark, set global_http_proxy_host and global_http_proxy_port empty
    ~90% mark, set http_proxy empty
get remote config json over the wire
    launch medieval merge app
    check mitmweb page for the response from firebaseremoteconfig.googleapis.com
    copy as raw_response.json in this folder
    run py format-response.py
    inspect response.json
get remote config from disk
    it's in the /data directory, *firebase*.json
    copy as raw_response.json in this folder
    run py format-response.py
    inspect response.json
get dlls
    download Il2CppDumper
    get /data/lib directory
    /c/tools/Il2CppDumper-net6-v6.7.25/Il2CppDumper mmerge/lib/lib/arm64/libil2cpp.so mmerge/unzipped/assets/bin/Data/Managed/Metadata/global-metadata.dat mmerge/dumper
    use ilspy but no code b/c Il2CppDumper can't make that i guess...
    it wants System.Private.CoreLib v6.0.0.0 despite being .net framework 4?? maybe some mono thing?
        dotnet new console -f net6.0
        dotnet publish --sc
        ./bin/Debug/net6.0/win-x64/publish/System.Private.CoreLib.dll

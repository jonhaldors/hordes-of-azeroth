function Build-WineIcu([string]$LauncherSource) {
    $name = 'icu4c-78.3-Win64-MSVC2022.zip'
    $hash = '446b671f9437227daa79e221d4521d75793f9ecd65ac44c06e34dd848f201ac2'
    $folder = Join-Path $buildDir 'wine-icu'
    $archive = Join-Path $cacheDir $name
    New-Item -ItemType Directory -Force $folder, $cacheDir | Out-Null
    if (-not (Test-Path $archive) -or (Get-Sha256 $archive) -ne $hash) {
        Invoke-WebRequest "https://github.com/unicode-org/icu/releases/download/release-78.3/$name" -OutFile $archive -UseBasicParsing
        if ((Get-Sha256 $archive) -ne $hash) { throw 'ICU4C archive SHA-256 does not match.' }
    }

    $instance = (Get-CMake).Instance
    $versionFile = Join-Path $instance 'VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt'
    $compilerVersion = (Get-Content $versionFile -Raw).Trim()
    $compiler = Join-Path $instance "VC\Tools\MSVC\$compilerVersion\bin\Hostx64\x64"
    $object = Join-Path $folder 'wine-icu.obj'
    Invoke-Native 'ICU forwarder compile' (Join-Path $compiler 'cl.exe') @('/nologo', '/c', '/Zl', '/GS-', "/Fo$object", (Join-Path $LauncherSource 'wine-icu.c'))

    $files = @(
        $zip = [System.IO.Compression.ZipFile]::OpenRead($archive)
        try {
            foreach ($file in @('icuuc78.dll', 'icuin78.dll', 'icudt78.dll', 'ICU-LICENSE.txt')) {
                $entry = if ($file -eq 'ICU-LICENSE.txt') { 'LICENSE' } else { "bin64/$file" }
                $target = Join-Path $folder $file
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zip.GetEntry($entry), $target, $true)
                [pscustomobject]@{ Source = $target; Target = $file }
            }
        } finally { $zip.Dispose() }

        foreach ($name in @('icuuc', 'icuin')) {
            $def = Join-Path $LauncherSource "$name.def"
            $target = Join-Path $folder "$name.dll"
            $library = Join-Path $folder "$name.lib"
            Invoke-Native "ICU forwarder $name" (Join-Path $compiler 'link.exe') @('/nologo', '/dll', '/noentry', '/nodefaultlib', '/machine:x64', "/def:$def", "/out:$target", "/implib:$library", $object)
            [pscustomobject]@{ Source = $target; Target = "$name.dll" }
        }
    )
    (New-PackageZip 'WineIcu' $files $folder).FullName
}

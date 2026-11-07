param(
    [string]$Godot = 'D:\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [string]$JavaHome = 'D:\Programs\temurin-17.0.18',
    [string]$AndroidSdk = 'D:\Programs\Android\SDK'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $projectRoot 'build\android'
$signingDir = Join-Path $projectRoot '.android-signing'
$apk = Join-Path $buildDir 'WildInstinct.apk'
$utf8 = New-Object Text.UTF8Encoding($false)
New-Item -ItemType Directory -Force $buildDir,$signingDir | Out-Null
$credentialsPath = Join-Path $signingDir 'signing.json'
$keystore = Join-Path $signingDir 'wild-instinct.keystore'
if (-not (Test-Path -LiteralPath $credentialsPath)) {
    if (Test-Path -LiteralPath $keystore) { throw 'Keystore credentials are missing.' }
    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] 24
    $random.GetBytes($bytes)
    $random.Dispose()
    $credentials = @{alias='wildinstinct'; password=[Convert]::ToBase64String($bytes)}
    [IO.File]::WriteAllText($credentialsPath, (ConvertTo-Json $credentials), $utf8)
}
$credentials = Get-Content -Raw -LiteralPath $credentialsPath | ConvertFrom-Json
$oldJavaHome = $env:JAVA_HOME
$oldPath = $env:PATH
try {
    $env:JAVA_HOME = $JavaHome
    $env:PATH = "$JavaHome\bin;$env:PATH"
    $env:WILDINSTINCT_SIGN_PASSWORD = $credentials.password
    if (-not (Test-Path -LiteralPath $keystore)) {
        & "$JavaHome\bin\keytool.exe" -genkeypair -keystore $keystore -storetype PKCS12 -storepass:env WILDINSTINCT_SIGN_PASSWORD -keypass:env WILDINSTINCT_SIGN_PASSWORD -alias $credentials.alias -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Wild Instinct, OU=Game, O=Wild Instinct, C=RU'
        if ($LASTEXITCODE -ne 0) { throw 'Signing key creation failed.' }
    }
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $keystore.Replace('\','/')
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $credentials.alias
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $credentials.password
    & $Godot --headless --path $projectRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Project import failed.' }
    & $Godot --headless --path $projectRoot --export-release Android $apk
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $apk)) { throw 'Android export failed.' }
    & "$AndroidSdk\build-tools\36.1.0\apksigner.bat" verify --verbose --min-sdk-version 24 $apk
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    $badging = & "$AndroidSdk\build-tools\36.1.0\aapt.exe" dump badging $apk
    if ($LASTEXITCODE -ne 0) { throw 'APK manifest verification failed.' }
    if (-not ($badging -contains "sdkVersion:'24'")) { throw 'Minimum Android version must remain Android 7 / API 24.' }
    $info = @('Wild Instinct 1.1.0', 'Android 7.0+ / API 24', "SHA256: $((Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash)")
    $info += @($badging | Where-Object { $_ -match '^(package:|sdkVersion:|targetSdkVersion:|application-label:|native-code:|uses-permission:)' })
    [IO.File]::WriteAllLines((Join-Path $buildDir 'APK-info.txt'), [string[]]$info, $utf8)
    Write-Output "APK ready: $apk"
    Write-Output "Size: $([Math]::Round((Get-Item -LiteralPath $apk).Length / 1MB, 1)) MiB"
} finally {
    $env:JAVA_HOME = $oldJavaHome
    $env:PATH = $oldPath
    Remove-Item Env:\WILDINSTINCT_SIGN_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:\GODOT_ANDROID_KEYSTORE_RELEASE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:\GODOT_ANDROID_KEYSTORE_RELEASE_USER -ErrorAction SilentlyContinue
    Remove-Item Env:\GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
}

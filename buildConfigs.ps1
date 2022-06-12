param(
    [Parameter(Mandatory = $True)]
    [string]$ImagesPath
) 

function Get-FileMetaData { 
    param(
        [Parameter(Mandatory = $True)]
        [string]$File
    ) 
 
    if (!(Test-Path -Path $File)) { 
        throw "File does not exist: $File" 
        Exit 1 
    } 
 
    $tmp = Get-ChildItem $File 
    $pathname = $tmp.DirectoryName 
    $filename = $tmp.Name 
 
    $hash = @{}
    try {
        $shellobj = New-Object -ComObject Shell.Application 
        $folderobj = $shellobj.namespace($pathname) 
        $fileobj = $folderobj.parsename($filename) 
        
        for ($i = 0; $i -le 294; $i++) { 
            $name = $folderobj.getDetailsOf($null, $i);
            if ($name) {
                $value = $folderobj.getDetailsOf($fileobj, $i);
                if ($value) {
                    $hash[$($name)] = $($value)
                }
            }
        } 
    }
    finally {
        if ($shellobj) {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$shellobj) | Out-Null
        }
    }

    return New-Object PSObject -Property $hash
}

$Configs = Get-ChildItem "www/albums/" -File -Recurse | Where-Object { $_.Name -eq "config.json" }

foreach ($Config in $Configs) {
    $Year = ($Config.Directory.FullName -split '\\')[-2]
    $Album = $Config.Directory.Name
    $ImageDirectory = Join-Path $ImagesPath $Year $Album
    $Images = Get-ChildItem $ImageDirectory -Exclude "*-thumb.jpg", "cover.jpg"
    $JSON = Get-Content $Config -Raw | ConvertFrom-Json
    $Array = @()

    foreach ($Image in $Images) {
        $EXIFData = Get-FileMetaData $Image.FullName
        $Properties = [PSCustomObject]@{
            Name         = $Image.Name
            CameraModel  = $EXIFData.'Camera model'
            ExposureTime = $EXIFData.'Exposure time' -replace '\P{IsBasicLatin}'
            FStop        = $EXIFData.'F-stop'
            FocalLength  = $EXIFData.'Focal length' -replace '\P{IsBasicLatin}'
            IsoSpeed     = $EXIFData.'ISO speed'
        }
        $Array += $Properties
    }

    $Properties = [PSCustomObject]@{
        Title    = $JSON.Title
        Category = $JSON.Category
        Images   = $Array
    } | ConvertTo-Json | Out-File $Config -Force
}
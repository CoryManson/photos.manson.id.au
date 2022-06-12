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

$Years = Get-ChildItem -Path "www/albums/" -Directory | Sort-Object $_.Name -Descending

foreach ($Year in $Years) {
    $Albums = Get-Content "$($Year.FullName)/albums.json" | ConvertFrom-Json

    foreach ($Album in $Albums) {
        $ConfigPath = Join-Path $Year.FullName $Album.Name "images.json"
        $Images = Get-ChildItem (Join-Path $ImagesPath $Year.Name $Album.Name) -Exclude "*-thumb.jpg", "cover.jpg"
        $ConfigArray = @()

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
            $ConfigArray += $Properties
        }

        $Properties = [PSCustomObject]@{
            Images = $ConfigArray
        } | ConvertTo-Json | Out-File $ConfigPath -Force
    }
}
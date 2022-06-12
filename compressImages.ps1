$Images = Get-ChildItem -File -Recurse | Where-Object { $_.Extension -eq ".jpg" }

foreach ($Image in $Images) {
    $Dest = $Image.FullName -replace 'Published Images', 'Compressed Images'
    $DestFolder = $Image.DirectoryName -replace 'Published Images', 'Compressed Images'

    # Create Folder if required
    if ((Test-Path $DestFolder) -eq $false) {
        New-Item -Path $DestFolder -ItemType Directory -Force 
    }

    # Check to see if image is already compressed
    if ((Test-Path $Dest) -eq $true) {
        Write-Host "$($Image.Name) Already Exists in Destination Dir"
        continue
    }

    if ($Image.Name -match "thumb") {
        Copy-Item $Image.FullName $Dest
        continue
    }

    & ".\cjpeg.exe" -quality 90 -sample 1x1 -quant-table 2 -progressive -optimize -OutFile $Dest $Image.FullName
}
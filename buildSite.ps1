$Years = Get-ChildItem -Path "www/albums/" -Directory | Sort-Object $_.Name -Descending
$Albums = Get-ChildItem -Path "www/albums/" -Directory -Recurse | Sort-Object $_.Parent -Descending
$AlbumTemplate = Get-Content -Path "templates/album.html" -Raw
$HomeTemplate = Get-Content -Path "templates/home.html" -Raw
$ImageRootUri = "https://mansonphotography.azureedge.net/images"

foreach ($Year in $Years) {
    $Albums = Get-Content -Path "$($Year.FullName)/albums.json" | ConvertFrom-Json
    foreach ($Album in $Albums) {
        $ImagesConfig = Join-Path $Year.FullName $Album.Name "images.json"

        if ((Test-Path $ConfigPath) -ne $true) {
            Write-Host "[$($Album.Name)]: Missing images.json, skipping.."
            continue
        }
        else {
            $Images = (Get-Content -Path $ImagesConfig | ConvertFrom-Json).Images
        }

        $GalleryItems = ""

        foreach ($Image in $Images) {
            $Extension = ($Image.Name).Split('.')[-1]
            $ThumbnailFile = ($Image.Name).Split('.')[0] + "-thumb." + $Extension
            $GalleryItemBlock = @"
            <div class="isotope-item">

                <!-- Begin gallery single item -->
                <a href="$($ImageRootUri)/$($Year.Name)/$($Album.Name)/$($Image.Name)"
                    class="gallery-single-item lg-trigger"
                    data-exthumbnail="$($ImageRootUri)/$($Year.Name)/$($Album.Name)/$($ThumbnailFile)" data-sub-html="$($Image.CameraModel) @ $($Image.FStop) | $($Image.ExposureTime) | $($Image.FocalLength) | $($Image.IsoSpeed)">

                    <img src="$($ImageRootUri)/$($Year.Name)/$($Album.Name)/$($Image.Name)"
                        class="gs-item-image" alt="">
                </a>
                <!-- End gallery single item -->

            </div>
            <!-- End isotope item -->

"@
            $GalleryItems = $GalleryItems + $GalleryItemBlock
        }

        # Replace Tokens
        $HTML = $AlbumTemplate
        $HTML = $HTML -replace ('##TITLE##', "$($Album.Title) - Cory Manson Photography")
        $HTML = $HTML -replace ('##GALLERYITEMS##', $GalleryItems)
        $HTML | Out-File -FilePath (Join-Path $Year.FullName $Album.Name "index.html") -Force

        $HomeItemBlock = @"
                        <div class="isotope-item iso-height-1">

                        <!-- Begin gallery list item -->
                        <div class="gallery-list-item">

                            <!-- Begin gallery list item image -->
                            <div class="gl-item-image-wrap">

                                <!-- Begin gallery list item image inner -->
                                <a href="/albums/$($Year.Name)/$($Album.Name)" class="gl-item-image-inner">
                                    <div class="gl-item-image bg-image"
                                        style="background-image: url($($ImageRootUri)/$($Year.Name)/$($Album.Name)/cover.jpg); background-position: 50% 50%">
                                    </div>

                                    <span class="gl-item-image-zoom"></span>
                                </a>
                                <!-- End gallery list item image inner -->

                            </div>
                            <!-- End gallery list item image -->

                            <!-- Begin gallery list item info -->
                            <div class="gl-item-info">
                                <div class="gl-item-caption">
                                    <h2 class="gl-item-title"><a href="/albums/$($Year.Name)/$($Album.Name)">$($Album.Title)</a></h2>
                                    <span class="gl-item-category">$($Year.Name) - $($Album.Category)</span>
                                </div>
                            </div>
                            <!-- End gallery list item info -->

                        </div>
                        <!-- End gallery list item -->

                    </div>
                    <!-- End isotope item -->
"@

        $HomeItems = $HomeItems + $HomeItemBlock
    }
}

$HTML = $HomeTemplate
$HTML = $HTML -replace ('##GALLERIES##', $HomeItems)
$HTML | Out-File -FilePath "www/index.html" -Force

$Albums = Get-ChildItem -Path "www/albums/" -Directory -Recurse | Sort-Object $_.Parent -Descending
$AlbumTemplate = Get-Content -Path "templates/album.html" -Raw
$HomeTemplate = Get-Content -Path "templates/home.html" -Raw
$ImageRootUri = "https://mansonphotography.azureedge.net/images"

foreach ($Album in $Albums) {
    if ($Album.Name -match '^(19|20)[\d]{2,2}$') {
        Write-Host "Found Year Folder $Album, skipping"
        continue
    }

    if ((Test-Path "$($Album.FullName)/config.json") -ne $true) {
        Write-Host "[$($Album.Name)]: Missing config.json, skipping.."
        continue
    }

    $Config = Get-Content -Path "$($Album.FullName)/config.json" | ConvertFrom-Json
    $Images = $Config.Images
    $GalleryItems = ""

    foreach ($Image in $Images) {
        $Extension = ($Image).Split('.')[-1]
        $ThumbnailFile = ($Image).Split('.')[0] + "-thumb." + $Extension
        $GalleryItemBlock = @"
        <!-- ===================== 
        /// Begin isotope item ///
        ========================== 
        * If you use background image on isotope-item child element, then you need to use class "iso-height-1" or "iso-height-2" to set the item height. If you use simple image tag, then don't use height classes.
        -->
        <div class="isotope-item">

            <!-- Begin gallery single item -->
            <a href="$($ImageRootUri)/$($Album.Parent.Name)/$($Album.Name)/$($Image)"
                class="gallery-single-item lg-trigger"
                data-exthumbnail="$($ImageRootUri)/$($Album.Parent.Name)/$($Album.Name)/$($ThumbnailFile)">

                <img src="$($ImageRootUri)/$($Album.Parent.Name)/$($Album.Name)/$($Image)"
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
    $HTML = $HTML -replace ('##TITLE##', "$($Config.Title) - Cory Manson Photography")
    $HTML = $HTML -replace ('##GALLERYITEMS##', $GalleryItems)
    $HTML | Out-File -FilePath "$($Album.FullName)/index.html" -Force

    $HomeItemBlock = @"
                        <div class="isotope-item iso-height-1">

                        <!-- Begin gallery list item -->
                        <div class="gallery-list-item">

                            <!-- Begin gallery list item image -->
                            <div class="gl-item-image-wrap">

                                <!-- Begin gallery list item image inner -->
                                <a href="/albums/$($Album.Parent.Name)/$($Album.Name)" class="gl-item-image-inner">
                                    <div class="gl-item-image bg-image"
                                        style="background-image: url($($ImageRootUri)/$($Album.Parent.Name)/$($Album.Name)/cover.jpg); background-position: 50% 50%">
                                    </div>

                                    <span class="gl-item-image-zoom"></span>
                                </a>
                                <!-- End gallery list item image inner -->

                            </div>
                            <!-- End gallery list item image -->

                            <!-- Begin gallery list item info -->
                            <div class="gl-item-info">
                                <div class="gl-item-caption">
                                    <h2 class="gl-item-title"><a href="/albums/$($Album.Parent.Name)/$($Album.Name)">$($Config.Title)</a></h2>
                                    <span class="gl-item-category">$($Album.Parent.Name) - $($Config.Category)</span>
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

$HTML = $HomeTemplate
$HTML = $HTML -replace ('##GALLERIES##', $HomeItems)
$HTML | Out-File -FilePath "www/index.html" -Force

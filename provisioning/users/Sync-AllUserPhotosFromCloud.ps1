function Sync-AllUserPhotosFromCloud {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PeopleOU = "OU=People,DC=untapped,DC=tech",

        [Parameter()]
        [string]$WorkingFolder = "$env:TEMP\UserPhotoSync",

        [Parameter()]
        [switch]$SetJpegPhoto
    )

    # Ensure working folder exists
    if (-not (Test-Path $WorkingFolder)) {
        New-Item -ItemType Directory -Path $WorkingFolder | Out-Null
    }

    # Connect to Graph once
    # Load only required Graph modules (meta-module causes hangs)
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Users
    Connect-MgGraph -Scopes "User.ReadWrite.All"

    # Get all AD users in the People OU
    $users = Get-ADUser -SearchBase $PeopleOU -Filter * -Properties SamAccountName, UserPrincipalName

    foreach ($u in $users) {

        $sam = $u.SamAccountName
        $upn = $u.UserPrincipalName

        Write-Host "Processing $sam ($upn)..."

        # Paths for temp files
        $cloudPath = Join-Path $WorkingFolder "$sam-cloud.jpg"
        $thumbPath = Join-Path $WorkingFolder "$sam-thumb.jpg"

        try {
            #
            # 1. Pull cloud photo
            #
            Get-MgUserPhotoContent -UserId $upn -OutFile $cloudPath

            #
            # 2. Resize to AD-safe 96x96
            #
            Add-Type -AssemblyName System.Drawing

            $img = [System.Drawing.Image]::FromFile($cloudPath)
            $thumb = New-Object System.Drawing.Bitmap 96, 96
            $g = [System.Drawing.Graphics]::FromImage($thumb)

            $g.DrawImage($img, 0, 0, 96, 96)
            $thumb.Save($thumbPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

            $g.Dispose()
            $thumb.Dispose()
            $img.Dispose()

            #
            # 3. Write to AD
            #
            $bytes = [System.IO.File]::ReadAllBytes($thumbPath)

            $replace = @{ thumbnailPhoto = $bytes }
            if ($SetJpegPhoto) {
                $replace['jpegPhoto'] = $bytes
            }

            Set-ADUser -Identity $sam -Replace $replace

            Write-Host "✔ Synced photo for $sam"
        }
        catch {
            Write-Warning "✖ Failed to sync photo for $sam — $($_.Exception.Message)"
        }
    }

    Write-Host "Bulk photo sync complete."
}

#!/usr/bin/env pwsh
#requires -version 5
param(
    # Set to the full tag name e.g. "2.0.6-2.1.101"
    [string]$longtag
)

$runtime,$sdk = $longtag.split('-')
$major,$minor,$path = $runtime.split('.')

# $tags = @("2.0.6-2.1.101", "2.0", "2")
$tags = @($longtag, $runtime, "$major.$minor", $major)

foreach ($tag in $tags) {
	Write-host "Tagging $tag"
    git tag "$tag" --force
}
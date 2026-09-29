# SmartDrive Fleet & Vehicle System Test Runner
# Tests all 5 realistic vehicle categories across 2-Wheeler, 3-Wheeler, and 4-Wheeler

$baseUrl = "http://localhost:3000"
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  SMARTDRIVE FLEET & VEHICLE SYSTEM TEST RUNNER (POWERSHELL)    " -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

# 1. Test Candidates with realistic vehicle types
$candidates = @(
    @{
        name = "Aarav Sharma"
        email = "aarav.scooter.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())@testdrive.in"
        phoneNumber = "+91 98451 23001"
        vehicleType = "scooter"
        licenseNumber = "KA21 20210001024"
        zone = "Karnataka, Dakshina Kannada, Puttur"
        familyRelationship = "Mother"
        emergencyContactName = "Sunita Sharma"
        emergencyContactPhone = "+91 98451 99001"
    },
    @{
        name = "Vikramaditya Rao"
        email = "vikram.bike.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())@testdrive.in"
        phoneNumber = "+91 98452 34002"
        vehicleType = "bike"
        licenseNumber = "KA19 20200004412"
        zone = "Karnataka, Dakshina Kannada, Mangaluru"
        familyRelationship = "Father"
        emergencyContactName = "Gopal Rao"
        emergencyContactPhone = "+91 98452 99002"
    },
    @{
        name = "Manjunath Gowda"
        email = "manju.auto.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())@testdrive.in"
        phoneNumber = "+91 98453 45003"
        vehicleType = "3_wheeler"
        licenseNumber = "KA20 20190008890"
        zone = "Karnataka, Udupi, Manipal"
        familyRelationship = "Brother"
        emergencyContactName = "Ramesh Gowda"
        emergencyContactPhone = "+91 98453 99003"
    },
    @{
        name = "Suresh Babu Kumar"
        email = "suresh.cab.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())@testdrive.in"
        phoneNumber = "+91 98454 56004"
        vehicleType = "cab"
        licenseNumber = "KA01 20180003321"
        zone = "Karnataka, Bengaluru Urban, Indiranagar"
        familyRelationship = "Spouse"
        emergencyContactName = "Lakshmi Kumar"
        emergencyContactPhone = "+91 98454 99004"
    },
    @{
        name = "Praveen Shetty"
        email = "praveen.van.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())@testdrive.in"
        phoneNumber = "+91 98455 67005"
        vehicleType = "delivery_van"
        licenseNumber = "KA21 20220005509"
        zone = "Karnataka, Dakshina Kannada, Puttur"
        familyRelationship = "Uncle"
        emergencyContactName = "Mohan Shetty"
        emergencyContactPhone = "+91 98455 99005"
    }
)

Write-Host "`n▶ [1/3] Submitting 5 Test Applications to Backend ($baseUrl)..." -ForegroundColor Green
foreach ($cand in $candidates) {
    try {
        $body = $cand | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "$baseUrl/api/auth/driver-apply" -Method Post -ContentType "application/json" -Body $body
        Write-Host "  ✔ $($cand.name) registered as [$($cand.vehicleType.ToUpper())] -> App ID: $($res.data.applicationId)" -ForegroundColor Green
    } catch {
        Write-Host "  ✖ Failed to submit $($cand.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n▶ [2/3] Authenticating Regional Admin..." -ForegroundColor Green
try {
    $loginBody = @{
        email = "admin@acmelogistics.com"
        password = "SmartDrive2026!"
    } | ConvertTo-Json
    $loginRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
    $token = $loginRes.data.accessToken
    Write-Host "  ✔ Admin authenticated. Access Token secured." -ForegroundColor Green

    Write-Host "`n▶ [3/3] Inspecting Driver Verification Queue..." -ForegroundColor Green
    $headers = @{ Authorization = "Bearer $token" }
    $driversRes = Invoke-RestMethod -Uri "$baseUrl/api/drivers" -Method Get -Headers $headers
    $pending = $driversRes.data | Where-Object { $_.status -eq "PENDING_APPROVAL" }
    Write-Host "  ✔ Total pending applications awaiting review: $($pending.Count)" -ForegroundColor Cyan
    
    foreach ($p in ($pending | Select-Object -First 5)) {
        Write-Host "    • $($p.user.firstName) $($p.user.lastName) | Type: $($p.driverType) | Zone: $($p.user.zone)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  ✖ Admin check error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  READY FOR LIVE INSPECTION ON DASHBOARD AND MOBILE APP         " -ForegroundColor Yellow
Write-Host "  - Dashboard Requests URL : http://localhost:5173/requests      " -ForegroundColor White
Write-Host "  - Profile Sector Control : http://localhost:5173/profile       " -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan

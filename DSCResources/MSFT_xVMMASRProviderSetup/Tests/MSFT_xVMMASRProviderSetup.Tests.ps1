<###################################################
 #                                                 #
 #  Copyright (c) Microsoft. All rights reserved.  #
 #                                                 #
 ##################################################>

 <#
.SYNOPSIS
    Pester Tests for MSFT_xVMMASRProviderSetup.psm1

.DESCRIPTION
    See Pester Wiki at https://github.com/pester/Pester/wiki
    Download Module from https://github.com/pester/Pester to run tests
#>

$ModulePath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
import-module (Join-Path -Path $ModulePath -ChildPath "MSFT_xVMMASRProviderSetup.psm1") -force

$ModulePath = Split-Path -Parent (Split-Path -Parent $ModulePath)
import-module (Join-Path -Path $ModulePath -ChildPath "xPDT.psm1") -force


InModuleScope MSFT_xVMMASRProviderSetup {

	$UserName = "UserName"
	$Password = "Password"
	$ProxyServerAddress = "http://Proxy.com"
	$ProxyServerPort = "80"
	$IdentifyingNumber = "{6CCC483C-AD9E-468D-83F6-AD7FBA2B310B}"
	$Version1 = "3.5.700.0"
	$Version2 = "3.5.700.1"

	$Pass=ConvertTo-SecureString -AsPlainText $Password -Force
	$SetupCred=New-Object System.Management.Automation.PSCredential -ArgumentList $UserName,$Pass

	Describe "MSFT_xVMMASRProviderSetup Tests"{

		Mock -ModuleName "MSFT_xVMMASRProviderSetup" ResolvePath{

			write-Host "Mocking ResolvePath"
			return $Path
		}

		Mock -ModuleName "MSFT_xVMMASRProviderSetup" Import-Module{

			write-Host "Mocking Import-Module"
		}

		Mock -ModuleName "MSFT_xVMMASRProviderSetup" Get-Item{

			write-Host "Mocking Get-Item"
			$VersionInfo=@{"FileVersion"="$Version1"}
			$obj=@{"VersionInfo"=$VersionInfo}
			return $obj
		}
   
		It "Test if the Test-TargetResource returns false in case MARS agent is not installed and Ensure=Present"{

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $False
			}

			(Test-TargetResource -Ensure "Present" -SourcePath "$env:TEMP") |  Should Be 'False'
		}

		It "Test if the Test-TargetResource returns true in case MARS agent is not installed and Ensure=Absent"{
    
			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $False
			}

			(Test-TargetResource -Ensure "Absent" -SourcePath "$env:TEMP") |  Should Be 'True'
		}

		It "Test if the Test-TargetResource returns false in case MARS agent is installed but of some other version and Ensure=Present"{
    
			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Get-ItemProperty{

				write-Host "Mocking Get-ItemProperty"
				$obj=@{"Version"="$Version2"}
				return $obj
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $Ture
			}

			(Test-TargetResource -Ensure "Present" -SourcePath "$env:TEMP") |  Should Be 'False'
		}

		It "Test if the Test-TargetResource returns true in case MARS agent of expected version is installed and Ensure=Present"{

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Get-ItemProperty{

				write-Host "Mocking Get-ItemProperty"
				$obj=@{"Version"="$Version1"}
				return $obj
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $True
			}

			(Test-TargetResource -Ensure "Present" -SourcePath "$env:TEMP") |  Should Be 'True'
		}

		It "Test if the Set-TargetResource arguments are correct if Ensure=Present"{

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" -ParameterFilter {$Arguments -match "/i"} StartWin32Process{

				if($Path -match "SETUPDR.EXE")
				{
					write-Host "Path : $Path is Correct"
					if($Arguments -match "/i")
					{
						write-Host "Arguments : $Arguments are correct"
					}
					else
					{
						throw ("Arguments : $Arguments are incorrect")
					}
				}
				else
				{
					throw ("Path : $Path is incorrect")
				}
				return "$Path $Arguments"
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" -ParameterFilter {$Arguments -match "/x"} StartWin32Process{

				Write-host "Mocking StartWin32Process"
				return "$Path $Arguments"
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Test-Path{

				write-Host "Mocking Test-Path"	
				return $False
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Get-Service{

				write-Host "Mocking Get-Service"
				$obj=@{"Status"="PlaceHolder"}
				return $obj
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Restart-Service{

				write-Host "Mocking Restart-Service"
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Test-TargetResource{

				write-Host "Mocking Test-TargetResource"
				return $True
			}

			(Set-TargetResource -Ensure "Present" -SourcePath "$env:TEMP" -SetupCredential $SetupCred)
		}

		It "Test if the Set-TargetResource arguments are correct if Ensure=Absent"{

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" -ParameterFilter {$Path -match "MsiExec.exe"} StartWin32Process{

				if($Path -match "MsiExec.exe")
				{
					write-Host "Path : $Path is Correct"
					if($Arguments -match "/X$IdentifyingNumber /q")
					{
						write-Host "Arguments : $Arguments are correct"
					}
					else
					{
						throw ("Arguments : $Arguments are incorrect")
					}
				}
				else
				{
					throw ("Path : $Path is incorrect")
				}

				return "$Path $Arguments"
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" -ParameterFilter {$Path -match "VMMASRProvider_x64.exe"} StartWin32Process{

				Write-host "Mocking StartWin32Process"
				return "$Path $Arguments"
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Test-TargetResource{

				write-Host "Mocking Test-TargetResource"
				return $True
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Get-ChildItem{

				write-Host "Mocking Get-ChildItem"
				$obj=New-Object psobject -Property @{"Path"="PlaceHolder"}
				return $obj
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Get-ItemProperty{

				write-Host "Mocking Get-ItemProperty"
				$obj=New-Object psobject -Property @{"DisplayName"="PlaceHolder"}
				return $obj
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Select-Object{

				write-Host "Mocking Select-Object"
				$Cmds = @{"UninstallString"="MsiExec.exe /X$IdentifyingNumber"}
				return $Cmds
			}

			Mock -ModuleName "MSFT_xVMMASRProviderSetup" Where-Object{

				write-Host "Mocking Where-Object"
				$obj=New-Object psobject -Property @{"UninstallString"="PlaceHolder"}
				return $obj
			}

			(Set-TargetResource -Ensure "Absent" -SourcePath "$env:TEMP" -SetupCredential $SetupCred)
		}
	}
}
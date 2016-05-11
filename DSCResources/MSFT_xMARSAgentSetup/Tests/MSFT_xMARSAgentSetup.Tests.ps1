<###################################################
 #                                                 #
 #  Copyright (c) Microsoft. All rights reserved.  #
 #                                                 #
 ##################################################>

 <#
.SYNOPSIS
    Pester Tests for MSFT_xMARSAgentSetup.psm1

.DESCRIPTION
    See Pester Wiki at https://github.com/pester/Pester/wiki
    Download Module from https://github.com/pester/Pester to run tests
#>
 
$ModulePath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
import-module (Join-Path -Path $ModulePath -ChildPath "MSFT_xMARSAgentSetup.psm1") -force

$ModulePath = Split-Path -Parent (Split-Path -Parent $ModulePath)
import-module (Join-Path -Path $ModulePath -ChildPath "xPDT.psm1") -force


InModuleScope MSFT_xMARSAgentSetup {

	$UserName="UserName"
	$Password="Password"
	$IdentifyingNumber = "{FFE6D16C-3F87-4192-AF94-DDBEFF165106}"
	$Version1 = "2.0.8704.0"
	$Version2 = "2.0.8704.1"

	$Pass=ConvertTo-SecureString -AsPlainText $Password -Force
	$SetupCred=New-Object System.Management.Automation.PSCredential -ArgumentList $UserName,$Pass

	Describe "MSFT_xMARSAgentSetup Tests"{ 

		Mock -ModuleName "MSFT_xMARSAgentSetup" ResolvePath{

			write-Host "Mocking ResolvePath"
			return $Path
		}

		Mock -ModuleName "MSFT_xMARSAgentSetup" Import-Module{

			write-Host "Mocking Import-Module"
		}

		Mock -ModuleName "MSFT_xMARSAgentSetup" Get-Item{

				write-Host "Mocking Get-Item"
				$VersionInfo=@{"FileVersion"="$Version1"}
				$obj=@{"VersionInfo"=$VersionInfo}
				return $obj
		}

		It "Test if the Test-TargetResource returns false in case MARS agent is not installed and Ensure=Present"{

			Mock -ModuleName "MSFT_xMARSAgentSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $False
			}

			(Test-TargetResource -Ensure "Present" -SourcePath "$env:TEMP" -SetupCredential $SetupCred) |  Should Be 'False'
		}

		It "Test if the Test-TargetResource returns true in case MARS agent is not installed and Ensure=Absent"{

			Mock -ModuleName "MSFT_xMARSAgentSetup" Test-Path{		

				write-Host "Mocking Test-Path"	
				return $False
			}

			(Test-TargetResource -Ensure "Absent" -SourcePath "$env:TEMP" -SetupCredential $SetupCred) |  Should Be 'True'
		}

		It "Test if the Test-TargetResource returns false in case MARS agent is installed but of some other version and Ensure=Present"{
    
			Mock -ModuleName "MSFT_xMARSAgentSetup" Get-WmiObject{

				write-Host "Mocking Get-WmiObject"
				$obj=@{"Version"="$Version2"}
				return $obj
			}

			Mock -ModuleName "MSFT_xMARSAgentSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $Ture
			}

			(Test-TargetResource -Ensure "Present" -SourcePath "$env:TEMP" -SetupCredential $SetupCred) |  Should Be 'False'
		}

		It "Test if the Test-TargetResource returns true in case MARS agent of expected version is installed and Ensure=Present"{

			Mock -ModuleName "MSFT_xMARSAgentSetup" Get-WmiObject{

				write-Host "Mocking Get-WmiObject"
				$obj=@{"Version"="$Version1"}
				return $obj
			}

			Mock -ModuleName "MSFT_xMARSAgentSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $True
			}

			(Test-TargetResource -Ensure "Present" -SourcePath "$env:TEMP" -SetupCredential $SetupCred) |  Should Be 'True'
		}

		It "Test if the Set-TargetResource arguments are correct if Ensure=Present"{

			Mock -ModuleName "MSFT_xMARSAgentSetup" StartWin32Process{

				if($Path -match "MARSAgentInstaller.exe")
				{
					write-Host "Path : $Path is Correct"
					if($Arguments -match "/q")
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

			Mock -ModuleName "MSFT_xMARSAgentSetup" Test-Path{

				write-Host "Mocking Test-Path"
				return $False
			}

			Mock -ModuleName "MSFT_xMARSAgentSetup" Test-TargetResource{

				write-Host "Mocking Test-TargetResource"
				return $True
			}

			(Set-TargetResource -Ensure "Present" -SourcePath "$env:TEMP" -SetupCredential $SetupCred)
		}

		It "Test if the Set-TargetResource arguments are correct if Ensure=Absent"{

			Mock -ModuleName "MSFT_xMARSAgentSetup" StartWin32Process{

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

			Mock -ModuleName "MSFT_xMARSAgentSetup" Test-TargetResource{

				write-Host "Mocking Test-TargetResource"
				return $True
			}

			Mock -ModuleName "MSFT_xMARSAgentSetup" Get-ChildItem{

				write-Host "Mocking Get-ChildItem"
				$obj=New-Object psobject -Property @{"Path"="PlaceHolder"}
				return $obj
			}

			Mock -ModuleName "MSFT_xMARSAgentSetup" Get-ItemProperty{

				write-Host "Mocking Get-ItemProperty"
				$obj=New-Object psobject -Property @{"DisplayName"="PlaceHolder"}
				return $obj
			}

			Mock -ModuleName "MSFT_xMARSAgentSetup" Select-Object{

				write-Host "Mocking Select-Object"
				$cmds = @{"UninstallString"="MsiExec.exe /X$IdentifyingNumber"}
				return $cmds
			}

			Mock -ModuleName "MSFT_xMARSAgentSetup" Where-Object{

				write-Host "Mocking Where-Object"
				$obj=New-Object psobject -Property @{"UninstallString"="PlaceHolder"}
				return $obj
			}

			(Set-TargetResource -Ensure "Absent" -SourcePath "$env:TEMP" -SetupCredential $SetupCred)
		}
	}
}
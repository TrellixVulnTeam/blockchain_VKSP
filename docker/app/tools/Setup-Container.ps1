#===============================================================================
# Setup-Container.ps1
#===============================================================================
param(
	[String]$ArchiveFile='system.zip',    # �V�X�e���A�[�J�C�u
	[String]$Product,                     # �v���_�N�g��
	[Switch]$Help                         # �g�p���@�\��
)

#--------------------------------------
# �ϐ��ݒ�
#--------------------------------------
Set-Variable CUR_DIR               "$(Split-Path $myInvocation.MyCommand.Path -parent)"           -option constant
Set-Variable LOG_FILE              "$($script:CUR_DIR)\setup.log"                                 -option constant
Set-Variable OUT_DIR               "C:/opt/$($script:Product)"                                    -option constant
Set-Variable SYS_DIR               "$($script:OUT_DIR)"                                           -option constant
Set-Variable WIN_DIR               "$($script:CUR_DIR)\win"                                       -option constant

Set-Variable RUNTIME_X86_PATH      "$($script:WIN_DIR)\vc_redist.x86.exe"                         -option constant
Set-Variable RUNTIME_X64_PATH      "$($script:WIN_DIR)\vc_redist.x64.exe"                         -option constant

Set-Variable IIS_REWRITE_PATH      "$($script:WIN_DIR)\rewrite.msi"                               -option constant
Set-Variable IIS_ROUTER_PATH       "$($script:WIN_DIR)\requestRouter_amd64.msi"                   -option constant
Set-Variable IIS_SETUP_PATH        "$($script:SYS_DIR)\system\shell\iis-setup.ps1"                -option constant

Set-Variable SQLSVR_SETUP_PATH     "$($script:WIN_DIR)\database_en\SETUP.EXE"                     -option constant
Set-Variable SQLSVR_INSTANCE       "PWSP"                                                         -option constant
Set-Variable SQLSVR_PASS           "Rencho2000"                                                   -option constant
Set-Variable SQLSVR_USR_TOOL_PATH  "$($script:CUR_DIR)\db_create_user.bat"                        -option constant
Set-Variable SQLSVR_MOUNT_DIR      "C:\sqlserver\data"                                            -option constant
Set-Variable SQLSVR_SQLCMD_PATH    "$($script:WIN_DIR)\msodbcsql.msi"                             -option constant

Set-Variable VIM_TOOL_PATH         "$($script:WIN_DIR)\gvim82.exe"                                -option constant
Set-Variable PS_PROFILE_DIR        "C:\Users\ContainerAdministrator\Documents\WindowsPowerShell"  -option constant
Set-Variable PS_PROFILE_PATH       "$($script:WIN_DIR)\Microsoft.PowerShell_profile.ps1"          -option constant

#--------------------------------------
# �g�p���@
#--------------------------------------
function Print-Usage(
	[String]$Message
)
{
Write-Host "==========================================================="
Write-Host " $($myInvocation.ScriptName)"
Write-Host "---------------------------usage---------------------------"
Write-Host " usage: $($myInvocation.ScriptName)"
Write-Host " option:"
Write-Host "     -ArchiveFile   : archive module path"
Write-Host "     -Product       : product name"
Write-Host "     -Help:         : show usage"
Write-Host "==========================================================="
if ($Message) { Write-Host "$($Message)" }
}

#--------------------------------------
# ���O�o��
#--------------------------------------
function Print-Log(
	[String]$Message)
{
    Write-Host $Message
    $Message = (Get-Date -format s) + ": " + $Message
    Write-Output $Message| Out-File $script:LOG_FILE -encoding default -Append
}

#--------------------------------------
# �c�[���폜
#--------------------------------------
function Clear-SetupTool()
{
    if (![string]::IsNullOrEmpty($script:ArchiveFile)) {
        if ($(Test-Path "$($script:CUR_DIR)\$($script:ArchiveFile)")){ Remove-Item "$($script:CUR_DIR)\$($script:ArchiveFile)" -Force }
    }
    if ($(Test-Path "$($script:WIN_DIR)"))                       { Remove-Item "$($script:WIN_DIR)"                        -Force -Recurse }
	if ($(Test-Path "$($myInvocation.ScriptName)"))              { Remove-Item "$($myInvocation.ScriptName)"               -Force }
}

#--------------------------------------
# �W�J��쐬
#--------------------------------------
function Create-Path()
{
	Print-Log "***** [Create-Path] start!! *****"
	
	# �C���e�O���[�V�����f�B���N�g���쐬
	New-Item -ItemType Directory "$($script:OUT_DIR)" | Out-Null
	if ($(Test-Path "$($script:OUT_DIR)") -eq $FALSE) {
		Print-Log "<!> mkdir($($script:OUT_DIR)) failed..."
		return 1
	}
	Print-Log "<I> mkdir($($script:OUT_DIR))"

	Print-Log "***** [Create-Path] done!! *****"

    return 0
}

#--------------------------------------
# zip�W�J
#--------------------------------------
function Extract-Archive([String]$File)
{
	Print-Log "***** [Extract-Archive] start!! *****"

	if ($(Test-Path $File) -eq $FALSE) {
		Print-Log "<!> $($File) not found."
		return 1
	}

	# �W�J
    Expand-Archive -Path "$($File)" -DestinationPath "$($script:OUT_DIR)" | Out-Null
	if ($? -eq $false) {
		Print-Log "<!> unzip.exe failed..."
		return 1
	}
	Print-Log "<I> extract archive $($File) to $($OUT_DIR)"

	Print-Log "***** [Extract-Archive] done!! *****"

    return 0
}

#--------------------------------------
# runtime�Z�b�g�A�b�v
#--------------------------------------
function Setup-Runtime()
{
	Print-Log "***** [Setup-Runtime] start!! *****"

    # Runtime(x86)�ǉ�
    & $script:RUNTIME_X86_PATH /quiet /norestart
    if ($? -eq $false) {
		Print-Log "<!> add runtime x86 failed..."
		return 1
	}
    Print-Log "<I> add runtime x86"

    # Runtime(x64)�ǉ�
    & $script:RUNTIME_X64_PATH /quiet /norestart
    if ($? -eq $false) {
		Print-Log "<!> add runtime x64 failed..."
		return 1
	}
    Print-Log "<I> add runtime x64"

	Print-Log "***** [Setup-Runtime] done!! *****"

    return 0
}

#--------------------------------------
# web�Z�b�g�A�b�v
#--------------------------------------
function Setup-Web()
{
	Print-Log "***** [Setup-Web] start!! *****"

    # IIS Major Version�ύX
    Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\InetStp -Name MajorVersion -Value 9 | Out-Null
    Print-Log "<I> change IIS MajorVersion 9"#>

    # IIS Rewrite�ǉ�
    msiexec.exe /qn /i $script:IIS_REWRITE_PATH | Out-Null
    if ($? -eq $false) {
		Print-Log "<!> add iis rewrite failed..."
		return 1
	}

    # IIS Request Router�ǉ�
    msiexec.exe /qn /i $script:IIS_ROUTER_PATH | Out-Null
    if ($? -eq $false) {
		Print-Log "<!> add iis request router failed..."
		return 1
	}

    $waitcount = 10
    $waitcounter = 0
    While ($true) {
        $rewrite = Get-WmiObject Win32_Product | Select-Object Name,Vendor,Version,Caption | ForEach-Object { $_.Name -like "*rewrite*" }
        if ($rewrite -ne $null) {
            break
        } else {
            Start-Sleep 5
            $waitcounter++
            if ($waitcounter -ge $waitcount) {
                Print-Log "<!> add iis rewrite failed..."
		        return 1
            }
        }
    }
    Print-Log "<I> add iis rewrite"

    # IIS�ǉ�
    & $script:IIS_SETUP_PATH -Site $script:Product -StopSiteConflictPort 80
    if ($? -eq $false) {
		Print-Log "<!> add iis failed..."
		return 1
	}

    # �n������
    Remove-Website -Name "Default Web Site"

	Print-Log "***** [Setup-Web] done!! *****"

    return 0
}

#--------------------------------------
# database�Z�b�g�A�b�v
#--------------------------------------
function Setup-Database()
{
	Print-Log "***** [Setup-Database] start!! *****"

    msiexec.exe /quiet /passive /qn /i $script:SQLSVR_SQLCMD_PATH IACCEPTMSODBCSQLLICENSETERMS=YES | Out-Null
    if ($? -eq $false) {
		Print-Log "<!> add sqlcmd failed..."
		return 1
	}

	Print-Log "***** [Setup-Database] done!! *****"

    return 0
}

#--------------------------------------
# utility�Z�b�g�A�b�v
#--------------------------------------
function Setup-Utility()
{
	Print-Log "***** [Setup-Utility] start!! *****"

    if ($(Test-Path $script:VIM_TOOL_PATH) -eq $FALSE) {
		Print-Log "<!> $($script:VIM_TOOL_PATH) not found."
		return 1
	}

    # VIM�ǉ�
    & $script:VIM_TOOL_PATH /S
    if ($? -eq $false) {
		Print-Log "<!> add vim failed..."
		return 1
	}
    $waitcount = 10
    $waitcounter = 0
    While ($true) {
        $process = Get-Process | Where-Object { $_.ProcessName -like "*vim*" }
        if ($process -eq $null) {
            break
        } else {
            Start-Sleep 5
            $waitcounter++
            if ($waitcounter -ge $waitcount) {
                Print-Log "<!> add vim timeout failed..."
		        return 1
            }
        }
    }
	Print-Log "<I> add vim"

    if ($(Test-Path $script:PS_PROFILE_PATH) -eq $FALSE) {
		Print-Log "<!> $($script:PS_PROFILE_PATH) not found."
		return 1
	}
    if ($(Test-Path $script:PS_PROFILE_DIR) -eq $FALSE) {
        New-Item $script:PS_PROFILE_DIR -ItemType Directory | Out-Null
    }

    # Powershell�v���t�@�C���ǉ�
    Copy-Item -Path $script:PS_PROFILE_PATH -Destination "$($script:PS_PROFILE_DIR)\Microsoft.PowerShell_profile.ps1" | Out-Null
    if ($? -eq $false) {
		Print-Log "<!> add powershell profile failed..."
		return 1
	}
	Print-Log "<I> add powershell profile"

    # PATH�ǉ�
    $SystemPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $SystemPath += ";C:\setup\sqlcmd"
    [System.Environment]::SetEnvironmentVariable("PATH", $SystemPath, "Machine")
    Print-Log "<I> add system path"

	Print-Log "***** [Setup-Utility] done!! *****"

    return 0
}

#--------------------------------------
# �x�[�X�Z�b�g�A�b�v
#--------------------------------------
function Setup-Base()
{
    # runtime
    $ret = Setup-Runtime
	if ($ret -ne 0) {
		Print-Log "<!> Setup-Runtime failed..."
		return 1
	}

    # web
    $ret = Setup-Web
	if ($ret -ne 0) {
		Print-Log "<!> Setup-Web failed..."
		return 1
	}

    # database
    $ret = Setup-Database
	if ($ret -ne 0) {
		Print-Log "<!> Setup-Database failed..."
		return 1
	}

    # utility
    $ret = Setup-Utility
	if ($ret -ne 0) {
		Print-Log "<!> Setup-Utility failed..."
		return 1
	}

    return 0
}

#--------------------------------------
# �v���_�N�g�Z�b�g�A�b�v
#--------------------------------------
function Setup-Prod()
{
	# �v���_�N�g�ŗL�̏���

    return 0
}

#--------------------------------------
# �C�j�V�����C�Y
#--------------------------------------
function Initialize()
{
    # �W�J��쐬
	$ret = Create-Path
	if ($ret -ne 0) {
		Print-Log "<!> Create-Path failed..."
		return $ret
	}

	# �V�X�e���A�[�J�C�u�W�J
	if ([string]::IsNullOrEmpty($script:ArchiveFile)) {
		Print-Log "<I> non system install..."
	} else {
		if ($(Test-Path "$($script:CUR_DIR)\$($script:ArchiveFile)")) {
			$ret = Extract-Archive "$($script:CUR_DIR)\$($script:ArchiveFile)"
			if ($ret -ne 0) {
				Print-Log "<!> Extract-Archive(system) failed..."
				return $ret
			}
		} else {
			Print-Log "<I> skip system install..."
		}
	}

    return 0
}

#--------------------------------------
# ���C��
#--------------------------------------
function Main()
{
	Print-Log "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"
	Print-Log " setup container..."
	Print-Log "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"

	$ret = Setup-Base
	if ($ret -ne 0) {
		Print-Log "xxxxxxxxxxxxxxxxxxxxxxxx"
		Print-Log "<!> Setup-Base failed..."
		Print-Log "xxxxxxxxxxxxxxxxxxxxxxxx"
		return $ret
	}

	if ($script:Product -ne "") {
		Print-Log "$($script:Product) configure..."
		$ret = Setup-Prod
		if ($ret -ne 0) {
			Print-Log "xxxxxxxxxxxxxxxxxxxxxxxx"
			Print-Log "<!> Setup-Prod failed..."
			Print-Log "xxxxxxxxxxxxxxxxxxxxxxxx"
			return $ret
		}
	}

	Print-Log "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"
	Print-Log " finished!!"
	Print-Log "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"

    return 0
}

#--------------------------------------
# �t�@�C�i���C�Y
#--------------------------------------
function Finalize()
{
    # �S�~�|��
	$ret = Clear-SetupTool

    return 0
}

#--------------------------------------
# �G���g���[�|�C���g
#--------------------------------------
$ret = Initialize
if ($ret -eq 0) {
    $ret = Main
    Finalize
}
exit $ret

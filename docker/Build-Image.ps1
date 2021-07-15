#===============================================================================
# Build-Image.ps1
#===============================================================================
param(
	[String]$Dockerfile="$(Split-Path $myInvocation.MyCommand.Path -parent)\Dockerfile", # Dockerfile
	[String]$Tag="latest",              # Docker�C���[�W�̃^�O
	[String]$ImageName="rtc",           # Docker�C���[�W��
	[String]$AutoTestName,              # opt : �����e�X�g�R���e�i��
	[String]$DBServer,                  # opt : (��)�f�[�^�x�[�X�T�[�o�[
	[String]$DBInstance,                # opt : (��)�f�[�^�x�[�X�C���X�^���X
	[String]$DBDatabase,                # opt : (��)�f�[�^�x�[�X��
	[Switch]$Help                       # �g�p���@�\��
)

#--------------------------------------
# �ϐ��ݒ�
#--------------------------------------
Set-Variable SETUP_CMD   "RUN powershell.exe -noprofile -executionpolicy RemoteSigned -command " -option constant

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
Write-Host "     -Dockerfile    : Dockerfile path. if you want to specify another dockerfile, use this option."
Write-Host "     -Tag           : add image tag e.g.) latest"
Write-Host "     -ImageName     : add image name e.g.) rtc"
Write-Host "     -AutoTestName  : autotest container name"
Write-Host "     -DBServer      : database server e.g.) 172.27.xx.xx"
Write-Host "     -DBInstance    : database instanse e.g.) rtc"
Write-Host "     -DBDatabase    : database name e.g.) rtc"
Write-Host "     -Help          : show usage"
Write-Host "==========================================================="
if ($Message) { Write-Host "$($Message)" }
}

#--------------------------------------
# ���O�o��
#--------------------------------------
function Print-Log(
	[String]$Message)
{
	$Message = (Get-Date -format s) + ": " + $Message
	Write-Host $Message
}

#--------------------------------------
# �{�`����Dockerfile�쐬
#--------------------------------------
function Create-Dockerfile([String]$image, [String]$name)
{
	$dockerFile = "$($script:Dockerfile)-$($image)-$($name)"
    Copy-Item $script:Dockerfile $dockerFile

	return $dockerFile
}

#--------------------------------------
# �C�j�V�����C�Y
#--------------------------------------
function Initialize()
{
    Push-Location (Get-item $script:Dockerfile).DirectoryName
    
    return 0
}

#--------------------------------------
# ���C��
#--------------------------------------
function Main()
{
	Print-Log "------------------------------------------------------"
	Print-Log " build container image prod:$($script:ImageName) tag:$($script:Tag)"
	Print-Log "------------------------------------------------------"

	Print-Log "Step 0/X : Prepare for docker build"

	if ($script:AutoTestName -eq "") {
		$dockerFile = $(Create-Dockerfile -image $script:ImageName -name "sim")
		Print-Log "created $($dockerFile)"
		docker build -t "$($script:ImageName):$($script:Tag)" -f $dockerFile .
	} else {
		$dockerFile = $(Create-Dockerfile -image $script:ImageName -name $script:AutoTestName)
		Print-Log "created $($dockerFile)"
		docker build -t "$($script:ImageName)-$($script:AutoTestName):$($script:Tag)" -f $dockerFile .
	}

	if ($(Test-Path $dockerFile) -eq $True) {
		Print-Log "remove $($dockerFile)"
		Remove-Item "$($dockerFile)"
	}

	Print-Log "completed!!"
}

#--------------------------------------
# �t�@�C�i���C�Y
#--------------------------------------
function Finalize()
{
    Pop-Location
}

#--------------------------------------
# ��O����
#--------------------------------------
trap [SystemException] {
	$file = ($error[0]).InvocationInfo.ScriptName
	$line = ($error[0]).InvocationInfo.ScriptLineNumber
	$code = ($error[0]).InvocationInfo.OffsetInLine
	$msg  = ($error[0]).ToString()
	Print-Log "<!> Exception!! file=$file line=$line, code=$code, msg=$msg"
    Pop-Location
	exit 1
}

if(($ret = Initialize) -ne 0){ exit $ret }
Main
Finalize
exit 0

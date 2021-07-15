#===============================================================================
# Run-Container.ps1
#===============================================================================
param(
	[String]$ConfigFile="$(Split-Path $myInvocation.MyCommand.Path -parent)\config.xml",    # �R���t�B�O�t�@�C��
    [Switch]$SkipDBRestore,    # DB���X�g�A�X�L�b�v
	[Switch]$Help              # �g�p���@�\��
)

#--------------------------------------
# �ϐ��ݒ�
#--------------------------------------
Set-Variable CUR_DIR "$(Split-Path $myInvocation.MyCommand.Path -parent)" -option constant

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
Write-Host "     -ConfigFile : config file path"
Write-Host "     -Help:      : show usage"
Write-Host "==========================================================="
if ($Message) { Write-Host "$($Message)" }
}

#--------------------------------------
# DB�R���e�i�N��
#--------------------------------------
function Run-DBContainer()
{
    $xml = [XML](Get-Content $script:ConfigFile)
    $image_registry = $xml.config.db.image.registry
    $image_container = $xml.config.db.image.container
    $port_host = $xml.config.db.port.host
    $port_container = $xml.config.db.port.container
    $password = $xml.config.db.password
    $shared_dir_host = $xml.config.db.shared_dir.host
    $shared_dir_container = $xml.config.db.shared_dir.container
    $dump_name = $xml.config.db.dump.name
    $dump_path_host = $xml.config.db.dump.path.host
    $dump_path_container = $xml.config.db.dump.path.container

    # �R���e�i�N��
    docker run -d --name $image_container -p "$($port_host):$($port_container)" -e sa_password=$password -e ACCEPT_EULA=Y -v "$($shared_dir_host):$($shared_dir_container)" $image_registry | Out-Null
    if ($? -eq $False) {
		Write-Host "<!> docker run failed..." -ForegroundColor Red
		return 1
	}
	Write-Host "<I> docker run ($($image_registry))"
    
    if ($script:SkipDBRestore) {
        Write-Host "<I> skip db restore..."
    } else {
        # DB�_���v�R�s�[
        docker cp $dump_path_host "$($image_container):$($dump_path_container)" | Out-Null
        if ($? -eq $False) {
		    Write-Host "<!> docker cp failed..." -ForegroundColor Red
		    return 1
	    }
	    Write-Host "<I> docker cp ($($dump_path_host) => $($image_container):$($dump_path_container))"

        # DB�_���v����
        $dump_path_container = "C:" + $dump_path_container
        docker exec $image_container powershell -c "Restore-DB -DBName $($dump_name) -DBPath $($dump_path_container) -DBDataDir $($shared_dir_container)" | Out-Null
        if ($? -eq $False) {
		    Write-Host "<!> docker exec failed..." -ForegroundColor Red
		    return 1
	    }
	    Write-Host "<I> docker exec (Restore-DB)"
    }

    # IP�A�h���X�擾
    $script:ip = docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $image_container
    Write-Host "<I> docker inspect ($($script:ip))"

    return 0
}

#--------------------------------------
# �A�v���P�[�V�����R���e�i�N��
#--------------------------------------
function Run-AppContainer()
{
    $xml = [XML](Get-Content $script:ConfigFile)
    $image_registry = $xml.config.app.image.registry
    $image_container = $xml.config.app.image.container
    $port_host = $xml.config.app.port.host
    $port_container = $xml.config.app.port.container
    $db_type = $xml.config.app.db.type
    $db_instance = $xml.config.app.db.instance
    $db_name = $xml.config.app.db.name

    # �R���e�i�N��
    docker run -d --name $image_container -p "$($port_host):$($port_container)" $image_registry | Out-Null
    if ($? -eq $False) {
		Write-Host "<!> docker run failed..." -ForegroundColor Red
		return 1
	}
	Write-Host "<I> docker run ($($image_registry))"

    # �R���t�B�O�ݒ�
    $db_server = $script:ip
    if(![string]::IsNullOrEmpty($db_instance)){
        $db_server += ("\" + $db_instance)
    }
    docker exec $image_container powershell -c "Setup-DBConfig -DBType $($db_type) -DBServer $($db_server) -DBName $($db_name)" | Out-Null
    if ($? -eq $False) {
		Write-Host "<!> docker exec failed..." -ForegroundColor Red
		return 1
	}
	Write-Host "<I> docker exec (Setup-DBConfig)"

    return 0
}

#--------------------------------------
# �C�j�V�����C�Y
#--------------------------------------
function Initialize()
{
    if ($(Test-Path "$($script:ConfigFile)") -eq $FALSE) {
		Write-Host "<!> ($($script:ConfigFile)) not found..." -ForegroundColor Red
		return 1
	}

    return 0
}

#--------------------------------------
# ���C��
#--------------------------------------
function Main()
{
	Write-Host "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"
	Write-Host " run container..."
	Write-Host "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"

    Write-Host "<I> config $($script:ConfigFile)"

	$ret = Run-DBContainer
	if ($ret -ne 0) {
		Write-Host "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		Write-Host "<!> Run-DBContainer failed..."
		Write-Host "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		return $ret
	}

	$ret = Run-AppContainer
	if ($ret -ne 0) {
		Write-Host "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		Write-Host "<!> Run-AppContainer failed..."
		Write-Host "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		return $ret
	}

	Write-Host "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"
	Write-Host " finished!!"
	Write-Host "_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/"

    return 0
}

#--------------------------------------
# �t�@�C�i���C�Y
#--------------------------------------
function Finalize()
{
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

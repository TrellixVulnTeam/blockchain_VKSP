=============================
 �R���e�i/Docker���\�z�菇
=============================

1. �R���e�i/Docker�̃C���X�g�[��
   https://www.server-world.info/query?os=Windows_Server_2019&p=docker&f=1

2. �K�v�ȃt�@�C����p�� (�����̓R���e�i���ɔz�u�����)
   ./docker/tools/win
    �Evc_redist.x86.exe (Runtime)
    �Evc_redist.x64.exe (Runtime)
    �Egvim*.exe (Vim)
    �Erewrite.msi (IIS Rewrite)
    �ErequestRouter_amd64.msi (IIS Rewrite)
    �Emysql-connector-odbc-8.0.22-winx64.msi (MySQL�pODBC�h���C�o�[)
    �Emsodbcsql.msi (SQL Server�pODBC�h���C�o�[)
    �Edb_create_user.bat (SQL Server�p���[�U�[�쐬�o�b�`)
    �Esqlcmd (SQL Server�p�R�}���h)
    �Edatabase_enu (SQL Server Express �p��) ��2021/4���_�͉p�ꂵ���g���Ȃ�
    �Edatabase_jpn (SQL Server Express ���{��)
   ./archives
    �Esystem.zip (�z�u�������t�@�C���Q���ꌳ������ZIP�t�@�C��)

3. �r���h�C���[�W���쐬
   cd <Build-Images.ps1�����݂���p�X(Dockerfile�����݂���p�X)>
   "Build-Images.ps1 -ImageName <�C���[�W��>"�����s�B
   "docker images"�����s���A�쐬�����C���[�W�����݂��邱�Ƃ��m�F(REPOSITORY������L�C���[�W���ł���)�B

4. �R���e�i���N��
   "docker run --entrypoint powershell -it -p 8888:80 <REPOSITORY��>"�ŃA�N�Z�X�B
   8888�̓A�N�Z�X��(�z�X�g)�̃|�[�g�A80�̓A�N�Z�X��(�R���e�i)�̃|�[�g

5. Vim���C���X�g�[��
   "gvim82.exe /S"�ŃR���e�i���ŃC���X�g�[�������B
   �z�X�g����Microsoft.PowerShell_profile.ps1��p�ӂ��A�ȉ����L�����Ă����B
   �uset-alias vi 'C:\Program Files (x86)\Vim\vim82\vim.exe'�v
   ���t�@�C�����R���e�i���́uC:\Users\ContainerAdministrator\Documents\WindowsPowerShell�v�ɃR�s�[�B
   "docker cp <�v���t�@�C���̃p�X> <�R���e�iID>:/Users\ContainerAdministrator\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
   "docker ps"�ɂ��A���Y�C���[�W��NAME��c���B
   "docker stop <��L��NAME>"�ɂ��A���Y�R���e�i���~�B
   "docker start <��L��NAME>"�ɂ��A���Y�R���e�i���ċN���B(OS�ċN���Ɠ���)
   "docker attach <��L��NAME>"�ɂ��A���Y�R���e�i�ɓ���B
   ����Łuvi�v�R�}���h��Vim���g���邱�Ƃ��m�F�ł���B

6. IIS URL Rewrite���C���X�g�[�����邽�߂̃o�[�W��������
   Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\InetStp
   MajorVersion��10�ł���ꍇ�͈ȉ������{�B
   Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\InetStp -Name MajorVersion -Value 9
   "docker stop <�R���e�i��NAME>"�ɂ��A���Y�C���[�W���~�B
   "docker start <�R���e�i��NAME>"�ɂ��A���Y�C���[�W���ċN���B(OS�ċN���Ɠ���)

7. IIS URL Rewrite���C���X�g�[��
   �R���e�i���ňȉ������{�B
   msiexec.exe /qn /i <rewrite.msi�̃t���p�X>
   msiexec.exe /qn /i <requestRouter_amd64.msi�̃t���p�X>
    ��MSI�t�@�C���̓t���p�X���w�肵�Ȃ��Ǝ��s����B
   �ȉ������s���āA����ɃC���X�g�[������Ă��邱�Ƃ��m�F�B
   Get-WmiObject Win32_Product | Select-Object Name,Vendor,Version,Caption | ForEach-Object {if($_.Name -like "*rewrite*"){ Write-Host $_ }}
   "*IIS URL Rewrite Module*"���\�������΂悢�B

8. IIS�Z�b�g�A�b�v
   �R���e�i���ňȉ������{�B
   iis-setup.ps1 -Site <�T�C�g��> -StopSiteConflictPort 80

9. ODBC�h���C�o�[���C���X�g�[��
   �A�v���p�R���e�i���ňȉ������{�B
   [MySQL]
    msiexec.exe /qn /i <mysql-connector-odbc-8.0.22-winx64.msi�̃t���p�X>
     ��MSI�t�@�C���̓t���p�X���w�肵�Ȃ��Ǝ��s����B
    �ȉ������s���āA����ɃC���X�g�[������Ă��邱�Ƃ��m�F�B
    $HKLM = 2147483650
    $reg = [WMIClass]"ROOT\DEFAULT:StdRegProv"
    $Key = "SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
    $reg.EnumValues($HKLM, $Key) | % { $_.sNames | % {$_ + "`t" + $reg.getStringValue($HKLM, $Key, $_).sValue } }
    "MySQL ODBC * Driver      Installed"���\�������΂悢�B
   [SQL Server]
    msiexec.exe /quiet /passive /qn /i <msodbcsql.msi�̃t���p�X> IACCEPTMSODBCSQLLICENSETERMS=YES
    �ȉ������s���āA����ɃC���X�g�[������Ă��邱�Ƃ��m�F�B
    $HKLM = 2147483650
    $reg = [WMIClass]"ROOT\DEFAULT:StdRegProv"
    $Key = "SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
    $reg.EnumValues($HKLM, $Key) | % { $_.sNames | % {$_ + "`t" + $reg.getStringValue($HKLM, $Key, $_).sValue } }
    "ODBC Driver * for SQL Server   Installed"���\�������΂悢�B

10.DB�Z�b�g�A�b�v
   [MySQL]
    �ȉ�����MySQL(�o�[�W����8.0.22)���_�E�����[�h
    https://dev.mysql.com/downloads/installer/
    �z�X�g�ɃC���X�g�[��(�C���X�g�[���[�̐ݒ�͂��ׂăf�t�H���g�ł悢�B�p�X���[�h�͔C�ӁB�����ł�"Recho2000"�Ƃ���)
    �z�X�g�̊��ϐ�Path�ɁuC:\Program Files\MySQL\MySQL Server 8.0\bin�v��ǉ��B
    �V�F���ɂĈȉ������s�B
    mysql.exe -u root -p
    CREATE USER 'root'@'%' IDENTIFIED BY 'Rencho2000';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
     ���V�K���[�U�[root���쐬�B�p�X���[�h��Rencho2000�B�O������̃A�N�Z�X���\�Ƃ���"%"�����Ƃ���B
       "select user, host from mysql.user;"�Ŋm�F�\�B
    ����ŁA�R���e�i����z�X�g�ցAroot/Rencho2000�ŃA�N�Z�X�\�ƂȂ�B
    �R���e�i����ڑ�����z�X�g��IP�A�h���X�́A�R���e�i���Łuping <�z�X�g�̃R���s���[�^�[��>�v�����s���Ď擾����B
   [SQL Server]
    DB(SQL Server)�p�R���e�i������B
    docker pull kkbruce/mssql-server-windows-express:windowsservercore-1809
    docker run -d -p 1433:1433 -e sa_password=Rencho2000 -e ACCEPT_EULA=Y -v "C:/docker/sqlserver/data:C:/sqlserver/data" kkbruce/mssql-server-windows-express:windowsservercore-1809
     ���ڍׂ�TIPS�́uSQL Server�̃f�[�^�i�����v���Q�ƁB
    �R���e�i���ňȉ������{�B
    cd C:/docker/tools/win/database_en
    & .\SETUP.EXE /Q /ACTION=Install /IACCEPTSQLSERVERLICENSETERMS /FEATURES=SQLEngine,Conn /INSTANCENAME=PWSP /SECURITYMODE=SQL /SAPWD=Rencho2000 /NPENABLED=1 /TCPENABLED=1 /AGTSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS'
    .\db_create_user.bat <�R���e�i��IP>\PWSP
     ���R���e�i��IP��TIPS�Q�ƁB
       ����ŁA�z�X�g��SSMS����u<�R���e�i��IP>\PWSP�v�C���X�^���X�ցADashboard_Admin/P@ssW0rd�ŃA�N�Z�X�ł���B

11.�z�X�g�̃u���E�U����uhttp://localhost:8888�v�ŃA�N�Z�X�B
   ���X�̓�����m�F�ł���B

12.�R���e�i�C���[�W�̕ۑ�
   "docker stop <�R���e�i��NAME>"�ɂ��A���Y�R���e�i���~�B
   "docker commit <�ۑ������������R���e�i��NAME> <�C�ӂ̖��O>"�ɂ��A�C�ӂ̖��O�ŃC���[�W���R�s�[���ۑ��B
   "docker images"�ɂ��A��L�̖��O(REPOSITORY��)�ŃC���[�W���ǉ�����Ă��邱�Ƃ��m�F�B

13.Docker�C���[�W�̔��o
   "docker save <��L��REPOSITORY��> -o <�o�͐�t�@�C���p�X(�g���q��.tar)>"

14.Docker�C���[�W�̔��� (�\�z���������Ŏ��{)
   "docker load -i <�����������C���[�W(�g���q��.tar)>"


TIPS.
�Edocker rmi�ŃG���[�ɂȂ�Ƃ�
  "docker ps -a"�Œ�~���Ă���R���e�i�ꗗ��\�����ACONTAINER ID���m�F�B
  docker rm <CONTAINER ID>�ō폜���Ă���Adocker rmi����B
  docker rm <CONTAINER ID> <CONTAINER ID> <CONTAINER ID>�c�̂悤�ɕ����w��\�B

�Edocker-compose�̃C���X�g�[��
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-Windows-x86_64.exe" -UseBasicParsing -OutFile $Env:ProgramFiles\docker\docker-compose.exe
   ��"1.23.2"�̓o�[�W�������w���B�ȉ����ŐV�̈���o�[�W�������m�F���Ďw�肷��΂悢�B
     https://github.com/docker/compose/releases

�Edocker-compose�̃r���h�C���[�W�쐬
  .\docker-compose.yml��p�ӁB
  .\Dockerfile��RUN�𒲐��B
  cd <yml�t�@�C���Ɠ��t�H���_>
  docker-compose build

�EWindows Container�ł�MySQL�̃C���[�W�͎g���Ȃ����߁ASQL Server(microsoft/mssql-server-windows*)���g���B
  �������A������z�X�g��WS2019(v1809)�ł�2021/4���_�Ŏg���Ȃ��c(run���ɃG���[���o��)�B
  WS2019(v1809)��SQL Server�́A�ȉ��̃J�X�^���C���[�W�Ȃ�g�p�\(Microsoft�I�t�B�V�����łł͏�L�̒ʂ�G���[�ɂȂ�)�B
  kkbruce/mssql-server-windows-express:windowsservercore-1809
  �z�X�g����R���e�i�ւ�SSMS�ڑ��͈ȉ����Q�ƁB
  http://kharuka2016.hatenablog.com/entry/2017/02/16/170009

�E�z�X�g����R���e�i��IP�A�h���X�擾
  docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' �R���e�iID�܂��̓R���e�i��

�E�z�X�g����R���e�i�̃R�}���h���s
  docker exec �R���e�iID�܂��̓R���e�i�� powershell -c "�R���e�i���ł̃R�}���h"

�ESQL Server�̃f�[�^�i����
  �@�z�X�g��mdf,ldf�ۑ�����쐬(�����ł́A"C:\docker\sqlserver\data"�Ƃ���)
  �Adocker run -d -p 1433:1433 -e sa_password=Rencho2000 -e ACCEPT_EULA=Y -v "C:/docker/sqlserver/data:C:/sqlserver/data" kkbruce/mssql-server-windows-express:windowsservercore-1809
    �������ł́A�R���e�i����"C:/sqlserver/data"�Ƃ��Ă���B
    ��"docker exec -it �R���e�iID�܂��̓R���e�i�� powershell"�ŃR���e�i���ɃA�N�Z�X�ł���B
  �B�R���e�i����DB���쐬����B���̂Ƃ��Amdf,ldf�̕ۑ����"C:/sqlserver/data"���w�肷��B
  �C�R���e�i��~�B�f�[�^�̓z�X�g����"C:\docker\sqlserver\data"�ɕۑ�����Ă���B
  �D�ēx�R���e�i���N������Ƃ��͈ȉ������s�B
    docker run -d -p 1433:1433 -e sa_password=Rencho2000 -e ACCEPT_EULA=Y -e attach_dbs="[{'dbname':'test','dbFiles':['C:\\sqlserver\\data\\test.mdf','C:\\sqlserver\\data\\test_log.ldf']}]" -v "C:/docker/sqlserver/data:C:/sqlserver/data" kkbruce/mssql-server-windows-express:windowsservercore-1809
    ��dbFiles�́u\\�v���w�肵�Ȃ���(�G���[�͏o�Ȃ���)���s����B

�E�R���e�i�ł�PWSP�C���X�^���X�ւ�DB�A�^�b�`���@
  sqlcmd -E -S "localhost\PWSP" -Q "sp_attach_db 'DB��(e.g. test)','C:\\sqlserver\\data\\test.mdf','C:\\sqlserver\\data\\test_log.ldf'"

�E�R���e�i�ł�DB�f�^�b�`���@
  sqlcmd -E -S "localhost\PWSP" -Q "sp_detach_db 'DB��(e.g. test)'"

�Ekkbruce/mssql-server-windows-express:windowsservercore-1809��Dockerfile��FROM�Ɏw�肵��docker build�����ꍇ�A
  ��Dockerfile��WORKDIR���L�ڂ���ƁAdocker run�ŋN����������ɑ��I�����Ă��܂��B����͓�c�B

�E���b�p�[�܂߂������菇
��db
C:\docker\Build-Image.ps1 -Dockerfile C:\docker\rtc\db\Dockerfile -ImageName rtc_db_image_test
docker run -d -p 1433:1433 -e sa_password=Rencho2000 -e ACCEPT_EULA=Y -v "C:/docker/sqlserver/data:C:/sqlserver/data" rtc_db_image_test
docker ps
docker cp C:\docker\rtc\wrapper\pc.bak 70d3824d5a20:/sqlserver/pc.bak
docker exec 70d3824d5a20 powershell -c "Restore-DB -DBName pc -DBPath C:\sqlserver\pc.bak -DBDataDir C:\sqlserver\data"
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 70d3824d5a20

��app
C:\docker\Build-Image.ps1 -Dockerfile C:\docker\rtc\app\Dockerfile -ImageName rtc_app_image_test
docker run -d -p 8888:8080 rtc_app_image_test
docker ps
docker exec f7886baa9f0a powershell -c "Setup-DBConfig -DBType sqlserver -DBServer localhost\PWSP -DBName pc"

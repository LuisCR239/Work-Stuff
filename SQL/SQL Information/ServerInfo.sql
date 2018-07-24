	Declare @advancedValue int;
	Declare @cmdValue int;
	DECLARE @configuration TABLE (
	   Name varchar(300),
	   minimum int,
	   maximum int,
	   config_value int,
	   run_value int
	)
	INSERT INTO @configuration Exec sp_configure 
	set @advancedValue  = (select run_value from @configuration where Name = 'show advanced options');

	EXEC sp_configure 'show advanced options', 1;  

	RECONFIGURE;  
  
	delete from @configuration
	INSERT INTO @configuration Exec sp_configure 
	set @cmdValue  = (select run_value from @configuration where Name = 'xp_cmdshell');

	EXEC sp_configure 'xp_cmdshell', 1;  

	RECONFIGURE;  

Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';
Print N''
Print N''
Print N'Informacion Discos duros'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';

	exec xp_cmdshell 'powershell.exe  "Get-WmiObject Win32_LogicalDisk  | select-object DeviceID,Size,Freespace | % {$_.FreeSpace=([math]::Round($_.FreeSpace/1GB,2));$_.Size=([math]::Round($_.Size/1GB,2));$_}"';

Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';
Print N''
Print N''
Print N'Informacion instancia'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';

	SELECT    
		cast(SERVERPROPERTY('MachineName') as nvarchar(100)) as [Nombre de equipo] ,
		cast(SERVERPROPERTY('InstanceName') as nvarchar(20))  as [Nombre de instancia],
		case SERVERPROPERTY('IsLocalDB') 
			when 0 then 'No' 
			when 1 then 'Si'
		end as [SQL Express LocalDB],
		cast(SERVERPROPERTY('ResourceVersion') as nvarchar(20)) as [Version],
		cast(SERVERPROPERTY('Edition') as nvarchar(50)) as [Edicion],
		cast(SERVERPROPERTY('ProductLevel') as nvarchar(20)) as [Nivel],
			case SERVERPROPERTY('IsHadrEnabled') 
			when 0 then 'No' 
			when 1 then 'Si' 
		end as [Always On Avaliability Groups esta habilitado en la instancia],
		case SERVERPROPERTY('HadrManagerStatus') 
			when 0 then 'No iniciado' 
			when 1 then 'Iniciado' 
			when 2 then 'No iniciado y/o con error' 
			else 'No aplica'
		end as [Administrador de Always On Avaliability Groups],
		case SERVERPROPERTY('IsClustered') 
			when 0 then 'No' 
			when 1 then 'Si'
		end as [Es cluster],
		case SERVERPROPERTY('IsIntegratedSecurityOnly') 
			when 0 then 'Mixta' 
			when 1 then 'Windows' 
		end as [Autenticacion],
		cast(SERVERPROPERTY('Collation') as nvarchar(100)) as [Collation]
	;

Print N'Para revisar las actualizaciones existentes, visitar https://sqlserverbuilds.blogspot.com/ y buscar el numero de version'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';
Print N''
Print N''
Print N'Informacion de servicios de SQL server'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';

	SELECT  cast(servicename as nvarchar(100)) as [Nombre de servicio],
			cast(status_desc as nvarchar(100)) as [Estatus],
			cast(service_account as nvarchar(100)) as [Usuario de servicio],
			is_clustered as [En cluster],
			cast(cluster_nodename as nvarchar(100)) as [Nombre del cluster]
	FROM    sys.dm_server_services


--En caso de 2008 que no se tenga posibilidad de usar el sistema anterior
--DECLARE       @DBEngineLogin       VARCHAR(100)
--DECLARE       @AgentLogin          VARCHAR(100)
-- 
--EXECUTE       master.dbo.xp_instance_regread
--              @rootkey      = N'HKEY_LOCAL_MACHINE',
--              @key          = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
--              @value_name   = N'ObjectName',
--              @value        = @DBEngineLogin OUTPUT
-- 
--EXECUTE       master.dbo.xp_instance_regread
--              @rootkey      = N'HKEY_LOCAL_MACHINE',
--              @key          = N'SYSTEM\CurrentControlSet\Services\SQLServerAgent',
--              @value_name   = N'ObjectName',
--              @value        = @AgentLogin OUTPUT
-- 
--SELECT        [DBEngineLogin] = @DBEngineLogin, [AgentLogin] = @AgentLogin
--
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';
	EXEC sp_configure 'xp_cmdshell',  @cmdValue;  

	RECONFIGURE; 
	EXEC sp_configure 'show advanced options', @advancedValue ;  

	RECONFIGURE;  
Print N''
Print N''
Print N'Informe de bases de datos existentes'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';

	execute master.sys.sp_MSforeachdb 'Use[?];
										Print N''***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************'';
										Select 
											db_name() as [Nombre], 
											db.recovery_model_desc as [Modelo de recuperacion], 
											db.state_desc as [Estado] 
										from master.sys.databases db where db.name = db_name(); 
										Select 
											fileid as [Id de archivo],
											case when groupid = 0 then ''log'' else ''datos'' end as [Tipo de archivo],
											name as [Nombre de archivo],
											filename as [Ruta], 
											[Tamaño del archivo en MB]=convert(int,round((sysfiles.size*1.000)/128.000,0)),
											[Espacio usado en MB] =convert(int,round(fileproperty(sysfiles.name,''SpaceUsed'')/128.000,0)) ,
											[Espacio sobrante en MB] =convert(int,round((sysfiles.size-fileproperty(sysfiles.name,''SpaceUsed''))/128.000,0)) 
										from dbo.sysfiles;
										Print N''***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************'';
										'

Print N''
Print N''
Print N'Respaldos por base de datos'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';

	use msdb

	SELECT backupset.database_name as [Nombre],    
		MAX(CASE WHEN backupset.type = 'D' THEN backupset.backup_finish_date ELSE NULL END) AS [Ultimo Respaldo Full],    
		MAX(CASE WHEN backupset.type = 'I' THEN backupset.backup_finish_date ELSE NULL END) AS [Ultimo Respaldo Diferencial],   
		MAX(CASE WHEN backupset.type = 'L' THEN backupset.backup_finish_date ELSE NULL END) AS [Ultimo Respaldo Log]
	FROM backupset
	GROUP BY backupset.database_name
	ORDER BY backupset.database_name DESC

Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';
Print N''
Print N''
Print N'Planes de mantenimiento'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';

	select 
		cast(p.name as nvarchar(50)) as 'Plan de mantenimiento'
		,cast(p.[description] as nvarchar(110)) as 'Descripcion'
		,cast(p.[owner] as nvarchar(50)) as 'Dueño del plan'
		,cast(sp.subplan_name as nvarchar(50)) as 'Nombre de Subplan'
		,cast(sp.subplan_description as nvarchar(110)) as ' Descripcion de Subplan'
		,cast(j.name as nvarchar(50)) as 'Nombre del Job'
		,cast(j.[description] as nvarchar(80)) as 'Descripcion del Job '  
	from msdb..sysmaintplan_plans p
		inner join msdb..sysmaintplan_subplans sp
		on p.id = sp.plan_id
		inner join msdb..sysjobs j
		on sp.job_id = j.job_id
	where j.[enabled] = 1

Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';
Print N''
Print N''
Print N'Usuarios con permisos elevados en Sql Server'
Print N'***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************';

	EXEC master.sys.sp_helpsrvrolemember
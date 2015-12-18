EXEC tSQLt.NewTestClass 'EnableExternalAccessTests';
GO
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess sets PERMISSION_SET to EXTERNAL_ACCESS if called without parameters]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;

  EXEC tSQLt.EnableExternalAccess;

  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = A.permission_set_desc FROM sys.assemblies AS A WHERE A.name = 'tSQLtCLR';

  EXEC tSQLt.AssertEqualsString @Expected = 'EXTERNAL_ACCESS', @Actual = @Actual;
END;
GO
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful error with details, if setting fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'The attempt to enable tSQLt features requiring EXTERNAL_ACCESS failed: ALTER ASSEMBLY%tSQLtCLR%failed%EXTERNAL_ACCESS%';
  EXEC tSQLt.EnableExternalAccess;
END;
GO
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess sets PERMISSION_SET to SAFE if @enable = 0]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;

  EXEC tSQLt.EnableExternalAccess @enable = 0;

  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = A.permission_set_desc FROM sys.assemblies AS A WHERE A.name = 'tSQLtCLR';

  EXEC tSQLt.AssertEqualsString @Expected = 'SAFE_ACCESS', @Actual = @Actual;
END;
GO
CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful warning only, if @try = 1 and setting fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;
  EXEC master.tSQLt_testutil.tSQLtTestUtil_ExternalAccessRevoke;

  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.EnableExternalAccess @try = 1;';
  
  SELECT OutputText 
    INTO #Actual
    FROM tSQLt.CaptureOutputLog;
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  INSERT INTO #Expected
  VALUES('Warning: The attempt to enable tSQLt features requiring EXTERNAL_ACCESS failed.'+CHAR(13)+CHAR(10));
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE EnableExternalAccessTests.[test tSQLt.EnableExternalAccess reports meaningful error if disabling fails]
AS
BEGIN
  ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;

  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = SM.definition FROM sys.sql_modules AS SM WHERE SM.object_id = OBJECT_ID('tSQLt.EnableExternalAccess');

  DECLARE @TranName VARCHAR(32);SET @TranName = REPLACE((CAST(NEWID() AS VARCHAR(36))),'-','');
  SAVE TRAN @TranName;
    EXEC tSQLt.Uninstall;
    EXEC('CREATE SCHEMA tSQLt;');
    EXEC(@cmd);

    DECLARE @Actual NVARCHAR(MAX);SET @Actual = 'No error raised!';  
    BEGIN TRY
      EXEC tSQLt.EnableExternalAccess @enable = 0;
    END TRY
    BEGIN CATCH
      SET @Actual = ERROR_MESSAGE();
    END CATCH;
  ROLLBACK TRAN @TranName;

  EXEC tSQLt.AssertLike @ExpectedPattern = 'The attempt to disable tSQLt features requiring EXTERNAL_ACCESS failed: %tSQLtCLR%', @Actual = @Actual;
END;
GO


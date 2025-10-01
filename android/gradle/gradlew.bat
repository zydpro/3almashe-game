@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIR=%~dp0
@rem Find java.exe
set JAVA_EXE=
if defined JAVA_HOME set JAVA_EXE=%JAVA_HOME%\bin\java.exe
if not defined JAVA_HOME set JAVA_EXE=java

@rem Check if JAVA_EXE exists
if not exist "%JAVA_EXE%" (
  echo.
  echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
  echo.
  echo Please set the JAVA_HOME variable in your environment to match the
  echo location of your Java installation.
  exit /b 1
)

set CLASSPATH=%DIR%gradle\wrapper\gradle-wrapper.jar

@rem Execute Gradle
"%JAVA_EXE%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

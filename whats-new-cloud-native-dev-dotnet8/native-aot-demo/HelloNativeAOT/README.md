## Native AOT Demo

Navigate to the project directory and run the following command:

```bash
dotnet publish
```

Once publish succeeds, run the following command to see what was published:

```bash
dir .\bin\Release\net8.0\publish\
```

You should see the following output:

```bash
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         4/12/2023   7:38 PM            127 appsettings.Development.json
-a----         4/12/2023   7:38 PM            151 appsettings.json
-a----         4/12/2023   8:53 PM            434 HelloNativeAOT.deps.json
-a----         4/12/2023   8:53 PM           5120 HelloNativeAOT.dll
-a----         4/12/2023   8:53 PM         140800 HelloNativeAOT.exe
-a----         4/12/2023   8:53 PM          21476 HelloNativeAOT.pdb
-a----         4/12/2023   8:53 PM            595 HelloNativeAOT.runtimeconfig.json
-a----         4/12/2023   8:53 PM            558 web.config
```

- dll has been created (5KB)
- This is a Framework dependent deployment. It requires a runtime to land on
- We want to deploy this as self-contained. To do that we can do the following:

Add the following to your ```*.csproj``` file:

```xml
<PublishSelfContained>true</PublishSelfContained>
```


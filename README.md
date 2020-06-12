# Format-Hook

![CI Tests](https://github.com/MrLuje/dotnet-format-hook/workflows/CI%20Tests/badge.svg)
![Nuget](https://img.shields.io/nuget/v/format-hook)

[dotnet-format](https://github.com/dotnet/format) as a git pre-commit hook

## Requirements

- git
- dotnet cli (>= 3.0)

## How to install

- VisualStudio
  - PackageManager : search for *format-hook* and install to your main csproj
  - PackageManager console : Install-Package format-hook
- .NET CLI : dotnet add <!path to your csproj> package format-hook

Build you project, and you are done 👏

format-hook is a development dependency so it won't affect build artifacts 🚩

![example precommit hook](.github/example%20hook.png)

## How

Under the hood, this will :

- checks for an available dotnet-format binary in PATH and install a [local one](https://docs.microsoft.com/fr-fr/dotnet/core/tools/local-tools-how-to-use) if needed
- configures git to use the newly created [*hooks*](#HooksPath) folder at the root of your repository
- adds the *pre-commit* hook that handles dotnet-format

## Configuration

You can configure the following properties by adding them on the csproj you installed format-hook :

| Property  | Description                                                                           | Default Value |
| --------- | ------------------------------------------------------------------------------------- | ------------- |
| CI        | Prevent hook from being installed if true. Major CI systems set it to true by default | false         |
| HooksPath | Folder to which hooks are configured                                                  | hooks         |

### Example

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <HooksPath>GitHook</HooksPath>
  </PropertyGroup>
</Project>
```

## Supported frameworks

- .Net Standard / .NET Core
- Full Framework .NET

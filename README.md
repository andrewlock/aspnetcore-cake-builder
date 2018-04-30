# A generalised ASP.NET Core builder Docker image

This repo contains a [Dockerfile](/Dockerfile) that can be used to build ASP.NET Core images using Cake, where they conform to a standard layout:

* Should have a single _.sln_ file in the root folder
* Should have all library and app projects in a _src_ subdirectory
* Should have all test projects in a _test_ subdirectory

The image uses Docker's `ONBUILD` command to execute the following in your project's directory:

1. Copy the _.sln_ file and _NuGet.config_
1. Copy the _.csproj_ files into the image and run `dotnet restore` using Cake (to [take advantage of Docker's layer caching mechanism](https://andrewlock.net/optimising-asp-net-core-apps-in-docker-avoiding-manually-copying-csproj-files/))
1. Copy the source code to the builder image and run `dotnet build` using Cake
1. Run `dotnet test` on every project in the _test_ folder using Cake

A [Cake build file is included](build.cake) for restoring, building and testing your app. You can overwrite the _build.cake_ file by including a replacement in your project folder if it doesn't meet your requirements. Either way, you will need to include a Cake build file for publishing your app. This includes invoking the publish command.

For example, the following small would be a publish target:

```csharp
var target = Argument("Target", "Default");  
var configuration = Argument("Configuration", "Release");

var distDirectory = Directory("./dist");

// Publish the app to the /dist folder
Task("PublishWeb")  
    .Does(() =>
    {
        DotNetCorePublish(
            "./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj",
            new DotNetCorePublishSettings()
            {
                Configuration = configuration,
                OutputDirectory = distDirectory,,
                ArgumentCustomization = args => args.Append("--no-restore"),
            });
    });

Task("Default")  
    .IsDependentOn("BuildAndTest")
    .IsDependentOn("PublishWeb");

// Executes the task specified in the target argument.
RunTarget(target);  
```

You can then use the Docker image and publish your app using a Docker image similar to the following:

```docker
# Build image
FROM andrewlock/aspnetcore-cakebuild:2.0.7-2.1.105 as builder

# Publish
ONBUILD RUN sh ./build.sh build.cake --target=Restore

#App image
FROM microsoft/aspnetcore:2.0.7
WORKDIR /app  
ENV ASPNETCORE_ENVIRONMENT Local  
ENTRYPOINT ["dotnet", "AspNetCoreInDocker.Web.dll"]
COPY --from=builder /sln/dist .  
```
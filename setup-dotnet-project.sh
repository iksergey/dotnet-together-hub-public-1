# chmod +x ./setup-dotnet-project.sh

#!/bin/bash

check_dotnet_version() {
    dotnet --list-sdks | grep -q "9\."
    return $?
}

if ! check_dotnet_version; then
    read -p ".NET 9 is not installed. Something might not work. Continue? (Y/N): " response
    
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    exit 1
fi

echo "Continuing execution..."

echo "dotnet-ef is not installed. Installing..."
dotnet tool install --global dotnet-ef --version 9.0.1

dotnet new gitignore

echo -e "togetherhub.db-shm\ntogetherhub.db-wal\ntogetherhub.db\n.DS_Store\n$(cat .gitignore)" > .gitignore

dotnet new sln -n "TogetherHub"

dotnet new webapi -n "Api" -controllers
dotnet new classlib -n "Application"
dotnet new classlib -n "Domain"
dotnet new classlib -n "Infrastructure"

dotnet new classlib -n "Shared"

dotnet sln add "./Api/Api.csproj"
dotnet sln add "./Application/Application.csproj" 
dotnet sln add "./Domain/Domain.csproj" 
dotnet sln add "./Infrastructure/Infrastructure.csproj" 
dotnet sln add "./Shared/Shared.csproj" 

dotnet add "./Api/Api.csproj" reference "./Application/Application.csproj"
dotnet add "./Api/Api.csproj" reference "./Infrastructure/Infrastructure.csproj"
dotnet add "./Application/Application.csproj" reference "./Domain/Domain.csproj" 
dotnet add "./Application/Application.csproj" reference "./Shared/Shared.csproj"
dotnet add "./Infrastructure/Infrastructure.csproj" reference "./Domain/Domain.csproj"
dotnet add "./Infrastructure/Infrastructure.csproj" reference "./Application/Application.csproj"

dotnet add "./Api/Api.csproj" package "Microsoft.EntityFrameworkCore.Design" -v "9.0.0"
dotnet add  "./Application/Application.csproj" package "AutoMapper.Extensions.Microsoft.DependencyInjection" -v "12.0.1"
dotnet add  "./Application/Application.csproj" package "Microsoft.IdentityModel.JsonWebTokens" -v "8.3.0"
dotnet add  "./Application/Application.csproj" package "Microsoft.AspNetCore.Authentication.JwtBearer" -v "9.0.0"
dotnet add "./Infrastructure/Infrastructure.csproj" package "Microsoft.EntityFrameworkCore.Sqlite" -v "9.0.0"
dotnet add "./Shared/Shared.csproj" package "MediatR" -v "12.4.1"

dotnet add  "./Domain/Domain.csproj" package "Microsoft.AspNetCore.Identity.EntityFrameworkCore" -v "9.0.0"

rm "./Api/Api.http"
rm "./Api/WeatherForecast.cs"
rm "./Api/Controllers/WeatherForecastController.cs"
rm "./Application/Class1.cs"
rm "./Infrastructure/Class1.cs"
rm "./Shared/Class1.cs"
rm "./Domain/Class1.cs"

dotnet new apicontroller -n TopicsController -o "./Api/Controllers" --namespace API.Controllers

: '
// http://localhost:5001/api/topics
[HttpGet]
public async Task<IActionResult> Hello()
{
    return await Task.FromResult(Ok(new { text = "hello" }));
}
'
# dotnet watch --no-hot-reload --project Api/Api.csproj 

dotnet clean
dotnet restore
dotnet build

echo "Project successfully created!"

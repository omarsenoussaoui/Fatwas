FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY TafrighBot.csproj .
RUN dotnet restore

COPY Program.cs .
COPY appsettings.json .
COPY Models/ Models/
COPY Data/ Data/
COPY Services/ Services/

RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .

RUN mkdir -p /app/data

EXPOSE 5060

ENTRYPOINT ["dotnet", "TafrighBot.dll"]

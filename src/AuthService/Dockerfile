FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/AuthService/AuthService.csproj", "AuthService/"]
COPY ["src/Shared/Shared.csproj", "Shared/"]
RUN dotnet restore "AuthService/AuthService.csproj"
COPY src/AuthService/ AuthService/
COPY src/Shared/ Shared/
WORKDIR "/src/AuthService"
RUN dotnet build "AuthService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AuthService.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AuthService.dll"]

# build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY src/SampleApp/*.csproj ./src/SampleApp/
RUN dotnet restore src/SampleApp/SampleApp.csproj
COPY src/ ./ 
WORKDIR /src/src/SampleApp
RUN dotnet publish -c Release -o /app/publish

# runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80
ENTRYPOINT ["dotnet", "SampleApp.dll"]

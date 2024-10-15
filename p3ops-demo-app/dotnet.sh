dotnet restore src/Server/Server.csproj
dotnet build src/Server/Server.csproj
dotnet publish src/Server/Server.csproj -c Release -o publish
DOTNET_ENVIRONMENT: environment name, e.g. Production
DOTNET_ConnectionStrings__SqlDatabase: connection string to the SQL Server database
dotnet publish/Server.dll